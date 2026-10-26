import 'package:flutter/material.dart';
import '../juego_estado.dart';
import '../tipo.dart';

// Muestra puntos, turno y avance de cada color.
class PanelPuntuacion extends StatelessWidget {
  final JuegoEnProgreso state;

  const PanelPuntuacion({
    super.key,
    required this.state,
  });

  String _obtenerEtiquetaTipo(Tipo tipo) {
    if (tipo is TipoAzul) return 'Azul';
    if (tipo is TipoMorado) return 'Morado';
    if (tipo is TipoRojo) return 'Rojo';
    if (tipo is TipoVerde) return 'Verde';
    if (tipo is TipoAmarillo) return 'Amarillo';
    if (tipo is TipoGris) return 'Gris';
    if (tipo is TipoNaranja1a3) return 'Nar. 1-3';
    if (tipo is TipoNaranja4a6) return 'Nar. 4-6';
    return 'Zona';
  }

  Widget _construirChipProgreso(
    Color color,
    String label,
    Type tipo,
    Map<Type, int> completadasPorTipo,
    Map<Type, int> totalPorTipo,
  ) {
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
    final Map<Type, Tipo> tiposUnicos = {};

    for (final reg in regiones) {
      final tipoRuntime = reg.tipo.runtimeType;
      tiposUnicos.putIfAbsent(tipoRuntime, () => reg.tipo);
      totalPorTipo[tipoRuntime] = (totalPorTipo[tipoRuntime] ?? 0) + 1;
      if (state.tablero.esRegionCompleta(reg)) {
        completadasPorTipo[tipoRuntime] =
            (completadasPorTipo[tipoRuntime] ?? 0) + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                // Puntos
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.military_tech_rounded,
                            color: Colors.amber.shade800,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'PUNTUACIÓN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${state.puntuacionTotal} pts',
                              key: const Key('texto_puntuacion_total'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Turno
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_outlined,
                          size: 15, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Turno ${state.turno}',
                        key: const Key('texto_turno'),
                        style: TextStyle(
                          fontSize: 13,
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
            // Fichas de colores del nivel
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tiposUnicos.entries.map((entry) {
                  final tipoInstancia = entry.value;
                  final tipoRuntime = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _construirChipProgreso(
                      tipoInstancia.color,
                      _obtenerEtiquetaTipo(tipoInstancia),
                      tipoRuntime,
                      completadasPorTipo,
                      totalPorTipo,
                    ),
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
