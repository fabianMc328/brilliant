import 'package:flutter/material.dart';
import '../region.dart';
import '../tipo.dart';
import 'nivel_definicion.dart';

// Nivel 4: el más difícil, con zonas naranjas de rangos 1-3 y 4-6.
class Nivel4Definicion extends NivelDefinicion {
  @override
  int get numero => 4;

  @override
  String get id => 'nivel_4';

  @override
  String get nombre => 'Nivel 4';

  @override
  String get dificultad => 'Experto';

  @override
  Color get colorTema => const Color(0xFFE0F2FE);

  @override
  String get descripcion =>
      'Nivel experto con filas Naranjas restringidas a rangos numéricos [1-3] y [4-6] y alta densidad.';

  @override
  List<Region> get regiones => [
        // Naranja 4-6
        Region(
          id: 'naranja_4_6',
          tipo: TipoNaranja4a6(const {1: 6, 2: 4, 3: 3}),
          coordenadas: {
            const Coordenada(0, 0),
            const Coordenada(0, 1),
            const Coordenada(0, 2),
            const Coordenada(0, 3),
            const Coordenada(0, 4), // Estrella
            const Coordenada(0, 5),
            const Coordenada(0, 6),
          },
        ),

        // Naranja 1-3
        Region(
          id: 'naranja_1_3',
          tipo: TipoNaranja1a3(const {1: 6, 2: 4, 3: 3}),
          coordenadas: {
            const Coordenada(6, 0),
            const Coordenada(6, 1), // Estrella
            const Coordenada(6, 2),
            const Coordenada(6, 3),
            const Coordenada(6, 4),
            const Coordenada(6, 5),
            const Coordenada(6, 6),
          },
        ),

        // Amarillo 1
        Region(
          id: 'amarillo_1',
          tipo: TipoAmarillo(const {1: 8, 2: 6, 3: 4}),
          coordenadas: {
            const Coordenada(1, 0),
            const Coordenada(2, 0),
            const Coordenada(3, 0), // Estrella
            const Coordenada(4, 0),
            const Coordenada(5, 0),
          },
        ),

        // Amarillo 2
        Region(
          id: 'amarillo_2',
          tipo: TipoAmarillo(const {1: 8, 2: 6, 3: 4}),
          coordenadas: {
            const Coordenada(1, 6),
            const Coordenada(2, 6),
            const Coordenada(3, 6),
            const Coordenada(4, 6),
            const Coordenada(5, 6),
          },
        ),

        // Rojo 1
        Region(
          id: 'rojo_1',
          tipo: TipoRojo(const {1: 6, 2: 4, 3: 2}),
          coordenadas: {
            const Coordenada(1, 1),
            const Coordenada(2, 1),
            const Coordenada(4, 1),
            const Coordenada(5, 1),
          },
        ),

        // Rojo 2
        Region(
          id: 'rojo_2',
          tipo: TipoRojo(const {1: 6, 2: 4, 3: 2}),
          coordenadas: {
            const Coordenada(1, 5),
            const Coordenada(2, 5), // Estrella
            const Coordenada(4, 5),
            const Coordenada(5, 5),
          },
        ),

        // Verde 1
        Region(
          id: 'verde_1',
          tipo: TipoVerde(const {1: 3, 2: 2, 3: 1}),
          coordenadas: {
            const Coordenada(1, 3),
            const Coordenada(3, 1),
            const Coordenada(3, 5),
            const Coordenada(5, 3),
          },
        ),

        // Morado 1
        Region(
          id: 'morado_1',
          tipo: TipoMorado(const {1: 7, 2: 5, 3: 3}),
          coordenadas: {
            const Coordenada(2, 2), // Estrella
            const Coordenada(2, 3),
            const Coordenada(2, 4),
            const Coordenada(3, 3),
            const Coordenada(4, 2),
            const Coordenada(4, 3),
            const Coordenada(4, 4),
          },
        ),

        // Azul 1
        Region(
          id: 'azul_1',
          tipo: TipoAzul(const {1: 8, 2: 6, 3: 4}),
          coordenadas: {
            const Coordenada(1, 2),
            const Coordenada(1, 4),
            const Coordenada(3, 2),
            const Coordenada(3, 4),
            const Coordenada(5, 2),
            const Coordenada(5, 4), // Estrella
          },
        ),
      ];

  @override
  List<Coordenada> get casillasIniciales => const [
        Coordenada(0, 4),
        Coordenada(2, 2),
        Coordenada(2, 5),
        Coordenada(3, 0),
        Coordenada(5, 4),
        Coordenada(6, 1),
      ];
}
