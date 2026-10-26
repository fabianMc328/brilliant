import 'niveles/catalogo_niveles.dart';
import 'niveles/nivel_definicion.dart';
import 'region.dart';
import 'tablero.dart';

abstract class JuegoEstado {}

// Antes de empezar nada.
class JuegoSinIniciar extends JuegoEstado {}

// Fase 1: llenando las estrellas iniciales.
class JuegoEsperandoValoresIniciales extends JuegoEstado {
  final List<Coordenada> casillasInciales;
  final Map<Coordenada, int> valoresColocados;
  final NivelDefinicion nivel;

  JuegoEsperandoValoresIniciales({
    required this.casillasInciales,
    this.valoresColocados = const {},
    NivelDefinicion? nivel,
  }) : nivel = nivel ?? CatalogoNiveles.nivel1;

  bool get listosParaAvanzar =>
      valoresColocados.length == casillasInciales.length;

  JuegoEsperandoValoresIniciales copiarCon({
    Map<Coordenada, int>? valoresColocados,
    NivelDefinicion? nivel,
  }) {
    return JuegoEsperandoValoresIniciales(
      casillasInciales: casillasInciales,
      valoresColocados: valoresColocados ?? this.valoresColocados,
      nivel: nivel ?? this.nivel,
    );
  }
}

// Fase 2: jugando con dados y anclas.
class JuegoEnProgreso extends JuegoEstado {
  final Tablero tablero;
  final NivelDefinicion nivel;
  final int dado1;
  final int dado2;
  final Coordenada? anclaSeleccionada;
  final int? numeroAColocar;
  final Set<Coordenada> casillasValidas;
  final int puntuacionTotal;
  final List<String> regionesCompletadasIds;
  final Map<String, int> desglosePuntos;
  final int turno;
  final String? mensajeFeedback;
  final bool hayJugadasDisponibles;

  JuegoEnProgreso({
    required this.tablero,
    NivelDefinicion? nivel,
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
  }) : nivel = nivel ?? CatalogoNiveles.nivel1;

  // Regresa los números que ya están puestos en el tablero.
  Map<Coordenada, int> get valoresColocados {
    final mapa = <Coordenada, int>{};
    for (final entry in tablero.celdas.entries) {
      if (!entry.value.estaVacia) {
        mapa[entry.key] = entry.value.valor!;
      }
    }
    return mapa;
  }

  // Casillas que tienen un número igual a alguno de los dados.
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
    NivelDefinicion? nivel,
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
      nivel: nivel ?? this.nivel,
      dado1: dado1 ?? this.dado1,
      dado2: dado2 ?? this.dado2,
      anclaSeleccionada:
          limpiarAncla ? null : (anclaSeleccionada ?? this.anclaSeleccionada),
      numeroAColocar: limpiarNumeroAColocar
          ? null
          : (numeroAColocar ?? this.numeroAColocar),
      casillasValidas: casillasValidas ?? this.casillasValidas,
      puntuacionTotal: puntuacionTotal ?? this.puntuacionTotal,
      regionesCompletadasIds:
          regionesCompletadasIds ?? this.regionesCompletadasIds,
      desglosePuntos: desglosePuntos ?? this.desglosePuntos,
      turno: turno ?? this.turno,
      mensajeFeedback:
          limpiarFeedback ? null : (mensajeFeedback ?? this.mensajeFeedback),
      hayJugadasDisponibles:
          hayJugadasDisponibles ?? this.hayJugadasDisponibles,
    );
  }
}

// Para avisar de algún error.
class JuegoError extends JuegoEstado {
  final String mensaje;
  final JuegoEstado estadoAnterior;

  JuegoError(this.mensaje, this.estadoAnterior);
}
