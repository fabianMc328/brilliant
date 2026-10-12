import 'region.dart';

/// La clase que une el tablero con las zonas (Regiones).
/// Representa una intersección física en la que se unen
/// las coordenadas, la región a la que pertenece y el valor del usuario.
class Celda {
  final Coordenada coordenada;
  final Region region;
  int? valor;

  Celda({
    required this.coordenada,
    required this.region,
    this.valor,
  });

  bool get estaVacia => valor == null;
}

/// Contenedor de todos los datos y reglas del mapa.
class Tablero {
  final int filas;
  final int columnas;

  /// El diccionario principal que almacena todo el estado del juego.
  ///  permite buscar  qué hay en cualquier Coordenada.
  final Map<Coordenada, Celda> celdas = {};
  final List<Region> _regiones = [];

  Tablero({required this.filas, required this.columnas});

  List<Region> get regiones => List.unmodifiable(_regiones);

  /// Inicializa el tablero vinculando cada coordenada con su región.
  void cargarRegiones(List<Region> regiones) {
    celdas.clear();
    _regiones.clear();
    _regiones.addAll(regiones);
    for (var region in regiones) {
      for (var coord in region.coordenadas) {
        celdas[coord] = Celda(coordenada: coord, region: region);
      }
    }
  }

  /// Obtiene todos los valores actuales dentro de una región específica.
  List<int> valoresEnRegion(Region region) {
    return celdas.values
        .where((celda) => celda.region == region && !celda.estaVacia)
        .map((celda) => celda.valor!)
        .toList();
  }

  /// Retorna si todas las casillas de una región han sido ocupadas.
  bool esRegionCompleta(Region region) {
    return region.coordenadas.every((c) => celdas[c]?.estaVacia == false);
  }

  /// Retorna los vecinos ortogonales válidos dentro de los límites del tablero.
  List<Coordenada> obtenerVecinosOrtogonales(Coordenada c) {
    final candidatos = [
      Coordenada(c.x - 1, c.y),
      Coordenada(c.x + 1, c.y),
      Coordenada(c.x, c.y - 1),
      Coordenada(c.x, c.y + 1),
    ];
    return candidatos.where((coord) =>
      coord.x >= 0 && coord.x < filas && coord.y >= 0 && coord.y < columnas
    ).toList();
  }

  /// Retorna las coordenadas de casillas adyacentes a [ancla] donde es válido colocar [numeroAColocar].
  Set<Coordenada> obtenerPosiblesLugaresParaAncla(Coordenada ancla, int numeroAColocar) {
    final vecinos = obtenerVecinosOrtogonales(ancla);
    final validos = <Coordenada>{};
    for (var vecino in vecinos) {
      final celda = celdas[vecino];
      if (celda != null && celda.estaVacia) {
        final valoresActuales = valoresEnRegion(celda.region);
        if (celda.region.tipo.esPosibleAgregar(valoresActuales, numeroAColocar)) {
          validos.add(vecino);
        }
      }
    }
    return validos;
  }

  /// Calcula la puntuación total acumulada para las regiones completadas dadas.
  int calcularPuntuacionTotal(List<String> ordenCompletadas) {
    final desglose = calcularDesglosePuntos(ordenCompletadas);
    return desglose.values.fold(0, (total, puntos) => total + puntos);
  }

  /// Calcula el desglose de puntos por cada región completada según su tipo y orden de completado.
  Map<String, int> calcularDesglosePuntos(List<String> ordenCompletadas) {
    final conteoPorTipo = <Type, int>{};
    final desglose = <String, int>{};

    for (var regionId in ordenCompletadas) {
      final region = _regiones.firstWhere((r) => r.id == regionId, orElse: () => throw Exception('Region no encontrada'));
      final tipoRuntime = region.tipo.runtimeType;
      final posicion = (conteoPorTipo[tipoRuntime] ?? 0) + 1;
      conteoPorTipo[tipoRuntime] = posicion;

      final puntos = region.tipo.puntuaciones[posicion] ?? 0;
      desglose[regionId] = puntos;
    }

    return desglose;
  }

  /// Intenta colocar un número en la coordenada indicada respetando las reglas de la Región.
  bool colocarNumero(Coordenada c, int numero) {
    final celda = celdas[c];
    if (celda == null) return false; // Coordenada fuera del mapa
    if (!celda.estaVacia) return false; // Ya tiene un número

    final valoresActuales = valoresEnRegion(celda.region);

    // Valida usando la lógica dinámica de tu clase Tipo (ej: TipoAzul, TipoAmarillo)
    if (celda.region.tipo.esPosibleAgregar(valoresActuales, numero)) {
      celda.valor = numero;
      return true;
    }

    return false; // Rompe la regla de la región
  }
}
