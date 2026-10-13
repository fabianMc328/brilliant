import 'package:test/test.dart';
import 'package:brilliant/region.dart';
import 'package:brilliant/tipo.dart';

// Verifica que las coordenadas comparen bien y que las regiones guarden sus casillas.
void main() {
  group('Coordenadas y Regiones', () {
    test('Coordenada compara bien por x e y', () {
      const c1 = Coordenada(1, 2);
      const c2 = Coordenada(1, 2);
      const c3 = Coordenada(2, 1);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1 == c3, isFalse);
      expect(c1.toString(), '(1, 2)');
    });

    test('Region sabe si tiene una coordenada adentro', () {
      final region = Region(
        id: 'region_prueba',
        tipo: TipoAzul(),
        coordenadas: {const Coordenada(0, 0), const Coordenada(0, 1)},
      );

      expect(region.contiene(const Coordenada(0, 0)), isTrue);
      expect(region.contiene(const Coordenada(0, 1)), isTrue);
      expect(region.contiene(const Coordenada(1, 0)), isFalse);
    });
  });
}
