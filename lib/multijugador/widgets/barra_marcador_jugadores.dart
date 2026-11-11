import 'package:flutter/material.dart';
import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';
import '../dominio/jugador_multijugador.dart';

/// Marcador compacto y responsivo para visualizar de 2 a 6 jugadores en tiempo real.
class BarraMarcadorJugadores extends StatelessWidget {
  final EstadoSalaMultijugador sala;

  const BarraMarcadorJugadores({
    super.key,
    required this.sala,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
      child: Container(
        key: const Key('barra_marcador_jugadores'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blueGrey.shade100, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded,
                      size: 15, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Meta: ${sala.metaPuntos} pts',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.casino_outlined,
                      size: 14, color: Colors.blueGrey.shade600),
                  const SizedBox(width: 3),
                  Text(
                    sala.fase == FaseSala.configurandoIniciales
                        ? 'Fase Inicial'
                        : 'Ronda ${sala.rondaActual}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.timer_outlined,
                      size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 3),
                  Text(
                    '${sala.segundosRestantes}s',
                    key: const Key('texto_reloj_ronda'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: sala.segundosRestantes <= 10
                          ? Colors.red.shade700
                          : Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sala.jugadores.map((j) {
                  final esYo = j.id == sala.miJugadorId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _ChipJugadorMarcador(jugador: j, esYo: esYo),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipJugadorMarcador extends StatelessWidget {
  final ResumenJugador jugador;
  final bool esYo;

  const _ChipJugadorMarcador({
    required this.jugador,
    required this.esYo,
  });

  @override
  Widget build(BuildContext context) {
    final bool retirado =
        jugador.participacion == EstadoParticipacion.concedido ||
        jugador.participacion == EstadoParticipacion.abandonado;
    final bool reconectando =
        jugador.participacion == EstadoParticipacion.reconectando;

    Color colorBorde = esYo ? Colors.blue.shade600 : Colors.blueGrey.shade200;
    Color colorFondo = esYo ? Colors.blue.shade50 : Colors.grey.shade50;
    if (retirado) {
      colorBorde = Colors.grey.shade300;
      colorFondo = Colors.grey.shade100;
    } else if (reconectando) {
      colorBorde = Colors.amber.shade600;
      colorFondo = Colors.amber.shade50;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorBorde, width: esYo ? 1.6 : 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (retirado)
            Icon(Icons.flag_rounded, size: 12, color: Colors.red.shade400)
          else if (reconectando)
            Icon(Icons.wifi_off_rounded, size: 12, color: Colors.amber.shade800)
          else if (jugador.confirmoAccionActual)
            const Icon(Icons.check_circle, size: 12, color: Color(0xFF059669))
          else
            Icon(Icons.schedule_rounded,
                size: 12, color: Colors.blueGrey.shade400),
          const SizedBox(width: 4),
          Text(
            esYo ? '${jugador.apodo} (Tú)' : jugador.apodo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: esYo ? FontWeight.w800 : FontWeight.w600,
              decoration: retirado ? TextDecoration.lineThrough : null,
              color: retirado ? Colors.grey.shade600 : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${jugador.puntuacion}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
