import 'package:flutter/material.dart';
import '../juego_estado.dart';
import '../widget_dado.dart';

// Panel inferior con los dos dados y los botones de tirar o pasar.
class PanelDados extends StatelessWidget {
  final JuegoEnProgreso state;
  final VoidCallback onTirarDados;
  final VoidCallback onCancelarAncla;
  final VoidCallback onPasarTurno;
  final void Function(int indiceDado, int valor)? onSeleccionarDado;

  const PanelDados({
    super.key,
    required this.state,
    required this.onTirarDados,
    required this.onCancelarAncla,
    required this.onPasarTurno,
    this.onSeleccionarDado,
  });

  @override
  Widget build(BuildContext context) {
    final bool dado1EsNumeroAColocar = state.indiceDadoSeleccionado == 1 ||
        (state.anclaSeleccionada != null && state.numeroAColocar == state.dado1);
    final bool dado2EsNumeroAColocar = state.indiceDadoSeleccionado == 2 ||
        (state.anclaSeleccionada != null && state.numeroAColocar == state.dado2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: state.debeTirarDados
              ? Border.all(color: Colors.amber.shade400, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: state.debeTirarDados
                  ? Colors.amber.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sección de Dados (Tocar dado para seleccionarlo)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WidgetDado(
                      key: const Key('dado_1'),
                      valor: state.dado1,
                      seleccionado: state.indiceDadoSeleccionado == 1,
                      esNumeroAColocar: dado1EsNumeroAColocar,
                      tamano: 48,
                      onTap: onSeleccionarDado != null
                          ? () => onSeleccionarDado!(1, state.dado1)
                          : null,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dado1EsNumeroAColocar ? 'A colocar' : 'Dado 1',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: dado1EsNumeroAColocar
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WidgetDado(
                      key: const Key('dado_2'),
                      valor: state.dado2,
                      seleccionado: state.indiceDadoSeleccionado == 2,
                      esNumeroAColocar: dado2EsNumeroAColocar,
                      tamano: 48,
                      onTap: onSeleccionarDado != null
                          ? () => onSeleccionarDado!(2, state.dado2)
                          : null,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dado2EsNumeroAColocar ? 'A colocar' : 'Dado 2',
                      style: TextStyle(
                        fontSize: 10.5,
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
            const SizedBox(width: 8),

            // Sección de Botones de Acción adaptativa
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.anclaSeleccionada != null ||
                        state.indiceDadoSeleccionado != null) ...[
                      TextButton.icon(
                        key: const Key('boton_cancelar_ancla'),
                        onPressed: onCancelarAncla,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cancelar selección'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (state.debeTirarDados)
                      ElevatedButton.icon(
                        key: const Key('boton_tirar_dados'),
                        onPressed: onTirarDados,
                        icon: const Icon(Icons.casino, size: 20),
                        label: const Text('Tirar Dados Obligatorio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      )
                    else if (!state.hayJugadasDisponibles)
                      ElevatedButton.icon(
                        key: const Key('boton_pasar_turno'),
                        onPressed: onPasarTurno,
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text('Pasar Turno'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        key: const Key('boton_tirar_dados'),
                        onPressed: onTirarDados,
                        icon: const Icon(Icons.casino, size: 18),
                        label: const Text('Tirar Dados'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
