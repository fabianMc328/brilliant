import 'region.dart';
import 'tablero.dart';

abstract class JuegoEstado {}

/// Estado inicial antes de cargar el tablero
class JuegoSinIniciar extends JuegoEstado {}

/// Fase 1: Inicialización
/// El jugador debe colocar los números del 1 al 6 en las casillas iniciales.
class JuegoEsperandoValoresIniciales extends JuegoEstado {
  /// Las 6 coordenadas que son iniciales en el tablero.
  final List<Coordenada> casillasInciales;

  /// Los valores que el jugador ha colocado hasta ahora (Coordenada -> valor).
  final Map<Coordenada, int> valoresColocados;

  JuegoEsperandoValoresIniciales({
    required this.casillasInciales,
    this.valoresColocados = const {},
  });

  bool get listosParaAvanzar => valoresColocados.length == casillasInciales.length;

  JuegoEsperandoValoresIniciales copiarCon({
    Map<Coordenada, int>? valoresColocados,
  }) {
    return JuegoEsperandoValoresIniciales(
      casillasInciales: casillasInciales,
      valoresColocados: valoresColocados ?? this.valoresColocados,
    );
  }
}

/// Fase 2: El juego ha comenzado (Roll & Write con dados y anclas)
class JuegoEnProgreso extends JuegoEstado {
  /// Instancia del tablero con todas las celdas y regiones.
  final Tablero tablero;

  /// Valor del primer dado tirado (1-6)
  final int dado1;

  /// Valor del segundo dado tirado (1-6)
  final int dado2;

  /// Coordenada del tablero seleccionada como ancla
  final Coordenada? anclaSeleccionada;

  /// El número a colocar (determinado por el otro dado)
  final int? numeroAColocar;

  /// Conjunto de coordenadas de casillas adyacentes válidas iluminadas
  final Set<Coordenada> casillasValidas;

  /// Puntuación total acumulada
  final int puntuacionTotal;

  /// IDs de las regiones completadas (en orden cronológico)
  final List<String> regionesCompletadasIds;

  /// Desglose de puntos por cada región completada
  final Map<String, int> desglosePuntos;

  /// Contador de turnos jugados
  final int turno;

  /// Mensaje descriptivo o de feedback temporal
  final String? mensajeFeedback;

  /// Si existe al menos una colocación válida en el tablero con la tirada actual
  final bool hayJugadasDisponibles;

  JuegoEnProgreso({
    required this.tablero,
    required this.dado1,
    required this.dado2,
    this.anclaSeleccionada,
    this.numeroAColocar,
    this.casillasValidas = const {},
    this.puntuacionTotal = 0,
    this.regionesCompletadasIds = const [],
    this.desglosePuntos = const {},
    this.turno = 1,
    this.mensajeFeedback,
    this.hayJugadasDisponibles = true,
  });

  /// Getter compatible para obtener todos los valores colocados en el tablero
  Map<Coordenada, int> get valoresColocados {
    final mapa = <Coordenada, int>{};
    for (final entry in tablero.celdas.entries) {
      if (!entry.value.estaVacia) {
        mapa[entry.key] = entry.value.valor!;
      }
    }
    return mapa;
  }

  /// Retorna las coordenadas del tablero que son elegibles para ser anclas
  /// (aquellas que ya tienen un número que coincide con dado1 o dado2)
  Set<Coordenada> get anclasElegibles {
    final elegibles = <Coordenada>{};
    for (final entry in tablero.celdas.entries) {
      final v = entry.value.valor;
      if (v != null && (v == dado1 || v == dado2)) {
        elegibles.add(entry.key);
      }
    }
    return elegibles;
  }

  JuegoEnProgreso copiarCon({
    Tablero? tablero,
    int? dado1,
    int? dado2,
    Coordenada? anclaSeleccionada,
    bool limpiarAncla = false,
    int? numeroAColocar,
    bool limpiarNumeroAColocar = false,
    Set<Coordenada>? casillasValidas,
    int? puntuacionTotal,
    List<String>? regionesCompletadasIds,
    Map<String, int>? desglosePuntos,
    int? turno,
    String? mensajeFeedback,
    bool limpiarFeedback = false,
    bool? hayJugadasDisponibles,
  }) {
    return JuegoEnProgreso(
      tablero: tablero ?? this.tablero,
      dado1: dado1 ?? this.dado1,
      dado2: dado2 ?? this.dado2,
      anclaSeleccionada: limpiarAncla ? null : (anclaSeleccionada ?? this.anclaSeleccionada),
      numeroAColocar: limpiarNumeroAColocar ? null : (numeroAColocar ?? this.numeroAColocar),
      casillasValidas: casillasValidas ?? this.casillasValidas,
      puntuacionTotal: puntuacionTotal ?? this.puntuacionTotal,
      regionesCompletadasIds: regionesCompletadasIds ?? this.regionesCompletadasIds,
      desglosePuntos: desglosePuntos ?? this.desglosePuntos,
      turno: turno ?? this.turno,
      mensajeFeedback: limpiarFeedback ? null : (mensajeFeedback ?? this.mensajeFeedback),
      hayJugadasDisponibles: hayJugadasDisponibles ?? this.hayJugadasDisponibles,
    );
  }
}

/// Estado para mostrar errores
class JuegoError extends JuegoEstado {
  final String mensaje;
  final JuegoEstado estadoAnterior;

  JuegoError(this.mensaje, this.estadoAnterior);
}
