import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'casilla_juego.dart';
import 'niveles/catalogo_niveles.dart';
import 'niveles/nivel_definicion.dart';
import 'region.dart';
import 'juego_bloc.dart';
import 'juego_evento.dart';
import 'juego_estado.dart';
import 'widgets/panel_puntuacion.dart';
import 'widgets/banner_instruccion.dart';
import 'widgets/panel_dados.dart';
import 'widgets/selector_valor_inicial_sheet.dart';

// Pantalla donde se juega la partida.
class PantallaJuego extends StatefulWidget {
  final NivelDefinicion? nivel;

  const PantallaJuego({super.key, this.nivel});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  late final NivelDefinicion nivelActivo;
  late final List<List<Color>> coloresTablero;
  late final List<Coordenada> casillasIniciales;

  @override
  void initState() {
    super.initState();
    nivelActivo = widget.nivel ?? CatalogoNiveles.nivel1;
    casillasIniciales = nivelActivo.casillasIniciales;

    final tableroRef = nivelActivo.crearTablero();

    coloresTablero = List.generate(7, (fila) {
      return List.generate(7, (columna) {
        final celda = tableroRef.celdas[Coordenada(fila, columna)];
        return celda?.region.tipo.color ?? Colors.grey;
      });
    });

    context
        .read<JuegoBloc>()
        .add(IniciarConfiguracionInicial(casillasIniciales, nivel: nivelActivo));
  }

