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

    if (state.partidaTerminada) {
      mensaje =
          '¡Partida finalizada! Puntuación final: ${state.puntuacionTotal} pts.';
      icono = Icons.emoji_events_rounded;
      colorFondo = const Color(0xFFD1FAE5);
      colorTexto = const Color(0xFF065F46);
    } else if (state.debeTirarDados) {
      mensaje =
          '¡Número colocado! Pulsa obligatoriamente "Tirar Dados" para continuar.';
      icono = Icons.casino_rounded;
      colorFondo = Colors.amber.shade50;
      colorTexto = Colors.amber.shade900;
    } else if (!state.hayJugadasDisponibles) {
      mensaje =
          '¡No hay jugadas posibles con [${state.dado1}] y [${state.dado2}]! Pulsa "Pasar Turno".';
      icono = Icons.info_outline;
      colorFondo = Colors.amber.shade50;
      colorTexto = Colors.amber.shade900;
    } else if (state.indiceDadoSeleccionado != null &&
        state.anclaSeleccionada == null) {
      final cantValidas = state.casillasValidas.length;
      final otroDado =
          state.indiceDadoSeleccionado == 1 ? state.dado2 : state.dado1;
      if (cantValidas > 0) {
        mensaje =
            'Dado ${state.numeroAColocar} activo. Toca una casilla verde (junto a un $otroDado).';
        icono = Icons.touch_app_rounded;
        colorFondo = const Color(0xFFD1FAE5);
        colorTexto = const Color(0xFF065F46);
      } else {
        mensaje =
            'No hay casillas válidas para el ${state.numeroAColocar} junto a un $otroDado. Prueba el otro dado.';
        icono = Icons.warning_amber_rounded;
        colorFondo = Colors.orange.shade50;
        colorTexto = Colors.orange.shade900;
      }
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
      mensaje =
          'Dados: [${state.dado1}] y [${state.dado2}]. Toca un dado o una casilla ancla.';
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
