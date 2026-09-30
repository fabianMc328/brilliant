import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'casilla_juego.dart';
import 'tipo.dart';
import 'region.dart';
import 'juego_bloc.dart';
import 'juego_evento.dart';
import 'juego_estado.dart';

class PantallaJuego extends StatefulWidget {
  const PantallaJuego({super.key});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  late List<List<Color>> coloresTablero;
  
  // Coordenadas (fila, columna) de las 6 estrellas iniciales
  final List<Coordenada> casillasIniciales = [
    const Coordenada(1, 2), // Azul
    const Coordenada(1, 5), // Morado
    const Coordenada(3, 1), // Rojo
    const Coordenada(3, 4), // Verde
    const Coordenada(5, 2), // Morado
    const Coordenada(6, 4), // Rojo
  ];

  @override
  void initState() {
    super.initState();
    final colorAmarillo = TipoAmarillo().color;
    final colorVerde = TipoVerde().color;
    final colorAzul = TipoAzul().color;
    final colorMorado = TipoMorado().color;
    final colorRojo = TipoRojo().color;

    // Mapa de colores basado en el Nivel 1 del juego físico
    coloresTablero = [
      [colorAmarillo, colorVerde, colorAzul, colorMorado, colorMorado, colorMorado, colorAmarillo],
      [colorVerde, colorVerde, colorAzul, colorAzul, colorMorado, colorMorado, colorVerde],
      [colorVerde, colorRojo, colorRojo, colorAzul, colorMorado, colorVerde, colorVerde],
      [colorVerde, colorRojo, colorMorado, colorAmarillo, colorVerde, colorVerde, colorVerde],
      [colorVerde, colorRojo, colorMorado, colorMorado, colorRojo, colorRojo, colorAzul],
      [colorRojo, colorRojo, colorMorado, colorRojo, colorRojo, colorAzul, colorAzul],
      [colorAmarillo, colorMorado, colorMorado, colorRojo, colorRojo, colorAzul, colorAmarillo],
    ];

    // Iniciamos la configuración enviando las coordenadas al Bloc
    context.read<JuegoBloc>().add(IniciarConfiguracionInicial(casillasIniciales));
  }

  void _alTocarCasilla(BuildContext context, Coordenada coord, JuegoEsperandoValoresIniciales estado) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona un número',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(6, (index) {
                  final numero = index + 1;
                  // Verificamos si este número está actualmente en esta casilla específica
                  final seleccionado = estado.valoresColocados[coord] == numero;
                  
                  return InkWell(
                    onTap: () {
                      context.read<JuegoBloc>().add(ColocarValorInicial(coord, numero));
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: seleccionado ? Colors.blue.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: seleccionado ? Colors.blue.shade600 : Colors.blue.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$numero',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarMensajeNoHabilitada(BuildContext context, Offset position) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        // Calcular posicion evitando que se salga de la pantalla
        final screenWidth = MediaQuery.of(context).size.width;
        double leftPos = position.dx - 100;
        if (leftPos < 10) leftPos = 10;
        if (leftPos + 200 > screenWidth - 10) leftPos = screenWidth - 210;

        return Positioned(
          top: position.dy - 50,
          left: leftPos,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Favor leer las instrucciones, esta casilla no está habilitada aún.',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JuegoBloc, JuegoEstado>(
      listener: (context, state) {
        if (state is JuegoError) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                  const SizedBox(width: 12),
                  const Text('¡Aviso!', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                state.mensaje,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Entendido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else if (state is JuegoEnProgreso) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  const Text('¡Excelente!', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                '¡Tablero listo! Fase 1 completada con éxito.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('¡A jugar!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        // Encontrar el estado que contiene nuestros valores colocados
        JuegoEsperandoValoresIniciales? estadoInicial;
        if (state is JuegoEsperandoValoresIniciales) {
          estadoInicial = state;
        } else if (state is JuegoError && state.estadoAnterior is JuegoEsperandoValoresIniciales) {
          estadoInicial = state.estadoAnterior as JuegoEsperandoValoresIniciales;
        }

        final Map<Coordenada, int> valoresActuales;
        if (state is JuegoEnProgreso) {
          valoresActuales = state.valoresColocados;
        } else {
          valoresActuales = estadoInicial?.valoresColocados ?? {};
        }
        
        final bool listoParaAvanzar = estadoInicial?.listosParaAvanzar ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Brilliant - Nivel 1'),
            centerTitle: true,
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state is! JuegoEnProgreso)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Fase 1 (Fase Inicial): Coloca los números iniciales con los que empezarás a jugar. Toca las estrellas para asignar los números del 1 al 6 sin repetirlos.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0), // Aumentado para que no sea tan grande
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 6.0,
                          mainAxisSpacing: 6.0,
                        ),
                        itemCount: 49,
                    itemBuilder: (context, index) {
                      final fila = index ~/ 7;
                      final columna = index % 7;
                      final coord = Coordenada(fila, columna);
                      final esInicial = casillasIniciales.contains(coord);
                      final valor = valoresActuales[coord];

                      // Dibujar una estrella si es casilla inicial y no tiene valor aún
                      Widget? contenido;
                      if (esInicial && valor == null) {
                        contenido = const Icon(
                          Icons.star_rounded, 
                          color: Colors.white70, 
                          size: 28
                        );
                      }

                      return GestureDetector(
                        onTapDown: (details) {
                          if (esInicial && estadoInicial != null) {
                            _alTocarCasilla(context, coord, estadoInicial!);
                          } else if (!esInicial && state is! JuegoEnProgreso) {
                            _mostrarMensajeNoHabilitada(context, details.globalPosition);
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: double.infinity,
                              child: CasillaJuego(
                                colorBase: coloresTablero[fila][columna],
                                estado: valor != null 
                                    ? EstadoCasilla.usado 
                                    : EstadoCasilla.sinUsar,
                                valor: valor,
                              ),
                            ),
                            if (contenido != null) contenido,
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              ), // Close Center
              ), // Close Expanded
              const SizedBox(height: 20),
              // Botones de acción
              if (state is JuegoEsperandoValoresIniciales || (state is JuegoError && state.estadoAnterior is JuegoEsperandoValoresIniciales))
                Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: valoresActuales.isNotEmpty 
                              ? () => context.read<JuegoBloc>().add(LimpiarValoresIniciales())
                              : null,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Limpiar'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            backgroundColor: Colors.red.shade50,
                            elevation: 0,
                            side: BorderSide(color: Colors.red.shade200, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.read<JuegoBloc>().add(LlenarValoresAleatorios()),
                          icon: const Icon(Icons.casino),
                          label: const Text('Qué flojera, acomódalos tú'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.deepPurple.shade700,
                            backgroundColor: Colors.deepPurple.shade50,
                            elevation: 0,
                            side: BorderSide(color: Colors.deepPurple.shade200, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: listoParaAvanzar 
                          ? () => context.read<JuegoBloc>().add(AvanzarJuego()) 
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Comenzar Nivel'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
