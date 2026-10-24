import 'region.dart';
import 'tablero.dart';
import 'niveles/nivel_1.dart';
import 'niveles/nivel_definicion.dart';

// Configuración del nivel 1 (por compatibilidad con pruebas viejas).
class Nivel1Config {
  static final NivelDefinicion definicion = Nivel1Definicion();

  static List<Region> get regionesNivel1 => definicion.regiones;
  static List<Coordenada> get casillasIniciales => definicion.casillasIniciales;
  static Tablero crearTablero() => definicion.crearTablero();
}
