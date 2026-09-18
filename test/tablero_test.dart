import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/tablero.dart';
import 'package:brilliant/region.dart';
import 'package:brilliant/tipo.dart'; // Para poder usar TipoAzul, TipoAmarillo, etc.

void main() {
  group('Pruebas del Tablero y Regiones', () {
    
    test('El tablero debe iniciar vacío y mapear las celdas a la región correcta', () {
      final regionAzul = Region(
        id: 'R1',
        tipo: TipoAzul(),
        coordenadas: {
          const Coordenada(0, 0),
          const Coordenada(0, 1),
        },
      );

      final tablero = Tablero(filas: 2, columnas: 2);
      tablero.cargarRegiones([regionAzul]);

      // Verificar que la celda (0,0) le pertenece a regionAzul
      expect(tablero.celdas[const Coordenada(0, 0)]?.region.id, 'R1');
      
      // Verificar que inicia vacía (el valor es null)
      expect(tablero.celdas[const Coordenada(0, 0)]?.estaVacia, isTrue);
      
      // Verificar que una coordenada fuera de la región no existe en el mapa
      expect(tablero.celdas[const Coordenada(1, 1)], isNull);
    });

    test('Regla Tipo Azul: Todos los números deben ser IGUALES', () {
      final regionAzul = Region(
        id: 'R_Azul',
        tipo: TipoAzul(),
        coordenadas: {
          const Coordenada(0, 0),
          const Coordenada(0, 1),
        },
      );

      final tablero = Tablero(filas: 2, columnas: 2);
      tablero.cargarRegiones([regionAzul]);

      // El primer número siempre debe ser válido si está vacío
      bool sePudoColocar = tablero.colocarNumero(const Coordenada(0, 0), 5);
      expect(sePudoColocar, isTrue);
      expect(tablero.celdas[const Coordenada(0, 0)]?.valor, 5);

      // Intentar colocar un número diferente (debe ser rechazado por la regla)
      bool intentoFallido = tablero.colocarNumero(const Coordenada(0, 1), 3);
      expect(intentoFallido, isFalse, reason: 'TipoAzul no permite números distintos'); 
      expect(tablero.celdas[const Coordenada(0, 1)]?.estaVacia, isTrue); // Sigue intacta

      // Intentar colocar el MISMO número (debe ser aceptado)
      bool intentoExitoso = tablero.colocarNumero(const Coordenada(0, 1), 5);
      expect(intentoExitoso, isTrue);
      expect(tablero.celdas[const Coordenada(0, 1)]?.valor, 5);
    });

    test('Regla Tipo Amarillo: Todos los números deben ser DISTINTOS', () {
      final regionAmarilla = Region(
        id: 'R_Amarilla',
        tipo: TipoAmarillo(),
        coordenadas: {
          const Coordenada(1, 0),
          const Coordenada(1, 1),
        },
      );

      final tablero = Tablero(filas: 2, columnas: 2);
      tablero.cargarRegiones([regionAmarilla]);

      // Colocamos un 4 con éxito
      expect(tablero.colocarNumero(const Coordenada(1, 0), 4), isTrue);

      // Intentar colocar otro 4 (debe ser rechazado)
      expect(tablero.colocarNumero(const Coordenada(1, 1), 4), isFalse);

      // Colocar un 7 (debe funcionar porque es un número nuevo)
      expect(tablero.colocarNumero(const Coordenada(1, 1), 7), isTrue);
    });

    test('Regla Universal: No se puede sobreescribir una celda ya ocupada', () {
      final regionVerde = Region(
        id: 'R_Verde',
        tipo: TipoVerde(), // Verde acepta cualquier número siempre
        coordenadas: {const Coordenada(0, 0)},
      );

      final tablero = Tablero(filas: 1, columnas: 1);
      tablero.cargarRegiones([regionVerde]);

      // Colocamos un 2
      expect(tablero.colocarNumero(const Coordenada(0, 0), 2), isTrue);
      
      // Intentar poner un 9 en la MISMA coordenada (rechazado, ya está ocupada)
      expect(tablero.colocarNumero(const Coordenada(0, 0), 9), isFalse);
      
      // Asegurarnos de que el valor no cambió y sigue siendo 2
      expect(tablero.celdas[const Coordenada(0, 0)]?.valor, 2);
    });

  });
}
