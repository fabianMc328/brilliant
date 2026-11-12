import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../casilla_juego.dart';
import '../../region.dart';
import '../../widget_dado.dart';
import '../../widgets/dialogo_como_jugar.dart';
import '../../widgets/selector_valor_inicial_sheet.dart';
import '../bloc/partida_multijugador_bloc.dart';
import '../bloc/partida_multijugador_estado.dart';
import '../bloc/partida_multijugador_evento.dart';
import '../dominio/estados_jugador_sala.dart';
import '../widgets/banner_conexion_red.dart';
import '../widgets/barra_marcador_jugadores.dart';
import '../widgets/dialogo_chat_multijugador.dart';
import '../widgets/dialogo_conceder_partida.dart';
import '../widgets/panel_carrera_regiones.dart';
import '../widgets/vista_podio_multijugador.dart';

/// Pantalla de juego multijugador sincronizado (2 a 6 jugadores).
class PantallaPartidaMultijugador extends StatefulWidget {
  final Future<void> Function()? alCerrarRepositorio;

  const PantallaPartidaMultijugador({
    super.key,
    this.alCerrarRepositorio,
  });

  @override
  State<PantallaPartidaMultijugador> createState() =>
      _PantallaPartidaMultijugadorState();
}

class _PantallaPartidaMultijugadorState
    extends State<PantallaPartidaMultijugador> {
  @override
  void dispose() {
    widget.alCerrarRepositorio?.call();
    super.dispose();
  }

  Future<void> _intentarConceder(BuildContext context) async {
    final confirmar = await mostrarDialogoConcederPartida(context);
    if (confirmar && context.mounted) {
      context
          .read<PartidaMultijugadorBloc>()
          .add(const SolicitarConcederPartida());
    }
  }

  void _abrirSelectorEstrella(
    BuildContext context,
    Coordenada coord,
    PartidaMultijugadorActiva estado,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SelectorValorInicialSheet(
        valorActual: estado.estrellasBorrador[coord],
        onNumeroSeleccionado: (numSeleccionado) {
          context
              .read<PartidaMultijugadorBloc>()
              .add(ColocarEstrellaLocal(coord, numSeleccionado));
        },
      ),
    );
  }

  void _abrirChat(BuildContext context) {
    DialogoChatMultijugador.mostrarParaPartida(
      context: context,
      partidaBloc: context.read<PartidaMultijugadorBloc>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PartidaMultijugadorBloc, PartidaMultijugadorEstado>(
      listener: (context, state) {
        if (state is PartidaMultijugadorCerrada) {
          Navigator.of(context).maybePop();
        }
      },
      builder: (context, state) {
        if (state is! PartidaMultijugadorActiva) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final sala = state.sala;
        final enCursoActivo =
            sala.fase != FaseSala.finalizada && !sala.yaConcedi;

        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Sala ${sala.codigoSala} • ${state.nivel.nombre}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: (sala.fase == FaseSala.finalizada || sala.yaConcedi)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Salir al menú',
                    onPressed: () => context
                        .read<PartidaMultijugadorBloc>()
                        .add(const AbandonarSalaMultijugador()),
                  )
                : null,
            actions: [
              IconButton(
                key: const Key('boton_como_jugar_partida_multi'),
                tooltip: '¿Cómo jugar?',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => DialogoComoJugar.mostrar(context),
              ),
              IconButton(
                key: const Key('boton_abrir_chat_partida'),
                tooltip: 'Chat de la Sala',
                icon: Badge(
                  isLabelVisible: state.historialChat.isNotEmpty,
                  label: Text('${state.historialChat.length}'),
                  child: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                onPressed: () => _abrirChat(context),
              ),
              if (enCursoActivo)
                IconButton(
                  key: const Key('boton_conceder_partida'),
                  tooltip: 'Conceder partida',
                  onPressed: () => _intentarConceder(context),
                  icon: Icon(Icons.flag_rounded,
                      size: 20, color: Colors.red.shade700),
                ),
            ],
          ),
          body: sala.fase == FaseSala.finalizada
              ? VistaPodioMultijugador(
                  sala: sala,
                  onVolverMenu: () => context
                      .read<PartidaMultijugadorBloc>()
                      .add(const AbandonarSalaMultijugador()),
                )
              : (sala.fase == FaseSala.configurandoIniciales
                  ? _construirFaseEstrellas(context, state)
                  : _construirFaseRondas(context, state)),
        );
      },
    );
  }

  Widget _construirFaseEstrellas(
    BuildContext context,
    PartidaMultijugadorActiva state,
  ) {
    final sala = state.sala;
    final confirmados =
        sala.jugadores.where((j) => j.confirmoAccionActual).length;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final esCompacta = constraints.maxHeight < 620;

          final columna = Column(
            children: [
              BannerConexionRed(
                conexion: state.conexion,
                avisoTemporal: state.mensajeAviso ?? sala.mensajeEventoReciente,
                onReintentar: () => context
                    .read<PartidaMultijugadorBloc>()
                    .add(const ReintentarReconexionPartida()),
                onSalirMenu: () => context
                    .read<PartidaMultijugadorBloc>()
                    .add(const AbandonarSalaMultijugador()),
              ),
              BarraMarcadorJugadores(sala: sala),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    sala.yaConfirmeEnRonda
                        ? '¡Estrellas listas! Esperando a los demás ($confirmados/${sala.jugadoresEnCompetencia.length})...'
                        : 'Coloca los números del 1 al 6 en las estrellas de ${state.nivel.nombre} y confirma.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: esCompacta ? 0 : 1,
                child: Center(
                  child: SizedBox(
                    width: esCompacta ? 265 : null,
                    height: esCompacta ? 265 : null,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 4.0),
                        child: _construirCuadriculaEstrellas(context, state),
                      ),
                    ),
                  ),
                ),
              ),
              if (sala.yaConcedi)
                _construirAvisoConcedido(context)
              else if (!sala.yaConfirmeEnRonda)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 6.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('boton_limpiar_multi'),
                            onPressed: state.estrellasBorrador.isNotEmpty
                                ? () => context
                                    .read<PartidaMultijugadorBloc>()
                                    .add(const LimpiarEstrellasLocales())
                                : null,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Limpiar'),
                          ),
                          OutlinedButton.icon(
                            key: const Key('boton_aleatorio_multi'),
                            onPressed: () => context
                                .read<PartidaMultijugadorBloc>()
                                .add(const LlenarEstrellasAleatoriasLocales()),
                            icon: const Icon(Icons.casino_outlined, size: 16),
                            label: const Text('Llenar al azar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton.icon(
                        key: const Key('boton_confirmar_estrellas_multi'),
                        onPressed: state.estrellasCompletasParaConfirmar
                            ? () => context
                                .read<PartidaMultijugadorBloc>()
                                .add(const ConfirmarEstrellasMultijugador())
                            : null,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Confirmar Estrellas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );

          return SingleChildScrollView(
            physics: esCompacta
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: columna),
            ),
          );
        },
      ),
    );
  }

  Widget _construirCuadriculaEstrellas(
    BuildContext context,
    PartidaMultijugadorActiva state,
  ) {
    final estrellas = state.nivel.casillasIniciales;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: 49,
      itemBuilder: (context, index) {
        final fila = index ~/ 7;
        final col = index % 7;
        final coord = Coordenada(fila, col);
        final celda = state.tableroLocal.celdas[coord];
        final color = celda?.region.tipo.color ?? Colors.grey;
        final esEstrella = estrellas.contains(coord);
        final valor = state.estrellasBorrador[coord];

        return GestureDetector(
          key: ValueKey('multi_casilla_${fila}_$col'),
          onTap: () {
            if (esEstrella &&
                !state.sala.yaConfirmeEnRonda &&
                !state.sala.yaConcedi) {
              _abrirSelectorEstrella(context, coord, state);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              CasillaJuego(
                colorBase: color,
                estado:
                    valor != null ? EstadoCasilla.usado : EstadoCasilla.sinUsar,
                valor: valor,
                reglaCorta: celda?.region.tipo.reglaCorta,
                tieneEstrella: esEstrella,
              ),
              if (esEstrella && valor == null)
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirFaseRondas(
    BuildContext context,
    PartidaMultijugadorActiva state,
  ) {
    final sala = state.sala;
    final d1 = sala.dado1 ?? 1;
    final d2 = sala.dado2 ?? 1;
    final dado1Colocar =
        state.anclaSeleccionada != null && state.numeroAColocar == d1;
    final dado2Colocar =
        state.anclaSeleccionada != null && state.numeroAColocar == d2;

    String instruccionRonda;
    if (sala.yaConcedi) {
      instruccionRonda =
          'Has concedido la partida. Viendo el progreso del grupo.';
    } else if (sala.yaConfirmeEnRonda) {
      final listos =
          sala.jugadoresEnCompetencia.where((j) => j.confirmoAccionActual).length;
      instruccionRonda =
          'Jugada enviada. Esperando a los demás ($listos/${sala.jugadoresEnCompetencia.length})...';
    } else if (!state.hayJugadasDisponibles) {
      instruccionRonda =
          'Sin jugadas posibles con [$d1] y [$d2]. Pulsa "Pasar Turno".';
    } else if (state.indiceDadoSeleccionado != null) {
      instruccionRonda = state.casillasValidas.isNotEmpty
          ? 'Toca una casilla verde para colocar el ${state.numeroAColocar} (vecina al ${state.indiceDadoSeleccionado == 1 ? d2 : d1}).'
          : 'No hay casillas válidas para colocar el ${state.numeroAColocar} adyacente a un ${state.indiceDadoSeleccionado == 1 ? d2 : d1}.';
    } else if (state.anclaSeleccionada != null) {
      instruccionRonda = state.casillasValidas.isNotEmpty
          ? 'Toca una casilla iluminada en verde para colocar el ${state.numeroAColocar}.'
          : 'Esa ancla no tiene vecinas legales para el ${state.numeroAColocar}. Elige otra.';
    } else {
      instruccionRonda =
          'Toca un dado [$d1 o $d2] o selecciona una casilla ancla en el tablero.';
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final esCompacta = constraints.maxHeight < 630;

          final columna = Column(
            children: [
              BannerConexionRed(
                conexion: state.conexion,
                avisoTemporal: state.mensajeAviso ?? sala.mensajeEventoReciente,
                onReintentar: () => context
                    .read<PartidaMultijugadorBloc>()
                    .add(const ReintentarReconexionPartida()),
                onSalirMenu: () => context
                    .read<PartidaMultijugadorBloc>()
                    .add(const AbandonarSalaMultijugador()),
              ),
              BarraMarcadorJugadores(sala: sala),
              PanelCarreraRegiones(
                sala: sala,
                tableroLocal: state.tableroLocal,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    instruccionRonda,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: esCompacta ? 0 : 1,
                child: Center(
                  child: SizedBox(
                    width: esCompacta ? 265 : null,
                    height: esCompacta ? 265 : null,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 3.0),
                        child: _construirCuadriculaJuego(context, state),
                      ),
                    ),
                  ),
                ),
              ),
              if (sala.yaConcedi)
                _construirAvisoConcedido(context)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 5.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WidgetDado(
                              key: const Key('multi_dado_1'),
                              valor: d1,
                              seleccionado: state.indiceDadoSeleccionado == 1,
                              esNumeroAColocar: state.indiceDadoSeleccionado == 1 || dado1Colocar,
                              tamano: 44,
                              onTap: state.puedeInteractuarConTablero
                                  ? () => context
                                      .read<PartidaMultijugadorBloc>()
                                      .add(SeleccionarDadoMultijugador(
                                          indiceDado: 1, valor: d1))
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            WidgetDado(
                              key: const Key('multi_dado_2'),
                              valor: d2,
                              seleccionado: state.indiceDadoSeleccionado == 2,
                              esNumeroAColocar: state.indiceDadoSeleccionado == 2 || dado2Colocar,
                              tamano: 44,
                              onTap: state.puedeInteractuarConTablero
                                  ? () => context
                                      .read<PartidaMultijugadorBloc>()
                                      .add(SeleccionarDadoMultijugador(
                                          indiceDado: 2, valor: d2))
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (state.anclaSeleccionada != null ||
                                    state.indiceDadoSeleccionado != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: OutlinedButton(
                                      key: const Key('boton_cancelar_ancla_multi'),
                                      onPressed: () => context
                                          .read<PartidaMultijugadorBloc>()
                                          .add(
                                              const DeseleccionarAnclaMultijugador()),
                                      child: const Text('Cancelar selección'),
                                    ),
                                  ),
                                ElevatedButton.icon(
                                  key: const Key('boton_pasar_turno_multi'),
                                  onPressed: state.puedeInteractuarConTablero
                                      ? () => context
                                          .read<PartidaMultijugadorBloc>()
                                          .add(const PasarTurnoMultijugador())
                                      : null,
                                  icon: const Icon(Icons.skip_next_rounded,
                                      size: 18),
                                  label: Text(
                                    sala.yaConfirmeEnRonda
                                        ? 'Esperando...'
                                        : 'Pasar Turno',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: state.hayJugadasDisponibles
                                        ? Colors.blueGrey.shade700
                                        : Colors.orange.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );

          return SingleChildScrollView(
            physics: esCompacta
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: columna),
            ),
          );
        },
      ),
    );
  }

  Widget _construirCuadriculaJuego(
    BuildContext context,
    PartidaMultijugadorActiva state,
  ) {
    final elegibles = state.anclasElegibles;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: 49,
      itemBuilder: (context, index) {
        final fila = index ~/ 7;
        final col = index % 7;
        final coord = Coordenada(fila, col);
        final celda = state.tableroLocal.celdas[coord];
        final color = celda?.region.tipo.color ?? Colors.grey;
        final valor = celda?.valor;

        final esAnclaSeleccionada = coord == state.anclaSeleccionada;
        final esAnclaElegible =
            elegibles.contains(coord) && state.anclaSeleccionada == null && state.indiceDadoSeleccionado == null;
        final esLugarValido = state.casillasValidas.contains(coord);
        final regionCompleta = celda != null &&
            state.tableroLocal.esRegionCompleta(celda.region);

        final estadoVisual = (celda == null || celda.estaVacia)
            ? EstadoCasilla.sinUsar
            : (regionCompleta ? EstadoCasilla.puntuado : EstadoCasilla.usado);

        return GestureDetector(
          key: ValueKey('multi_casilla_${fila}_$col'),
          onTap: () {
            if (!state.puedeInteractuarConTablero) return;
            if (esLugarValido) {
              context
                  .read<PartidaMultijugadorBloc>()
                  .add(ColocarNumeroMultijugador(coord));
            } else if (elegibles.contains(coord)) {
              if (esAnclaSeleccionada) {
                context
                    .read<PartidaMultijugadorBloc>()
                    .add(const DeseleccionarAnclaMultijugador());
              } else {
                context
                    .read<PartidaMultijugadorBloc>()
                    .add(SeleccionarAnclaMultijugador(coord));
              }
            }
          },
          child: CasillaJuego(
            colorBase: color,
            estado: estadoVisual,
            valor: valor,
            esAnclaSeleccionada: esAnclaSeleccionada,
            esAnclaElegible: esAnclaElegible,
            esLugarValido: esLugarValido,
            valorPreview: esLugarValido ? state.numeroAColocar : null,
            reglaCorta: celda?.region.tipo.reglaCorta,
            tieneEstrella: state.nivel.casillasIniciales.contains(coord),
          ),
        );
      },
    );
  }

  Widget _construirAvisoConcedido(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: ElevatedButton.icon(
        key: const Key('boton_salir_tras_conceder'),
        onPressed: () => context
            .read<PartidaMultijugadorBloc>()
            .add(const AbandonarSalaMultijugador()),
        icon: const Icon(Icons.exit_to_app_rounded),
        label: const Text('Salir al Menú Principal'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade800,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
