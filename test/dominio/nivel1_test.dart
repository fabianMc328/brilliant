import 'package:test/test.dart';
import 'package:brilliant/nivel1_tablero.dart';
import 'package:brilliant/region.dart';

// Revisa que el Nivel 1 tenga sus 49 casillas completas y sus 6 estrellas oficiales.
void main() {
  group('Mapa del Nivel 1', () {
    test('Tiene 49 casillas en una cuadrícula de 7x7 y 9 regiones', () {
      final tablero = Nivel1Config.crearTablero();
      expect(tablero.celdas.length, 49);
      expect(tablero.regiones.length, 9);
      expect(tablero.filas, 7);
      expect(tablero.columnas, 7);
    });

    test('Todas las casillas pertenecen a una sola región sin huecos ni repeticiones', () {
      final mapaCoordenadas = <Coordenada>{};
      int totalCasillas = 0;

      for (final region in Nivel1Config.regionesNivel1) {
        totalCasillas += region.coordenadas.length;
        for (final coord in region.coordenadas) {
          expect(mapaCoordenadas.contains(coord), isFalse);
          mapaCoordenadas.add(coord);
        }
      }

      expect(totalCasillas, 49);
      expect(mapaCoordenadas.length, 49);
    });

    test('Las 6 casillas iniciales con estrella son las correctas', () {
      final iniciales = Nivel1Config.casillasIniciales;
      expect(iniciales.length, 6);

      const esperadas = [
        Coordenada(1, 2),
        Coordenada(1, 5),
        Coordenada(3, 1),
        Coordenada(3, 4),
        Coordenada(5, 2),
        Coordenada(6, 4),
      ];

      expect(iniciales, containsAll(esperadas));
    });
  });
}
