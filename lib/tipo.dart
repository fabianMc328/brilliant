import 'dart:ui';
 
import 'reglas.dart';
 
abstract class Tipo {
  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);
  Map<int, int> get puntuaciones;
}
 
/// Azul: todos los números de la región deben ser iguales.
class TipoAzul extends Tipo {
  @override
  Color get color => const Color(0xFF2196F3);
 
  @override
  String get descripcion => 'Todos los números deben de ser iguales';
 
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element == posible);
  }
 
  @override
  Map<int, int> get puntuaciones => {
        1: 7,
        2: 5,
        3: 3,
      };
}
 
/// Morado: usa la regla que ya tenías probada en reglas.dart (AreaMorada) —
/// como máximo 2 valores distintos en la región.
class TipoMorado extends Tipo {
  @override
  Color get color => const Color(0xFF8E24AA);
 
  @override
  String get descripcion => 'Puede haber como máximo 2 valores distintos en la región';
 
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return AreaMorada(actuales, posible);
  }
 
  @override
  Map<int, int> get puntuaciones => {
        1: 7,
        2: 5,
        3: 3,
      };
}