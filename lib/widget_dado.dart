import 'package:flutter/material.dart';

/// Widget visual para renderizar un dado con puntos (estilo clásico) o número.
class WidgetDado extends StatelessWidget {
  final int valor;
  final bool seleccionado;
  final bool esNumeroAColocar;
  final VoidCallback? onTap;
  final double tamano;

  const WidgetDado({
    super.key,
    required this.valor,
    this.seleccionado = false,
    this.esNumeroAColocar = false,
    this.onTap,
    this.tamano = 62.0,
  }) : assert(valor >= 1 && valor <= 6, 'El valor del dado debe ser entre 1 y 6');

  Widget _construirPuntos() {
    // Patrón clásico de puntos de dados (1 al 6)
    final punto = Container(
      width: tamano * 0.16,
      height: tamano * 0.16,
      decoration: BoxDecoration(
        color: esNumeroAColocar ? Colors.blue.shade900 : Colors.black87,
        shape: BoxShape.circle,
      ),
    );

    // Matriz para colocar los puntos del dado
    switch (valor) {
      case 1:
        return Center(child: punto);
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [punto]),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [punto]),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [punto]),
            Center(child: punto),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [punto]),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [punto, punto]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [punto, punto]),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [punto, punto]),
            Center(child: punto),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [punto, punto]),
          ],
        );
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [punto, punto]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [punto, punto]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [punto, punto]),
          ],
        );
      default:
        return Center(
          child: Text(
            '$valor',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: tamano,
        height: tamano,
        padding: EdgeInsets.all(tamano * 0.18),
        decoration: BoxDecoration(
          color: esNumeroAColocar ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esNumeroAColocar
                ? Colors.blue.shade600
                : (seleccionado ? Colors.amber.shade700 : Colors.grey.shade300),
            width: esNumeroAColocar || seleccionado ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: esNumeroAColocar
                  ? Colors.blue.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.12),
              blurRadius: esNumeroAColocar ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _construirPuntos(),
      ),
    );
  }
}
