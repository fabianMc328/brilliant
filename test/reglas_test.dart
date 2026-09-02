import 'package:test/test.dart';
import 'package:brilliant/reglas.dart';

void main() {
  group('Pruebas para todosDiferentesAlInsertar', () {
    test('Debe retornar true al insertar un número en una lista vacía', () {
      expect(todosDiferentesAlInsertar([], 5), isTrue);
    });

    test('Debe retornar true cuando los elementos son únicos y el número no existe', () {
      expect(todosDiferentesAlInsertar([1, 2, 3, 4], 5), isTrue);
    });

    test('Debe retornar false cuando el número a insertar ya existe', () {
      expect(todosDiferentesAlInsertar([1, 2, 3, 4], 3), isFalse);
    });

    test('Debe retornar false si la lista ya contenía duplicados previos', () {
      expect(todosDiferentesAlInsertar([1, 2, 2, 4], 5), isFalse);
    });

    test('Debe validar números negativos y cero', () {
      expect(todosDiferentesAlInsertar([-1, 0, 2], 1), isTrue);
      expect(todosDiferentesAlInsertar([-1, 0, 2], 0), isFalse);
    });
  });
}
