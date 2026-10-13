import 'package:test/test.dart';
import 'package:brilliant/reglas.dart';

// Pruebas para checar que cada color respete su regla al meter números.
void main() {
  group('Reglas de colocación por color', () {
    group('Azul (todos iguales)', () {
      test('Acepta el primer número en una zona vacía', () {
        expect(todosIgualesAlInsertar([], 5), isTrue);
      });

      test('Acepta si metemos el mismo número', () {
        expect(todosIgualesAlInsertar([3, 3, 3], 3), isTrue);
      });

      test('Rechaza si metemos un número diferente', () {
        expect(todosIgualesAlInsertar([3, 3], 4), isFalse);
      });
    });

    group('Amarillo y Rojo (todos distintos)', () {
      test('Acepta en lista vacía', () {
        expect(todosDiferentesAlInsertar([], 5), isTrue);
      });

      test('Acepta un número que no se repite', () {
        expect(todosDiferentesAlInsertar([1, 2, 3], 4), isTrue);
      });

      test('Rechaza si el número ya estaba puesto', () {
        expect(todosDiferentesAlInsertar([1, 2, 3], 2), isFalse);
      });

      test('Rechaza si la lista ya venía con repetidos', () {
        expect(todosDiferentesAlInsertar([1, 2, 2], 5), isFalse);
      });
    });

    group('Morado (máximo 2 valores diferentes)', () {
      test('Acepta el primer número', () {
        expect(areaMorada([], 4), isTrue);
        expect(AreaMorada([], 4), isTrue);
      });

      test('Acepta un segundo número diferente', () {
        expect(areaMorada([4, 4], 2), isTrue);
      });

      test('Acepta repetir alguno de los dos que ya están', () {
        expect(areaMorada([1, 2, 1], 1), isTrue);
        expect(areaMorada([1, 2, 1], 2), isTrue);
      });

      test('Rechaza meter un tercer número distinto', () {
        expect(areaMorada([1, 2, 1], 3), isFalse);
      });
    });

    group('Verde (cualquiera es válido)', () {
      test('Pasa cualquier número sin importar nada', () {
        expect(cualquierNumeroAlInsertar([], 1), isTrue);
        expect(cualquierNumeroAlInsertar([1, 2, 3], 4), isTrue);
        expect(cualquierNumeroAlInsertar([5, 5], 5), isTrue);
      });
    });
  });
}
