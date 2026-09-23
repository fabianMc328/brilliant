import 'region.dart';

abstract class JuegoEvento {}

/// Carga el tablero y define cuáles son las casillas inciales.
class IniciarConfiguracionInicial extends JuegoEvento {
  final List<Coordenada> casillasInciales;

  IniciarConfiguracionInicial(this.casillasInciales);
}

/// El jugador coloca un número (del 1 al 6) en una casilla inicial.
class ColocarValorInicial extends JuegoEvento {
  final Coordenada coordenada;
  final int valor;

  ColocarValorInicial(this.coordenada, this.valor);
}

/// Evento para intentar pasar a la Fase 2 del juego (o avanzar turno).
class AvanzarJuego extends JuegoEvento {}
