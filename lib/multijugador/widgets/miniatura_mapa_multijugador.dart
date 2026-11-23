import 'package:flutter/material.dart';
import '../../niveles/nivel_definicion.dart';
import '../../region.dart';
import '../../tablero.dart';

/// Miniatura 7x7 de solo lectura para previsualizar el mapa compartido o resaltar una región concreta.
class MiniaturaMapaMultijugador extends StatelessWidget {
  final NivelDefinicion nivel;
  final Tablero? tablero;
  final double tamano;
  final bool mostrarEstrellas;
  final String? regionResaltadaId;
  final Set<String>? regionesResaltadasIds;

  const MiniaturaMapaMultijugador({
    super.key,
    required this.nivel,
    this.tablero,
    this.tamano = 56,
    this.mostrarEstrellas = true,
    this.regionResaltadaId,
    this.regionesResaltadasIds,
  });

  @override
  Widget build(BuildContext context) {
    final tableroActivo = tablero ?? nivel.crearTablero();
    final estrellas = nivel.casillasIniciales.toSet();
    final tamanoEstrella = (tamano / 9.5).clamp(5.0, 14.0);

    return Container(
      width: tamano,
      height: tamano,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200, width: 1.2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 1.5,
          mainAxisSpacing: 1.5,
        ),
        itemCount: 49,
        itemBuilder: (context, index) {
          final fila = index ~/ 7;
          final columna = index % 7;
          final coord = Coordenada(fila, columna);
          final celda = tableroActivo.celdas[coord];
          final region = celda?.region;
          final colorBase = region?.tipo.color ?? Colors.grey;
          final tieneFiltro = regionResaltadaId != null ||
              (regionesResaltadasIds != null &&
                  regionesResaltadasIds!.isNotEmpty);
          final estaResaltada = !tieneFiltro ||
              region?.id == regionResaltadaId ||
              (regionesResaltadasIds?.contains(region?.id) ?? false);
          final color =
              estaResaltada ? colorBase : Colors.grey.shade300;
          final esEstrella = mostrarEstrellas && estrellas.contains(coord);

          return Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.0),
              border: tieneFiltro && estaResaltada
                  ? Border.all(color: const Color(0xFF0F172A), width: 1.1)
                  : null,
            ),
            alignment: Alignment.center,
            child: esEstrella
                ? Icon(
                    Icons.star_rounded,
                    size: tamanoEstrella,
                    color: Colors.white,
                  )
                : null,
          );
        },
      ),
    );
  }
}
