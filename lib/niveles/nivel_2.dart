import 'package:flutter/material.dart';
import '../region.dart';
import '../tipo.dart';
import 'nivel_definicion.dart';

// Nivel 2: mete casillas grises que piden números iguales.
class Nivel2Definicion extends NivelDefinicion {
  @override
  int get numero => 2;

  @override
  String get id => 'nivel_2';

  @override
  String get nombre => 'Nivel 2';

  @override
  String get dificultad => 'Intermedio';

  @override
  Color get colorTema => const Color(0xFFFFF9C4);

  @override
  String get descripcion =>
      'Introduce zonas Grises en los bordes y una distribución concéntrica con hélices rojas.';

  @override
  List<Region> get regiones => [
        // Morado 1
        Region(
          id: 'morado_1',
          tipo: TipoMorado(const {1: 6, 2: 4, 3: 2}),
          coordenadas: {
            const Coordenada(0, 0),
            const Coordenada(0, 1),
            const Coordenada(0, 2),
            const Coordenada(1, 0),
            const Coordenada(2, 0), // Estrella
          },
        ),

        // Morado 2
        Region(
          id: 'morado_2',
          tipo: TipoMorado(const {1: 6, 2: 4, 3: 2}),
          coordenadas: {
            const Coordenada(4, 6),
            const Coordenada(5, 6),
            const Coordenada(6, 4), // Estrella
            const Coordenada(6, 5),
            const Coordenada(6, 6),
          },
        ),

        // Verde 1
        Region(
          id: 'verde_1',
          tipo: TipoVerde(const {1: 4, 2: 3, 3: 2}),
          coordenadas: {
            const Coordenada(0, 4), // Estrella
            const Coordenada(0, 5),
            const Coordenada(0, 6),
            const Coordenada(1, 6),
            const Coordenada(2, 6),
          },
        ),

        // Verde 2
        Region(
          id: 'verde_2',
          tipo: TipoVerde(const {1: 4, 2: 3, 3: 2}),
          coordenadas: {
            const Coordenada(4, 0),
            const Coordenada(5, 0),
            const Coordenada(6, 0),
            const Coordenada(6, 1),
            const Coordenada(6, 2),
          },
        ),

        // Amarillo 1
        Region(
          id: 'amarillo_1',
          tipo: TipoAmarillo(const {1: 6, 2: 4, 3: 2}),
          coordenadas: {
            const Coordenada(1, 1),
            const Coordenada(1, 5),
            const Coordenada(3, 3),
            const Coordenada(5, 1), // Estrella
            const Coordenada(5, 5),
          },
        ),

        // Gris 1
        Region(
          id: 'gris_1',
          tipo: TipoGris(const {1: 3, 2: 2, 3: 1}),
          coordenadas: {
            const Coordenada(0, 3),
            const Coordenada(6, 3),
          },
        ),

        // Azul 1
        Region(
          id: 'azul_1',
          tipo: TipoAzul(const {1: 7, 2: 5, 3: 3}),
          coordenadas: {
            const Coordenada(1, 2),
            const Coordenada(1, 3),
            const Coordenada(1, 4),
            const Coordenada(2, 3),
          },
        ),

        // Azul 2
        Region(
          id: 'azul_2',
          tipo: TipoAzul(const {1: 7, 2: 5, 3: 3}),
          coordenadas: {
            const Coordenada(4, 3),
            const Coordenada(5, 2),
            const Coordenada(5, 3),
            const Coordenada(5, 4),
          },
        ),

        // Rojo 1
        Region(
          id: 'rojo_1',
          tipo: TipoRojo(const {1: 6, 2: 4, 3: 2}),
          coordenadas: {
            const Coordenada(2, 1),
            const Coordenada(2, 2),
            const Coordenada(3, 0),
            const Coordenada(3, 1),
            const Coordenada(3, 2), // Estrella
            const Coordenada(4, 1),
            const Coordenada(4, 2),
          },
        ),

        // Rojo 2
        Region(
          id: 'rojo_2',
          tipo: TipoRojo(const {1: 6, 2: 4, 3: 2}),
          coordenadas: {
            const Coordenada(2, 4),
            const Coordenada(2, 5),
            const Coordenada(3, 4),
            const Coordenada(3, 5),
            const Coordenada(3, 6),
            const Coordenada(4, 4),
            const Coordenada(4, 5), // Estrella
          },
        ),
      ];

  @override
  List<Coordenada> get casillasIniciales => const [
        Coordenada(0, 4),
        Coordenada(2, 0),
        Coordenada(3, 2),
        Coordenada(4, 5),
        Coordenada(5, 1),
        Coordenada(6, 4),
      ];
}
