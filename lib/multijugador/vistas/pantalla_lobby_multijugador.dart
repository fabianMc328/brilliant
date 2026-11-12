import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/dialogo_como_jugar.dart';
import '../bloc/lobby_bloc.dart';
import '../bloc/lobby_estado.dart';
import '../bloc/lobby_evento.dart';
import '../bloc/partida_multijugador_bloc.dart';
import '../dominio/repositorio_multijugador.dart';
import '../infraestructura/cliente_websocket_multijugador.dart';
import '../widgets/dialogo_chat_multijugador.dart';
import 'pantalla_partida_multijugador.dart';
import 'vista_acceso_sala.dart';
import 'vista_sala_espera.dart';

/// Coordina el acceso por código, el Lobby de 2-6 jugadores y la transición a la partida.
class PantallaLobbyMultijugador extends StatefulWidget {
  final RepositorioMultijugador? repositorioExterno;
  final String? apodoInicial;

  const PantallaLobbyMultijugador({
    super.key,
    this.repositorioExterno,
    this.apodoInicial,
  });

  @override
  State<PantallaLobbyMultijugador> createState() =>
      _PantallaLobbyMultijugadorState();
}

class _PantallaLobbyMultijugadorState extends State<PantallaLobbyMultijugador> {
  late final RepositorioMultijugador _repositorio;
  late final bool _esRepositorioPropio;
  late final LobbyBloc _lobbyBloc;
  bool _transferidoAPartida = false;

  @override
  void initState() {
    super.initState();
    _esRepositorioPropio = widget.repositorioExterno == null;
    _repositorio = widget.repositorioExterno ?? ClienteWebsocketMultijugador();
    _lobbyBloc = LobbyBloc(repositorio: _repositorio);
  }

  @override
  void dispose() {
    _lobbyBloc.close();
    if (!_transferidoAPartida && _esRepositorioPropio) {
      _repositorio.cerrar();
    }
    super.dispose();
  }

  void _abrirChat(BuildContext context) {
    DialogoChatMultijugador.mostrarParaLobby(
      context: context,
      lobbyBloc: _lobbyBloc,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _lobbyBloc,
      child: BlocConsumer<LobbyBloc, LobbyEstado>(
        listener: (context, state) {
          if (state is LobbyTransicionAPartida && !_transferidoAPartida) {
            _transferidoAPartida = true;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => PartidaMultijugadorBloc(
                    repositorio: _repositorio,
                    salaInicial: state.salaInicial,
                  ),
                  child: PantallaPartidaMultijugador(
                    alCerrarRepositorio: () async {
                      if (_esRepositorioPropio) {
                        await _repositorio.cerrar();
                      }
                    },
                  ),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final enSala = state is LobbyEnSalaEspera;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                enSala ? 'Sala ${state.sala.codigoSala}' : 'Multijugador',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              centerTitle: true,
              leading: IconButton(
                key: const Key('boton_salir_lobby'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (enSala) {
                    context.read<LobbyBloc>().add(const SalirDelLobby());
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
              actions: [
                IconButton(
                  key: const Key('boton_como_jugar_lobby'),
                  tooltip: '¿Cómo jugar?',
                  icon: const Icon(Icons.help_outline_rounded),
                  onPressed: () => DialogoComoJugar.mostrar(context),
                ),
                if (enSala)
                  IconButton(
                    key: const Key('boton_abrir_chat_lobby'),
                    tooltip: 'Chat de la Sala',
                    icon: Badge(
                      isLabelVisible: state.historialChat.isNotEmpty,
                      label: Text('${state.historialChat.length}'),
                      child: const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    onPressed: () => _abrirChat(context),
                  ),
              ],
            ),
            body: SafeArea(
              child: _construirCuerpo(state),
            ),
          );
        },
      ),
    );
  }

  Widget _construirCuerpo(LobbyEstado state) {
    if (state is LobbyCargando) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                state.descripcion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is LobbyEnSalaEspera) {
      return VistaSalaEspera(
        sala: state.sala,
        conexion: state.conexion,
        avisoError: state.avisoError,
      );
    }

    final error = state is LobbyAccesoInicial ? state.mensajeError : null;
    return VistaAccesoSala(
      urlServidorActual: state.urlServidor,
      mensajeError: error,
      apodoInicial: widget.apodoInicial,
    );
  }
}
