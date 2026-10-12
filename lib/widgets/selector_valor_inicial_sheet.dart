import 'package:flutter/material.dart';

/// Modal desacoplado (SRP) para seleccionar un número del 1 al 6 en la Fase Inicial.
class SelectorValorInicialSheet extends StatelessWidget {
  final int? valorActual;
  final ValueChanged<int> onNumeroSeleccionado;

  const SelectorValorInicialSheet({
    super.key,
    required this.valorActual,
    required this.onNumeroSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona un número',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(6, (index) {
              final numero = index + 1;
              final seleccionado = valorActual == numero;

              return InkWell(
                onTap: () {
                  onNumeroSeleccionado(numero);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: seleccionado ? Colors.blue.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: seleccionado ? Colors.blue.shade600 : Colors.blue.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$numero',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