  void _abrirSelectorValorInicial(
    BuildContext context,
    Coordenada coord,
    JuegoEsperandoValoresIniciales estado,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SelectorValorInicialSheet(
        valorActual: estado.valoresColocados[coord],
        onNumeroSeleccionado: (numero) {
          context.read<JuegoBloc>().add(ColocarValorInicial(coord, numero));
        },
      ),
    );
  }

  void _mostrarToast(BuildContext context, Offset position, String mensaje) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        double leftPos = position.dx - 110;
        if (leftPos < 10) leftPos = 10;
        if (leftPos + 220 > screenWidth - 10) leftPos = screenWidth - 230;

        return Positioned(
          top: (position.dy - 60).clamp(10, double.infinity),
          left: leftPos,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 220,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
              ),
              child: Text(
                mensaje,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, height: 1.2),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 1400), () {
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 32),
                  SizedBox(width: 12),
                  Text('¡Aviso!',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                state.mensaje,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Entendido',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is JuegoEnProgreso) {
          return _construirPantallaFase2(context, state);
        }
        return _construirPantallaFase1(context, state);
      },
    );
  }

  // Fase 1: poner los números en las estrellas.
  Widget _construirPantallaFase1(BuildContext context, JuegoEstado state) {
    JuegoEsperandoValoresIniciales? estadoInicial;
    if (state is JuegoEsperandoValoresIniciales) {
      estadoInicial = state;
    } else if (state is JuegoError &&
        state.estadoAnterior is JuegoEsperandoValoresIniciales) {
      estadoInicial = state.estadoAnterior as JuegoEsperandoValoresIniciales;
    }

    final valoresActuales = estadoInicial?.valoresColocados ?? {};
    final bool listoParaAvanzar = estadoInicial?.listosParaAvanzar ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Brilliant - ${nivelActivo.nombre}'),
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                key: const Key('boton_volver_seleccion'),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Elegir otro tablero',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final esPantallaBaja = constraints.maxHeight < 560;

            final contenido = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14.0, vertical: 6.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.blue.shade100, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.blue.shade700, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Fase 1 (Inicialización): Toca las estrellas para colocar los números iniciales (anclas) del 1 al 6 sin repetirlos.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: esPantallaBaja ? 0 : 1,
                  child: Center(
                    child: SizedBox(
                      width: esPantallaBaja ? 280 : null,
                      height: esPantallaBaja ? 280 : null,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 4.0,
                              mainAxisSpacing: 4.0,
                            ),
                            itemCount: 49,
                            itemBuilder: (context, index) {
                              final fila = index ~/ 7;
                              final columna = index % 7;
                              final coord = Coordenada(fila, columna);
                              final esInicial =
                                  casillasIniciales.contains(coord);
                              final valor = valoresActuales[coord];

                              Widget? iconoEstrella;
                              if (esInicial && valor == null) {
                                iconoEstrella = const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                );
                              }

                              return GestureDetector(
                                key: ValueKey('casilla_${fila}_$columna'),
                                onTapDown: (details) {
                                  if (esInicial && estadoInicial != null) {
                                    _abrirSelectorValorInicial(
                                        context, coord, estadoInicial);
                                  } else if (!esInicial) {
                                    _mostrarToast(
                                      context,
                                      details.globalPosition,
                                      'Casilla no habilitada aún. Toca una estrella.',
                                    );
                                  }
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CasillaJuego(
                                      colorBase: coloresTablero[fila][columna],
                                      estado: valor != null
                                          ? EstadoCasilla.usado
                                          : EstadoCasilla.sinUsar,
                                      valor: valor,
                                    ),
                                    if (iconoEstrella != null) iconoEstrella,
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ElevatedButton.icon(
                            key: const Key('boton_limpiar'),
                            onPressed: valoresActuales.isNotEmpty
                                ? () => context
                                    .read<JuegoBloc>()
                                    .add(LimpiarValoresIniciales())
                                : null,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Limpiar'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              backgroundColor: Colors.red.shade50,
                              elevation: 0,
                              side: BorderSide(
                                  color: Colors.red.shade200, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            key: const Key('boton_aleatorio'),
                            onPressed: () => context
                                .read<JuegoBloc>()
                                .add(LlenarValoresAleatorios()),
                            icon: const Icon(Icons.casino, size: 18),
                            label: const Text('Qué flojera, acomódalos tú'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.deepPurple.shade700,
                              backgroundColor: Colors.deepPurple.shade50,
                              elevation: 0,
                              side: BorderSide(
                                  color: Colors.deepPurple.shade200,
                                  width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        key: const Key('boton_comenzar_nivel'),
                        onPressed: listoParaAvanzar
                            ? () =>
                                context.read<JuegoBloc>().add(AvanzarJuego())
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Comenzar Nivel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            return SingleChildScrollView(
              physics: esPantallaBaja
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(child: contenido),
              ),
            );
          },
        ),
      ),
    );
  }

  // Fase 2: dados y anclas.
  Widget _construirPantallaFase2(BuildContext context, JuegoEnProgreso state) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Brilliant - ${nivelActivo.nombre}'),
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                key: const Key('boton_volver_seleccion'),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Elegir otro tablero',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Tirar dados de nuevo',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<JuegoBloc>().add(TirarDados()),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final esPantallaBaja = constraints.maxHeight < 560;

            final contenido = Column(
              children: [
                // Puntos y turno
                PanelPuntuacion(state: state),

                // Mensaje de ayuda
                BannerInstruccion(state: state),

                // Tablero 7x7
                Expanded(
                  flex: esPantallaBaja ? 0 : 1,
                  child: Center(
                    child: SizedBox(
                      width: esPantallaBaja ? 290 : null,
                      height: esPantallaBaja ? 290 : null,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 4.0,
                              mainAxisSpacing: 4.0,
                            ),
                            itemCount: 49,
                            itemBuilder: (context, index) {
                              final fila = index ~/ 7;
                              final columna = index % 7;
                              final coord = Coordenada(fila, columna);
                              final celda = state.tablero.celdas[coord];

                              final colorBase = celda?.region.tipo.color ??
                                  coloresTablero[fila][columna];
                              final valor = celda?.valor;
                              final bool esAnclaSeleccionada =
                                  coord == state.anclaSeleccionada;
                              final bool esAnclaElegible =
                                  state.anclasElegibles.contains(coord) &&
                                      state.anclaSeleccionada == null;
                              final bool esLugarValido =
                                  state.casillasValidas.contains(coord);

                              final bool regionCompleta = celda != null &&
                                  state.tablero.esRegionCompleta(celda.region);
                              final estadoCasilla =
                                  celda == null || celda.estaVacia
                                      ? EstadoCasilla.sinUsar
                                      : (regionCompleta
                                          ? EstadoCasilla.puntuado
                                          : EstadoCasilla.usado);

                              return GestureDetector(
                                key: ValueKey('casilla_${fila}_$columna'),
                                onTapDown: (details) {
                                  if (esLugarValido) {
                                    context
                                        .read<JuegoBloc>()
                                        .add(ColocarNumero(coord));
                                  } else if (state.anclasElegibles
                                      .contains(coord)) {
                                    if (esAnclaSeleccionada) {
                                      context
                                          .read<JuegoBloc>()
                                          .add(DeseleccionarAncla());
                                    } else {
                                      context
                                          .read<JuegoBloc>()
                                          .add(SeleccionarAncla(coord));
                                    }
                                  } else if (celda != null && !celda.estaVacia) {
                                    _mostrarToast(
                                      context,
                                      details.globalPosition,
                                      'Esta ancla tiene valor $valor. Los dados salieron con ${state.dado1} y ${state.dado2}.',
                                    );
                                  } else {
                                    if (state.anclaSeleccionada == null) {
                                      _mostrarToast(
                                        context,
                                        details.globalPosition,
                                        'Primero toca un ancla con valor ${state.dado1} o ${state.dado2}.',
                                      );
                                    } else {
                                      _mostrarToast(
                                        context,
                                        details.globalPosition,
                                        'Casilla no válida según las reglas de la región.',
                                      );
                                    }
                                  }
                                },
                                child: CasillaJuego(
                                  colorBase: colorBase,
                                  estado: estadoCasilla,
                                  valor: valor,
                                  esAnclaSeleccionada: esAnclaSeleccionada,
                                  esAnclaElegible: esAnclaElegible,
                                  esLugarValido: esLugarValido,
                                  valorPreview:
                                      esLugarValido ? state.numeroAColocar : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Dados y botones
                PanelDados(
                  state: state,
                  onTirarDados: () =>
                      context.read<JuegoBloc>().add(TirarDados()),
                  onCancelarAncla: () =>
                      context.read<JuegoBloc>().add(DeseleccionarAncla()),
                  onPasarTurno: () =>
                      context.read<JuegoBloc>().add(PasarTurno()),
                ),
              ],
            );

            return SingleChildScrollView(
              physics: esPantallaBaja
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(child: contenido),
              ),
            );
          },
        ),
      ),
    );
  }
}
