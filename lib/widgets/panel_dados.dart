import 'package:flutter/material.dart';
import '../juego_estado.dart';
import '../widget_dado.dart';

// Panel inferior con los dos dados y los botones de tirar o pasar.
class PanelDados extends StatelessWidget {
  final JuegoEnProgreso state;
  final VoidCallback onTirarDados;
  final VoidCallback onCancelarAncla;
  final VoidCallback onPasarTurno;

  const PanelDados({
    super.key,
    required this.state,
    required this.onTirarDados,
    required this.onCancelarAncla,
    required this.onPasarTurno,
  });

  @override
  Widget build(BuildContext context) {
    final bool dado1EsNumeroAColocar =
        state.anclaSeleccionada != null && state.numeroAColocar == state.dado1;
    final bool dado2EsNumeroAColocar =
        state.anclaSeleccionada != null && state.numeroAColocar == state.dado2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sección de Dados
            Row(
              children: [
                Column(
                  children: [
                    WidgetDado(
                      key: const Key('dado_1'),
                      valor: state.dado1,
                      esNumeroAColocar: dado1EsNumeroAColocar,
                      tamano: 54,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dado1EsNumeroAColocar ? 'A colocar' : 'Dado 1',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: dado1EsNumeroAColocar
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Column(
                  children: [
                    WidgetDado(
                      key: const Key('dado_2'),
                      valor: state.dado2,
                      esNumeroAColocar: dado2EsNumeroAColocar,
                      tamano: 54,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dado2EsNumeroAColocar ? 'A colocar' : 'Dado 2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: dado2EsNumeroAColocar
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Sección de Botones de Acción
            Row(
              children: [
                if (state.anclaSeleccionada != null)
                  TextButton.icon(
                    key: const Key('boton_cancelar_ancla'),
                    onPressed: onCancelarAncla,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancelar ancla'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                if (!state.hayJugadasDisponibles)
                  ElevatedButton.icon(
                    key: const Key('boton_pasar_turno'),
                    onPressed: onPasarTurno,
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: const Text('Pasar Turno'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    key: const Key('boton_tirar_dados'),
                    onPressed: onTirarDados,
                    icon: const Icon(Icons.casino, size: 20),
                    label: const Text('Tirar Dados'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
