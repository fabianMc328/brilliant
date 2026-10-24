import 'dart:ui';
import 'reglas.dart';

// Color, regla y puntos de cada zona.
abstract class Tipo {
  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);
  Map<int, int> get puntuaciones;
}

// Azul: puros números iguales.
class TipoAzul extends Tipo {
  final Map<int, int> _puntuaciones;

  TipoAzul([Map<int, int>? puntuaciones])
      : _puntuaciones = puntuaciones ?? const {1: 7, 2: 5, 3: 3};

  @override
  Color get color => const Color(0xFF2196F3);

  @override
  String get descripcion => 'Todos los números deben de ser iguales';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      todosIgualesAlInsertar(actuales, posible);

  @override
  Map<int, int> get puntuaciones => _puntuaciones;
}

// Gris: números iguales también.
class TipoGris extends Tipo {
  final Map<int, int> _puntuaciones;

  TipoGris([Map<int, int>? puntuaciones])
      : _puntuaciones = puntuaciones ?? const {1: 3, 2: 2, 3: 1};

  @override
  Color get color => const Color(0xFF94A3B8);

  @override
  String get descripcion => 'Todos los números deben de ser iguales';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      todosIgualesAlInsertar(actuales, posible);

  @override
  Map<int, int> get puntuaciones => _puntuaciones;
}

// Morado: máximo 2 números diferentes.
class TipoMorado extends Tipo {
  final Map<int, int> _puntuaciones;

  TipoMorado([Map<int, int>? puntuaciones])
      : _puntuaciones = puntuaciones ?? const {1: 7, 2: 5, 3: 3};

  @override
  Color get color => const Color(0xFF8E24AA);

  @override
  String get descripcion =>
      'Puede haber como máximo 2 valores distintos en la región';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      areaMorada(actuales, posible);

  @override
  Map<int, int> get puntuaciones => _puntuaciones;
}

// Verde: puedes poner el que quieras.
class TipoVerde extends Tipo {
  final Map<int, int> _puntuaciones;

  TipoVerde([Map<int, int>? puntuaciones])
      : _puntuaciones = puntuaciones ?? const {1: 4, 2: 3, 3: 2};

  @override
  Color get color => const Color(0xFF43A047);

  @override
  String get descripcion => 'Puede ser cualquier número';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      cualquierNumeroAlInsertar(actuales, posible);

  @override
  Map<int, int> get puntuaciones => _puntuaciones;
}

// Amarillo: todos tienen que ser diferentes.
class TipoAmarillo extends Tipo {
  final Map<int, int> _puntuaciones;

  TipoAmarillo([Map<int, int>? puntuaciones])
      : _puntuaciones = puntuaciones ?? const {1: 8, 2: 6, 3: 4};

  @override
  Color get color => const Color(0xFFFFC107);

  @override
  String get descripcion => 'Todos los números deben de ser distintos';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      todosDiferentesAlInsertar(actuales, posible);

  @override
  Map<int, int> get puntuaciones => _puntuaciones;
}

// Rojo: todos tienen que ser diferentes.
class TipoRojo extends Tipo {
  final Map<int, int> _puntuaciones;

  TipoRojo([Map<int, int>? puntuaciones])
      : _puntuaciones = puntuaciones ?? const {1: 8, 2: 6, 3: 4};

  @override
  Color get color => const Color(0xFFF44336);

  @override
  String get descripcion => 'Todos los números deben de ser distintos';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      todosDiferentesAlInsertar(actuales, posible);

  @override
  Map<int, int> get puntuaciones => _puntuaciones;
}

// Naranja 1 a 3: solo números del 1 al 3.
class TipoNaranja1a3 extends Tipo {
  final Map<int, int> _puntuaciones;

  TipoNaranja1a3([Map<int, int>? puntuaciones])
      : _puntuaciones = puntuaciones ?? const {1: 6, 2: 4, 3: 3};

  @override
  Color get color => const Color(0xFFF97316);

  @override
  String get descripcion => 'Solo números del 1 al 3';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      numeroEnRangoAlInsertar(actuales, posible, 1, 3);

  @override
  Map<int, int> get puntuaciones => _puntuaciones;
}

// Naranja 4 a 6: solo números del 4 al 6.
class TipoNaranja4a6 extends Tipo {
  final Map<int, int> _puntuaciones;

  TipoNaranja4a6([Map<int, int>? puntuaciones])
      : _puntuaciones = puntuaciones ?? const {1: 6, 2: 4, 3: 3};

  @override
  Color get color => const Color(0xFFEA580C);

  @override
  String get descripcion => 'Solo números del 4 al 6';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      numeroEnRangoAlInsertar(actuales, posible, 4, 6);

  @override
  Map<int, int> get puntuaciones => _puntuaciones;
}
