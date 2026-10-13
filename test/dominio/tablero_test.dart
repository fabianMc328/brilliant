import 'package:test/test.dart';
import 'package:brilliant/tablero.dart';
import 'package:brilliant/region.dart';
import 'package:brilliant/tipo.dart';

// Prueba cómo se comporta el tablero, sus casillas, vecinos y el conteo de puntos.
void main() {
  group('Tablero y Celdas', () {
    test('Celda guarda si tiene número o si sigue vacía', () {
      final region = Region(
        id: 'r1',
        tipo: TipoVerde(),
        coordenadas: {const Coordenada(0, 0)},
      );
      final celda = Celda(coordenada: const Coordenada(0, 0), region: region);

      expect(celda.estaVacia, isTrue);
      expect(celda.valor, isNull);

      celda.valor = 6;
      expect(celda.estaVacia, isFalse);
      expect(celda.valor, 6);
    });

    test('Tablero inicia con sus celdas conectadas a sus regiones', () {
      final region = Region(
        id: 'r_azul',
        tipo: TipoAzul(),
        coordenadas: {const Coordenada(0, 0), const Coordenada(0, 1)},
      );
      final tablero = Tablero(filas: 2, columnas: 2);
      tablero.cargarRegiones([region]);

      expect(tablero.regiones.length, 1);
      expect(tablero.celdas.length, 2);
      expect(tablero.celdas[const Coordenada(0, 0)]?.region.id, 'r_azul');
      expect(tablero.celdas[const Coordenada(1, 1)], isNull);
    });

    test('Busca vecinos de arriba, abajo y lados sin salirse del mapa', () {
      final tablero = Tablero(filas: 7, columnas: 7);

      final esquina = tablero.obtenerVecinosOrtogonales(const Coordenada(0, 0));
      expect(esquina.length, 2);
      expect(esquina, containsAll([const Coordenada(1, 0), const Coordenada(0, 1)]));

      final borde = tablero.obtenerVecinosOrtogonales(const Coordenada(3, 0));
      expect(borde.length, 3);

      final centro = tablero.obtenerVecinosOrtogonales(const Coordenada(3, 3));
      expect(centro.length, 4);
    });

    test('No deja poner números fuera del mapa ni sobreescribir casillas', () {
      final tablero = Tablero(filas: 2, columnas: 2);
      final region = Region(
        id: 'r1',
        tipo: TipoVerde(),
        coordenadas: {const Coordenada(0, 0)},
      );
      tablero.cargarRegiones([region]);

      expect(tablero.colocarNumero(const Coordenada(5, 5), 1), isFalse);
      expect(tablero.colocarNumero(const Coordenada(0, 0), 2), isTrue);
      expect(tablero.colocarNumero(const Coordenada(0, 0), 3), isFalse);
      expect(tablero.celdas[const Coordenada(0, 0)]?.valor, 2);
    });

    test('Sabe cuándo una región se llenó y calcula los puntos acumulados', () {
      final regionAzul1 = Region(
        id: 'azul_1',
        tipo: TipoAzul(),
        coordenadas: {const Coordenada(0, 0), const Coordenada(0, 1)},
      );
      final regionAzul2 = Region(
        id: 'azul_2',
        tipo: TipoAzul(),
        coordenadas: {const Coordenada(1, 0), const Coordenada(1, 1)},
      );

      final tablero = Tablero(filas: 2, columnas: 2);
      tablero.cargarRegiones([regionAzul1, regionAzul2]);

      expect(tablero.esRegionCompleta(regionAzul1), isFalse);

      tablero.celdas[const Coordenada(0, 0)]?.valor = 3;
      tablero.celdas[const Coordenada(0, 1)]?.valor = 3;

      expect(tablero.esRegionCompleta(regionAzul1), isTrue);

      final desglose = tablero.calcularDesglosePuntos(['azul_1']);
      expect(desglose['azul_1'], 7);
      expect(tablero.calcularPuntuacionTotal(['azul_1']), 7);
    });
  });
}
