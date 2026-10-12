import 'package:flutter/material.dart';
import '../juego_estado.dart';
import '../tipo.dart';

// Muestra los puntos acumulados, el turno actual y el avance por color.
class PanelPuntuacion extends StatelessWidget {
  final JuegoEnProgreso state;

  const PanelPuntuacion({
    super.key,
    required this.state,
  });

  Widget _construirChipProgreso(Color color, String label, Type tipo, Map<Type, int> completadasPorTipo, Map<Type, int> totalPorTipo) {
    final completadas = completadasPorTipo[tipo] ?? 0;
    final total = totalPorTipo[tipo] ?? 1;
    final bool completada = completadas == total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: completada ? 0.35 : 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: completada ? 2.0 : 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $completadas/$total',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final regiones = state.tablero.regiones;
    final Map<Type, int> completadasPorTipo = {};
    final Map<Type, int> totalPorTipo = {};

    for (final reg in regiones) {
      final tipo = reg.tipo.runtimeType;
      totalPorTipo[tipo] = (totalPorTipo[tipo] ?? 0) + 1;
      if (state.tablero.esRegionCompleta(reg)) {
        completadasPorTipo[tipo] = (completadasPorTipo[tipo] ?? 0) + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.blueGrey.shade100, width: 1.2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Puntuación
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.military_tech_rounded,
                        color: Colors.amber.shade800,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PUNTUACIÓN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${state.puntuacionTotal} pts',
                          key: const Key('texto_puntuacion_total'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Turno
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Turno ${state.turno}',
                        key: const Key('texto_turno'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Chips de Regiones
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _construirChipProgreso(TipoAzul().color, 'Azul', TipoAzul, completadasPorTipo, totalPorTipo),
                  const SizedBox(width: 6),
                  _construirChipProgreso(TipoMorado().color, 'Morado', TipoMorado, completadasPorTipo, totalPorTipo),
                  const SizedBox(width: 6),
                  _construirChipProgreso(TipoRojo().color, 'Rojo', TipoRojo, completadasPorTipo, totalPorTipo),
                  const SizedBox(width: 6),
                  _construirChipProgreso(TipoVerde().color, 'Verde', TipoVerde, completadasPorTipo, totalPorTipo),
                  const SizedBox(width: 6),
                  _construirChipProgreso(TipoAmarillo().color, 'Amarillo', TipoAmarillo, completadasPorTipo, totalPorTipo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
