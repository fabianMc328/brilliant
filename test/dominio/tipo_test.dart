import 'dart:ui';
import 'package:test/test.dart';
import 'package:brilliant/tipo.dart';

// Revisa que cada tipo de color tenga su color, texto y puntos bien configurados.
void main() {
  group('Configuración de colores y puntos', () {
    test('TipoAzul tiene su color y puntos (7, 5, 3)', () {
      final tipo = TipoAzul();
      expect(tipo.color, const Color(0xFF2196F3));
      expect(tipo.puntuaciones, {1: 7, 2: 5, 3: 3});
      expect(tipo.esPosibleAgregar([4], 4), isTrue);
      expect(tipo.esPosibleAgregar([4], 2), isFalse);
    });

    test('TipoMorado tiene su color y puntos (7, 5, 3)', () {
      final tipo = TipoMorado();
      expect(tipo.color, const Color(0xFF8E24AA));
      expect(tipo.puntuaciones, {1: 7, 2: 5, 3: 3});
      expect(tipo.esPosibleAgregar([1, 2], 1), isTrue);
      expect(tipo.esPosibleAgregar([1, 2], 3), isFalse);
    });

    test('TipoVerde tiene su color y puntos (4, 3, 2)', () {
      final tipo = TipoVerde();
      expect(tipo.color, const Color(0xFF43A047));
      expect(tipo.puntuaciones, {1: 4, 2: 3, 3: 2});
      expect(tipo.esPosibleAgregar([1, 2, 3], 9), isTrue);
    });

    test('TipoAmarillo tiene su color y puntos (8, 6, 4)', () {
      final tipo = TipoAmarillo();
      expect(tipo.color, const Color(0xFFFFC107));
      expect(tipo.puntuaciones, {1: 8, 2: 6, 3: 4});
      expect(tipo.esPosibleAgregar([1, 2], 3), isTrue);
      expect(tipo.esPosibleAgregar([1, 2], 2), isFalse);
    });

    test('TipoRojo tiene su color y puntos (8, 6, 4)', () {
      final tipo = TipoRojo();
      expect(tipo.color, const Color(0xFFF44336));
      expect(tipo.puntuaciones, {1: 8, 2: 6, 3: 4});
      expect(tipo.esPosibleAgregar([5], 6), isTrue);
      expect(tipo.esPosibleAgregar([5], 5), isFalse);
    });
  });
}
