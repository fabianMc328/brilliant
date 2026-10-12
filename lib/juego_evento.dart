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

/// Evento para pasar a la Fase 2 del juego ("Comenzar Nivel").
class AvanzarJuego extends JuegoEvento {}

/// Llena las 6 casillas iniciales con números del 1 al 6 de forma aleatoria.
class LlenarValoresAleatorios extends JuegoEvento {}

/// Limpia todos los valores colocados en las casillas iniciales.
class LimpiarValoresIniciales extends JuegoEvento {}

/// Fase 2: Tirar los 2 dados.
class TirarDados extends JuegoEvento {}

/// Fase 2: Seleccionar una casilla como ancla (debe coincidir con uno de los dados).
class SeleccionarAncla extends JuegoEvento {
  final Coordenada coordenada;

  SeleccionarAncla(this.coordenada);
}

/// Fase 2: Colocar el número en una de las casillas válidas iluminadas.
class ColocarNumero extends JuegoEvento {
  final Coordenada coordenada;

  ColocarNumero(this.coordenada);
}

/// Fase 2: Deseleccionar el ancla activa actual.
class DeseleccionarAncla extends JuegoEvento {}

/// Fase 2: Pasar turno cuando no hay jugadas o se decide no jugar.
class PasarTurno extends JuegoEvento {}
