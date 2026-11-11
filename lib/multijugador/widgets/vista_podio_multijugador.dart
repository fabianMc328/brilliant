import 'package:flutter/material.dart';
import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';

/// Pantalla de cierre de partida multijugador con clasificación de hasta 6 jugadores.
class VistaPodioMultijugador extends StatelessWidget {
  final EstadoSalaMultijugador sala;
  final VoidCallback onVolverMenu;

  const VistaPodioMultijugador({
    super.key,
    required this.sala,
    required this.onVolverMenu,
  });

  String _descripcionMotivo(MotivoFinPartida? motivo) {
    switch (motivo) {
      case MotivoFinPartida.metaPuntosAlcanzada:
        return 'Se alcanzó la meta oficial de ${sala.metaPuntos} puntos.';
      case MotivoFinPartida.concesionRival:
        return 'Victoria por concesión de los demás jugadores.';
      case MotivoFinPartida.abandonoRival:
        return 'Victoria por desconexión definitiva de los rivales.';
      case MotivoFinPartida.sinJugadasRestantes:
        return 'Fin por tableros completos o límite de rondas sin jugadas.';
      case null:
        return 'Partida concluida.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ranking = sala.clasificacionOrdenada;
    final yoGane = sala.ganadoresIds.contains(sala.miJugadorId);
    final nombresGanadores = sala.jugadores
        .where((j) => sala.ganadoresIds.contains(j.id))
        .map((j) => j.apodo)
        .join(' y ');

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              key: const Key('vista_podio_multijugador'),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    yoGane ? Icons.emoji_events_rounded : Icons.leaderboard_rounded,
                    size: 54,
                    color: yoGane ? Colors.amber.shade600 : Colors.blue.shade700,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    yoGane ? '¡Victoria Brillante!' : 'Partida Finalizada',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (nombresGanadores.isNotEmpty)
                    Text(
                      'Ganador(es): $nombresGanadores',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF047857),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _descripcionMotivo(sala.motivoFin),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(ranking.length, (index) {
                    final j = ranking[index];
                    final esGanador = sala.ganadoresIds.contains(j.id);
                    final esYo = j.id == sala.miJugadorId;
                    String estadoExtra = '';
                    if (j.participacion == EstadoParticipacion.concedido) {
                      estadoExtra = ' • Concedió';
                    } else if (j.participacion == EstadoParticipacion.abandonado) {
                      estadoExtra = ' • Desconectado';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: esGanador
                            ? Colors.amber.shade50
                            : (esYo ? Colors.blue.shade50 : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: esGanador
                              ? Colors.amber.shade400
                              : (esYo
                                  ? Colors.blue.shade300
                                  : Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: esGanador
                                ? Colors.amber.shade600
                                : Colors.blueGrey.shade200,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: esGanador ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${j.apodo}${esYo ? ' (Tú)' : ''}$estadoExtra',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${j.puntuacion} pts',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('boton_volver_menu_multijugador'),
                      onPressed: onVolverMenu,
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Volver al Menú'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
