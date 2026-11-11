import 'package:flutter/material.dart';
import '../../tablero.dart';
import '../dominio/estado_sala_multijugador.dart';

/// Muestra en una tira horizontal compacta los bonos disponibles de cada región en la carrera.
class PanelCarreraRegiones extends StatelessWidget {
  final EstadoSalaMultijugador sala;
  final Tablero tableroLocal;

  const PanelCarreraRegiones({
    super.key,
    required this.sala,
    required this.tableroLocal,
  });

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
            final disponibles = carrera != null
                ? carrera.puntosDisponibles(region.tipo.puntuaciones)
                : (region.tipo.puntuaciones[1] ?? 0);

            final etiqueta = yoComplete
                ? '${region.id.replaceAll('_', ' ')}: +${misPuntos ?? disponibles} ✓'
                : '${region.id.replaceAll('_', ' ')}: +$disponibles';

            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: region.tipo.color
                      .withValues(alpha: yoComplete ? 0.30 : 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: region.tipo.color,
                    width: yoComplete ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: region.tipo.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      etiqueta,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.blueGrey.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
