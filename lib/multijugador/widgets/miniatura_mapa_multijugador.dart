import 'package:flutter/material.dart';
import '../../niveles/nivel_definicion.dart';
import '../../region.dart';

/// Miniatura 7x7 de solo lectura para previsualizar el mapa compartido en el lobby.
class MiniaturaMapaMultijugador extends StatelessWidget {
  final NivelDefinicion nivel;
  final double tamano;

  const MiniaturaMapaMultijugador({
    super.key,
    required this.nivel,
    this.tamano = 56,
  });

  @override
  Widget build(BuildContext context) {
    final tablero = nivel.crearTablero();

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
          crossAxisSpacing: 1.0,
          mainAxisSpacing: 1.0,
        ),
        itemCount: 49,
        itemBuilder: (context, index) {
          final fila = index ~/ 7;
          final columna = index % 7;
          final celda = tablero.celdas[Coordenada(fila, columna)];
          final color = celda?.region.tipo.color ?? Colors.grey;
          return Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        },
      ),
    );
  }
}
