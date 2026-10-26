import 'package:test/test.dart';
import 'package:brilliant/niveles/nivel_4.dart';
import 'package:brilliant/region.dart';

void main() {
  group('Mapa del Nivel 4', () {
    final nivel = Nivel4Definicion();

    test('Tiene 49 casillas en una cuadrícula de 7x7 y 9 regiones', () {
      final tablero = nivel.crearTablero();
      expect(tablero.celdas.length, 49);
      expect(tablero.regiones.length, 9);
      expect(tablero.filas, 7);
      expect(tablero.columnas, 7);
    });

    test('Todas las casillas pertenecen a una sola región sin huecos ni repeticiones', () {
      final mapaCoordenadas = <Coordenada>{};
      int totalCasillas = 0;

      for (final region in nivel.regiones) {
        totalCasillas += region.coordenadas.length;
        for (final coord in region.coordenadas) {
          expect(mapaCoordenadas.contains(coord), isFalse,
              reason: 'Coordenada repetida: $coord');
          mapaCoordenadas.add(coord);
        }
      }

      expect(totalCasillas, 49);
      expect(mapaCoordenadas.length, 49);
    });

    test('Las 6 casillas iniciales con estrella son las correctas y están en regiones distintas', () {
      final iniciales = nivel.casillasIniciales;
      expect(iniciales.length, 6);

      const esperadas = [
        Coordenada(0, 4),
        Coordenada(2, 2),
        Coordenada(2, 5),
        Coordenada(3, 0),
        Coordenada(5, 4),
        Coordenada(6, 1),
      ];

      expect(iniciales, containsAll(esperadas));

      final regionesConEstrella = <String>{};
      for (final coord in iniciales) {
        final region = nivel.regiones.firstWhere((r) => r.contiene(coord));
        expect(regionesConEstrella.contains(region.id), isFalse);
        regionesConEstrella.add(region.id);
      }
      expect(regionesConEstrella.length, 6);
    });
  });
}
