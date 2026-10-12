import 'region.dart';
import 'tipo.dart';
import 'tablero.dart';

/// Configuración y definición de las regiones oficiales del Nivel 1 de Brilliant.
class Nivel1Config {
  /// Lista de las 9 regiones que conforman el tablero 7x7 (49 casillas en total).
  static List<Region> get regionesNivel1 => [
        // 1. Azul 1 (Centro superior - 4 casillas)
        Region(
          id: 'azul_1',
          tipo: TipoAzul(),
          coordenadas: {
            const Coordenada(0, 2),
            const Coordenada(1, 2), // Estrella inicial
            const Coordenada(1, 3),
            const Coordenada(2, 3),
          },
        ),

        // 2. Azul 2 (Abajo a la derecha - 4 casillas)
        Region(
          id: 'azul_2',
          tipo: TipoAzul(),
          coordenadas: {
            const Coordenada(4, 6),
            const Coordenada(5, 5),
            const Coordenada(5, 6),
            const Coordenada(6, 5),
          },
        ),

        // 3. Morado 1 (Arriba a la derecha - 6 casillas)
        Region(
          id: 'morado_1',
          tipo: TipoMorado(),
          coordenadas: {
            const Coordenada(0, 3),
            const Coordenada(0, 4),
            const Coordenada(0, 5),
            const Coordenada(1, 4),
            const Coordenada(1, 5), // Estrella inicial
            const Coordenada(2, 4),
          },
        ),

        // 4. Morado 2 (Abajo a la izquierda - 6 casillas)
        Region(
          id: 'morado_2',
          tipo: TipoMorado(),
          coordenadas: {
            const Coordenada(3, 2),
            const Coordenada(4, 2),
            const Coordenada(4, 3),
            const Coordenada(5, 2), // Estrella inicial
            const Coordenada(6, 1),
            const Coordenada(6, 2),
          },
        ),

        // 5. Rojo 1 (Izquierda central - 6 casillas)
        Region(
          id: 'rojo_1',
          tipo: TipoRojo(),
          coordenadas: {
            const Coordenada(2, 1),
            const Coordenada(2, 2),
            const Coordenada(3, 1), // Estrella inicial
            const Coordenada(4, 1),
            const Coordenada(5, 0),
            const Coordenada(5, 1),
          },
        ),

        // 6. Rojo 2 (Abajo al centro - 6 casillas)
        Region(
          id: 'rojo_2',
          tipo: TipoRojo(),
          coordenadas: {
            const Coordenada(4, 4),
            const Coordenada(4, 5),
            const Coordenada(5, 3),
            const Coordenada(5, 4),
            const Coordenada(6, 3),
            const Coordenada(6, 4), // Estrella inicial
          },
        ),

        // 7. Verde 1 (Columna izquierda y arriba - 6 casillas)
        Region(
          id: 'verde_1',
          tipo: TipoVerde(),
          coordenadas: {
            const Coordenada(0, 1),
            const Coordenada(1, 0),
            const Coordenada(1, 1),
            const Coordenada(2, 0),
            const Coordenada(3, 0),
            const Coordenada(4, 0),
          },
        ),

        // 8. Verde 2 (Derecha central - 6 casillas)
        Region(
          id: 'verde_2',
          tipo: TipoVerde(),
          coordenadas: {
            const Coordenada(1, 6),
            const Coordenada(2, 5),
            const Coordenada(2, 6),
            const Coordenada(3, 4), // Estrella inicial
            const Coordenada(3, 5),
            const Coordenada(3, 6),
          },
        ),

        // 9. Amarillo 1 (4 esquinas + centro - 5 casillas)
        Region(
          id: 'amarillo_1',
          tipo: TipoAmarillo(),
          coordenadas: {
            const Coordenada(0, 0),
            const Coordenada(0, 6),
            const Coordenada(3, 3),
            const Coordenada(6, 0),
            const Coordenada(6, 6),
          },
        ),
      ];

  /// Las 6 coordenadas iniciales con estrella del Nivel 1.
  static final List<Coordenada> casillasIniciales = [
    const Coordenada(1, 2), // Azul 1
    const Coordenada(1, 5), // Morado 1
    const Coordenada(3, 1), // Rojo 1
    const Coordenada(3, 4), // Verde 2
    const Coordenada(5, 2), // Morado 2
    const Coordenada(6, 4), // Rojo 2
  ];

  /// Crea e inicializa una nueva instancia de Tablero de 7x7 con las regiones de Nivel 1.
  static Tablero crearTablero() {
    final tablero = Tablero(filas: 7, columnas: 7);
    tablero.cargarRegiones(regionesNivel1);
    return tablero;
  }
}
