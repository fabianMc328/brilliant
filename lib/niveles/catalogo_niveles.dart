import 'nivel_definicion.dart';
import 'nivel_1.dart';
import 'nivel_2.dart';
import 'nivel_3.dart';
import 'nivel_4.dart';

// Lista con los 4 niveles del juego.
class CatalogoNiveles {
  static final List<NivelDefinicion> todos = [
    Nivel1Definicion(),
    Nivel2Definicion(),
    Nivel3Definicion(),
    Nivel4Definicion(),
  ];

  static NivelDefinicion get nivel1 => todos[0];
  static NivelDefinicion get nivel2 => todos[1];
  static NivelDefinicion get nivel3 => todos[2];
  static NivelDefinicion get nivel4 => todos[3];

  // Busca el nivel por número (1 al 4).
  static NivelDefinicion porNumero(int numero) {
    return todos.firstWhere(
      (n) => n.numero == numero,
      orElse: () => nivel1,
    );
  }

  // Busca el nivel por su id.
  static NivelDefinicion porId(String id) {
    return todos.firstWhere(
      (n) => n.id == id,
      orElse: () => nivel1,
    );
  }
}
