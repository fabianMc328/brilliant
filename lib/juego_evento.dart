import 'niveles/nivel_definicion.dart';
import 'region.dart';

abstract class JuegoEvento {}

// Arranca el juego con las estrellas del nivel.
class IniciarConfiguracionInicial extends JuegoEvento {
  final List<Coordenada> casillasInciales;
  final NivelDefinicion? nivel;

  IniciarConfiguracionInicial(this.casillasInciales, {this.nivel});
}

// Arranca directo pasándole el nivel.
class IniciarNivel extends JuegoEvento {
  final NivelDefinicion nivel;

  IniciarNivel(this.nivel);
}

// Coloca un número del 1 al 6 en una estrella.
class ColocarValorInicial extends JuegoEvento {
  final Coordenada coordenada;
  final int valor;

  ColocarValorInicial(this.coordenada, this.valor);
}

// Pasa a la fase de tirar dados.
class AvanzarJuego extends JuegoEvento {}

// Llena las 6 estrellas al azar.
class LlenarValoresAleatorios extends JuegoEvento {}

// Borra los números de las estrellas.
class LimpiarValoresIniciales extends JuegoEvento {}

// Tira los 2 dados.
class TirarDados extends JuegoEvento {}

// Elige una casilla como ancla.
class SeleccionarAncla extends JuegoEvento {
  final Coordenada coordenada;

  SeleccionarAncla(this.coordenada);
}

// Pone el número en una casilla verde válida.
class ColocarNumero extends JuegoEvento {
  final Coordenada coordenada;

  ColocarNumero(this.coordenada);
}

// Desmarca el ancla que teníamos elegida.
class DeseleccionarAncla extends JuegoEvento {}

// Pasa el turno si no hay jugadas.
class PasarTurno extends JuegoEvento {}
