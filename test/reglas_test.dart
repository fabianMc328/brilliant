import 'package:test/test.dart';
import 'package:brilliant/reglas.dart';

void main() {
  group('Regla Azul (todosIgualesAlInsertar)', () {
    test('Debe retornar true al insertar en lista vacía', () {
      expect(todosIgualesAlInsertar([], 5), isTrue);
    });

    test('Debe retornar true cuando todos los números ya existentes son iguales al nuevo', () {
      expect(todosIgualesAlInsertar([3, 3, 3], 3), isTrue);
    });

    test('Debe retornar false si el número a insertar es diferente a los existentes', () {
      expect(todosIgualesAlInsertar([3, 3], 4), isFalse);
    });
  });

  group('Regla Amarillo y Rojo (todosDiferentesAlInsertar)', () {
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

  group('Regla Morado (areaMorada / AreaMorada)', () {
    test('Debe retornar true al insertar el primer número en un área vacía', () {
      expect(areaMorada([], 4), isTrue);
      expect(AreaMorada([], 4), isTrue);
    });

    test('Debe retornar true al insertar un segundo valor diferente', () {
      final area = [4, 4];
      expect(areaMorada(area, 2), isTrue);
    });

    test('Debe retornar true al repetir uno de los dos valores ya existentes', () {
      final area = [1, 2, 1, 2];
      expect(areaMorada(area, 1), isTrue);
      expect(areaMorada(area, 2), isTrue);
    });

    test('Debe retornar false al intentar ingresar un tercer valor diferente', () {
      final area = [1, 2, 1];
      expect(areaMorada(area, 3), isFalse);
    });

    test('Debe retornar false si el área ya contenía 3 o más valores distintos', () {
      final area = [1, 2, 3];
      expect(areaMorada(area, 2), isFalse);
    });
  });

  group('Regla Verde (cualquierNumeroAlInsertar)', () {
    test('Debe retornar true siempre para cualquier número', () {
      expect(cualquierNumeroAlInsertar([], 1), isTrue);
      expect(cualquierNumeroAlInsertar([1, 2, 3], 4), isTrue);
      expect(cualquierNumeroAlInsertar([5, 5, 5], 5), isTrue);
    });
  });
}
