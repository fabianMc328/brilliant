import 'package:flutter/material.dart';
import '../juego_estado.dart';

// Muestra la cajita con el mensaje de ayuda según el turno.
class BannerInstruccion extends StatelessWidget {
  final JuegoEnProgreso state;

  const BannerInstruccion({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    String mensaje;
    IconData icono;
    Color colorFondo;
    Color colorTexto;

    if (!state.hayJugadasDisponibles) {
      mensaje = '¡No hay jugadas posibles con estos dados! Pasa el turno o vuelve a tirar.';
      icono = Icons.info_outline;
      colorFondo = Colors.amber.shade50;
      colorTexto = Colors.amber.shade900;
    } else if (state.anclaSeleccionada != null) {
      final ancla = state.anclaSeleccionada!;
      final cantValidas = state.casillasValidas.length;
      if (cantValidas > 0) {
        mensaje = 'Ancla (${ancla.x + 1}, ${ancla.y + 1}) activa. Toca una casilla iluminada en verde para colocar el número ${state.numeroAColocar}.';
        icono = Icons.touch_app_rounded;
        colorFondo = const Color(0xFFD1FAE5);
        colorTexto = const Color(0xFF065F46);
      } else {
        mensaje = 'Esa ancla no tiene espacios legales adyacentes para colocar el ${state.numeroAColocar}. Selecciona otra ancla.';
        icono = Icons.warning_amber_rounded;
        colorFondo = Colors.orange.shade50;
        colorTexto = Colors.orange.shade900;
      }
    } else {
      mensaje = 'Dados: [${state.dado1}] y [${state.dado2}]. Toca una casilla del tablero con valor ${state.dado1} o ${state.dado2} para seleccionarla como ancla.';
      icono = Icons.tips_and_updates_outlined;
      colorFondo = Colors.blue.shade50;
      colorTexto = Colors.blue.shade900;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        key: const Key('banner_instruccion'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorTexto.withValues(alpha: 0.3), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icono, color: colorTexto, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorTexto,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
