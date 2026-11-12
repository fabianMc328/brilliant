import 'package:flutter/material.dart';
import '../../region.dart';
import '../../tablero.dart';
import '../dominio/estado_carrera_region.dart';
import '../dominio/estado_sala_multijugador.dart';

/// Muestra en una tira horizontal los 3 escalones de puntos de cada región en la carrera (1.º, 2.º, 3.º).
/// Al pulsar sobre cualquier región, se abre un modal con el detalle completo de su regla y puntuación.
class PanelCarreraRegiones extends StatelessWidget {
  final EstadoSalaMultijugador sala;
  final Tablero tableroLocal;

  const PanelCarreraRegiones({
    super.key,
    required this.sala,
    required this.tableroLocal,
  });

  void _mostrarDetalleRegion(
    BuildContext context,
    Region region,
    EstadoCarreraRegion? carrera,
    bool yoComplete,
    int? misPuntos,
  ) {
    final pts = region.tipo.puntuaciones;
    final completadas = tableroLocal.celdas.values
        .where((c) => c.region.id == region.id && !c.estaVacia)
        .length;
    final totalCeldas = region.coordenadas.length;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: region.tipo.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Región: ${region.id.replaceAll('_', ' ')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$totalCeldas casillas en el tablero • $completadas/$totalCeldas llenas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: region.tipo.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: region.tipo.color.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regla: ${region.tipo.descripcion}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Resumen: ${region.tipo.reglaCorta}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Escalones de Carrera:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TarjetaEscalonDetalle(
                  posicion: '1.º Lugar',
                  puntos: pts[1] ?? 0,
                  activo: (carrera?.escalonActual ?? 1) == 1,
                ),
                _TarjetaEscalonDetalle(
                  posicion: '2.º Lugar',
                  puntos: pts[2] ?? 0,
                  activo: (carrera?.escalonActual ?? 1) == 2,
                ),
                _TarjetaEscalonDetalle(
                  posicion: '3.º Lugar+',
                  puntos: pts[3] ?? 0,
                  activo: (carrera?.escalonActual ?? 1) >= 3,
                ),
              ],
            ),
            if (yoComplete) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '¡Ya completaste esta región! Ganaste +${misPuntos ?? 0} puntos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tableroLocal.regiones.map((region) {
            final yoComplete = tableroLocal.esRegionCompleta(region);
            final misPuntos = sala.miDesglosePuntos[region.id];
            final carrera = sala.carreraPorRegion[region.id];
            final escalonActual = carrera?.escalonActual ?? 1;

            final pts1 = region.tipo.puntuaciones[1] ?? 0;
            final pts2 = region.tipo.puntuaciones[2] ?? 0;
            final pts3 = region.tipo.puntuaciones[3] ?? 0;

            final color = region.tipo.color;

            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: InkWell(
                onTap: () => _mostrarDetalleRegion(
                  context,
                  region,
                  carrera,
                  yoComplete,
                  misPuntos,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: yoComplete ? 0.30 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color,
                      width: yoComplete ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        region.id.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (yoComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${misPuntos ?? (carrera?.puntosDisponibles(region.tipo.puntuaciones) ?? pts1)} ✓',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _BadgeEscalon(
                              posicion: '1.º',
                              puntos: pts1,
                              activo: escalonActual == 1,
                              yaGanado: escalonActual > 1,
                            ),
                            const SizedBox(width: 3),
                            _BadgeEscalon(
                              posicion: '2.º',
                              puntos: pts2,
                              activo: escalonActual == 2,
                              yaGanado: escalonActual > 2,
                            ),
                            const SizedBox(width: 3),
                            _BadgeEscalon(
                              posicion: '3.º',
                              puntos: pts3,
                              activo: escalonActual >= 3,
                              yaGanado: false,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TarjetaEscalonDetalle extends StatelessWidget {
  final String posicion;
  final int puntos;
  final bool activo;

  const _TarjetaEscalonDetalle({
    required this.posicion,
    required this.puntos,
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFF1E293B) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            posicion,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: activo ? Colors.white70 : Colors.blueGrey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '+$puntos pts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: activo ? Colors.white : Colors.blueGrey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeEscalon extends StatelessWidget {
  final String posicion;
  final int puntos;
  final bool activo;
  final bool yaGanado;

  const _BadgeEscalon({
    required this.posicion,
    required this.puntos,
    required this.activo,
    required this.yaGanado,
  });

  @override
  Widget build(BuildContext context) {
    if (yaGanado) {
      return Text(
        '$puntos',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.lineThrough,
          color: Colors.blueGrey.shade300,
        ),
      );
    }

    if (activo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$puntos',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      );
    }

    return Text(
      '$puntos',
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: Colors.blueGrey.shade600,
      ),
    );
  }
}
