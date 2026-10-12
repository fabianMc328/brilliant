import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/tablero.dart';
import 'package:brilliant/region.dart';
import 'package:brilliant/tipo.dart'; // Para poder usar TipoAzul, TipoAmarillo, etc.
import 'package:brilliant/nivel1_tablero.dart';

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

    test('Nivel1Config: El tablero oficial de Nivel 1 debe tener 49 casillas y 9 regiones', () {
      final tablero = Nivel1Config.crearTablero();
      expect(tablero.celdas.length, 49);
      expect(tablero.regiones.length, 9);

      // Verificar que las 6 casillas iniciales existan
      for (final coord in Nivel1Config.casillasIniciales) {
        expect(tablero.celdas.containsKey(coord), isTrue);
      }
    });

    test('obtenerPosiblesLugaresParaAncla: Sólo ilumina vecinos ortogonales válidos según la región', () {
      final tablero = Nivel1Config.crearTablero();
      // Casilla (1, 2) es Azul (id: azul_1). Sus vecinos son: (0, 2)[Azul], (2, 2)[Rojo], (1, 1)[Verde], (1, 3)[Azul]
      // Si colocamos un 5 en (1, 2):
      tablero.celdas[const Coordenada(1, 2)]?.valor = 5;

      // Si queremos colocar un 5 adyacente a esa ancla:
      // - (0, 2) [Azul]: acepta 5 (todos iguales) -> Válido
      // - (1, 3) [Azul]: acepta 5 (todos iguales) -> Válido
      // - (1, 1) [Verde]: acepta cualquier número (5) -> Válido
      // - (2, 2) [Rojo]: acepta 5 (todos distintos) -> Válido
      final lugaresPara5 = tablero.obtenerPosiblesLugaresParaAncla(const Coordenada(1, 2), 5);
      expect(lugaresPara5.contains(const Coordenada(0, 2)), isTrue);
      expect(lugaresPara5.contains(const Coordenada(1, 3)), isTrue);
      expect(lugaresPara5.contains(const Coordenada(1, 1)), isTrue);
      expect(lugaresPara5.contains(const Coordenada(2, 2)), isTrue);

      // Ahora colocamos un 2 en la casilla vecina (0, 2)[Azul] para probar restricción de TipoAzul
      tablero.celdas[const Coordenada(0, 2)]?.valor = null; // la dejamos vacía
      tablero.celdas[const Coordenada(1, 3)]?.valor = 5; // ocupada con 5

      // Si intentamos colocar un 3 en (0, 2)[Azul], debe rechazarse porque la región Azul ya tiene un 5
      final lugaresPara3 = tablero.obtenerPosiblesLugaresParaAncla(const Coordenada(1, 2), 3);
      expect(lugaresPara3.contains(const Coordenada(0, 2)), isFalse,
          reason: 'TipoAzul no permite 3 porque la región ya contiene un 5');
    });

    test('Cálculo de puntuación: Suma puntos correctos al completar regiones', () {
      final tablero = Nivel1Config.crearTablero();
      final regionAzul1 = tablero.regiones.firstWhere((r) => r.id == 'azul_1');

      // Inicialmente no está completa
      expect(tablero.esRegionCompleta(regionAzul1), isFalse);

      // Llenamos todas las casillas de regionAzul1 con el número 4
      for (final coord in regionAzul1.coordenadas) {
        tablero.celdas[coord]?.valor = 4;
      }

      expect(tablero.esRegionCompleta(regionAzul1), isTrue);

      // Calcular puntuación con azul_1 completada (debe ser 7 pts para la 1ª región azul)
      final puntos = tablero.calcularPuntuacionTotal(['azul_1']);
      expect(puntos, 7);

      final desglose = tablero.calcularDesglosePuntos(['azul_1']);
      expect(desglose['azul_1'], 7);
    });

  });
}
