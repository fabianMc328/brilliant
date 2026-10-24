import 'package:flutter/material.dart';
import '../region.dart';
import '../tipo.dart';
import 'nivel_definicion.dart';

// Nivel 3: mapa simétrico con zona gris más grande.
class Nivel3Definicion extends NivelDefinicion {
  @override
  int get numero => 3;

  @override
  String get id => 'nivel_3';

  @override
  String get nombre => 'Nivel 3';

  @override
  String get dificultad => 'Avanzado';

  @override
  Color get colorTema => const Color(0xFFFCE4EC);

  @override
  String get descripcion =>
      'Diseño simétrico desafiante con una gran franja verde inferior y zona Gris de 5 casillas.';

  @override
  List<Region> get regiones => [
        // Amarillo 1
        Region(
          id: 'amarillo_1',
          tipo: TipoAmarillo(const {1: 7, 2: 5, 3: 3}),
          coordenadas: {
            const Coordenada(0, 0),
            const Coordenada(0, 1),
            const Coordenada(1, 1),
            const Coordenada(0, 5),
            const Coordenada(0, 6),
            const Coordenada(1, 5), // Estrella
          },
        ),

        // Morado 1
        Region(
          id: 'morado_1',
          tipo: TipoMorado(const {1: 7, 2: 5, 3: 3}),
          coordenadas: {
            const Coordenada(0, 2),
            const Coordenada(0, 4),
            const Coordenada(1, 2), // Estrella
            const Coordenada(1, 3),
            const Coordenada(1, 4),
            const Coordenada(2, 3),
          },
        ),

        // Morado 2
        Region(
          id: 'morado_2',
          tipo: TipoMorado(const {1: 7, 2: 5, 3: 3}),
          coordenadas: {
            const Coordenada(6, 0),
            const Coordenada(6, 1),
            const Coordenada(6, 2), // Estrella
            const Coordenada(6, 4),
            const Coordenada(6, 5),
            const Coordenada(6, 6),
          },
        ),

        // Rojo 1
        Region(
          id: 'rojo_1',
          tipo: TipoRojo(const {1: 6, 2: 4, 3: 2}),
          coordenadas: {
            const Coordenada(2, 0),
            const Coordenada(2, 1),
            const Coordenada(2, 2),
            const Coordenada(3, 0),
            const Coordenada(3, 1),
            const Coordenada(3, 2),
          },
        ),

        // Rojo 2
        Region(
          id: 'rojo_2',
          tipo: TipoRojo(const {1: 6, 2: 4, 3: 2}),
          coordenadas: {
            const Coordenada(2, 4),
            const Coordenada(2, 5),
            const Coordenada(2, 6),
            const Coordenada(3, 4),
            const Coordenada(3, 5),
            const Coordenada(3, 6),
          },
        ),

        // Azul 1
        Region(
          id: 'azul_1',
          tipo: TipoAzul(const {1: 7, 2: 5, 3: 3}),
          coordenadas: {
            const Coordenada(4, 1), // Estrella
            const Coordenada(4, 2),
            const Coordenada(4, 3),
            const Coordenada(4, 4),
            const Coordenada(4, 5),
          },
        ),

        // Verde 1
        Region(
          id: 'verde_1',
          tipo: TipoVerde(const {1: 6, 2: 5, 3: 4}),
          coordenadas: {
            const Coordenada(4, 0),
            const Coordenada(4, 6), // Estrella
            const Coordenada(5, 0),
            const Coordenada(5, 1),
            const Coordenada(5, 2),
            const Coordenada(5, 3),
            const Coordenada(5, 4),
            const Coordenada(5, 5),
            const Coordenada(5, 6),
          },
        ),

        // Gris 1
        Region(
          id: 'gris_1',
          tipo: TipoGris(const {1: 8, 2: 6, 3: 4}),
          coordenadas: {
            const Coordenada(0, 3),
            const Coordenada(1, 0),
            const Coordenada(1, 6),
            const Coordenada(3, 3), // Estrella
            const Coordenada(6, 3),
          },
        ),
      ];

  @override
  List<Coordenada> get casillasIniciales => const [
        Coordenada(1, 2),
        Coordenada(1, 5),
        Coordenada(3, 3),
        Coordenada(4, 1),
        Coordenada(4, 6),
        Coordenada(6, 2),
      ];
}
