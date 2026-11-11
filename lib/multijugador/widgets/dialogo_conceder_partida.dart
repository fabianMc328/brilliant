import 'package:flutter/material.dart';

/// Muestra un diálogo de confirmación claro antes de conceder la partida.
Future<bool> mostrarDialogoConcederPartida(BuildContext context) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.flag_rounded, color: Colors.red.shade600, size: 26),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '¿Conceder partida?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: const Text(
        'Te retirarás de la competencia actual. Si quedan más jugadores activos, ellos podrán continuar la partida.',
        style: TextStyle(fontSize: 14, height: 1.35),
      ),
      actions: [
        TextButton(
          key: const Key('boton_cancelar_conceder'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Seguir jugando'),
        ),
        ElevatedButton(
          key: const Key('boton_confirmar_conceder'),
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Conceder'),
        ),
      ],
    ),
  );
  return resultado ?? false;
}
