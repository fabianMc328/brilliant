import 'region.dart';

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

/// Fase 2: El juego ha comenzado
class JuegoEnProgreso extends JuegoEstado {
  // Aquí se manejará el estado durante la partida
}

/// Estado para mostrar errores (ej. intentar colocar un número repetido)
class JuegoError extends JuegoEstado {
  final String mensaje;
  final JuegoEstado estadoAnterior;

  JuegoError(this.mensaje, this.estadoAnterior);
}
