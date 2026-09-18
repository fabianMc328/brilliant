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

  Tablero({required this.filas, required this.columnas});

  /// Inicializa el tablero vinculando cada coordenada con su región.
  void cargarRegiones(List<Region> regiones) {
    celdas.clear();
    for (var region in regiones) {
      for (var coord in region.coordenadas) {
        celdas[coord] = Celda(coordenada: coord, region: region);
      }
    }
  }

  /// Obtiene todos los valores actuales dentro de una región específica.
  List<int> _valoresEnRegion(Region region) {
    return celdas.values
        .where((celda) => celda.region == region && !celda.estaVacia)
        .map((celda) => celda.valor!)
        .toList();
  }

  /// Intenta colocar un número en la coordenada indicada respetando las reglas de la Región.
  bool colocarNumero(Coordenada c, int numero) {
    final celda = celdas[c];
    if (celda == null) return false; // Coordenada fuera del mapa
    if (!celda.estaVacia) return false; // Ya tiene un número

    final valoresActuales = _valoresEnRegion(celda.region);

    // Valida usando la lógica dinámica de tu clase Tipo (ej: TipoAzul, TipoAmarillo)
    if (celda.region.tipo.esPosibleAgregar(valoresActuales, numero)) {
      celda.valor = numero;
      return true;
    }

    return false; // Rompe la regla de la región
  }
}
