import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constantes_multijugador.dart';
import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';
import '../dominio/repositorio_multijugador.dart';
import 'lobby_estado.dart';
import 'lobby_evento.dart';

/// BLoC enfocado exclusivamente en acceso por código, lobby de 2-6 jugadores y botón Listo.
class LobbyBloc extends Bloc<LobbyEvento, LobbyEstado> {
  final RepositorioMultijugador _repositorio;
  StreamSubscription<EstadoSalaMultijugador>? _subSala;
  StreamSubscription<EstadoConexionCliente>? _subConexion;
  StreamSubscription<FalloMultijugador>? _subErrores;

  LobbyBloc({required RepositorioMultijugador repositorio})
      : _repositorio = repositorio,
        super(LobbyAccesoInicial(urlServidor: repositorio.urlServidorActual)) {
    on<CambiarUrlServidorLobby>(_onCambiarUrl);
    on<SolicitarCrearSala>(_onCrearSala);
    on<SolicitarUnirseASala>(_onUnirseASala);
    on<CambiarNivelLobby>(_onCambiarNivel);
    on<AlternarEstadoListoLobby>(_onAlternarListo);
    on<SolicitarIniciarPartidaLobby>(_onIniciarPartida);
    on<ReintentarConexionLobby>(_onReintentarConexion);
    on<LimpiarErrorLobby>(_onLimpiarError);
    on<SalirDelLobby>(_onSalirDelLobby);
    on<SalaLobbyRecibidaInterna>(_onSalaRecibida);
    on<ConexionLobbyRecibidaInterna>(_onConexionRecibida);
    on<ErrorLobbyRecibidoInterno>(_onErrorRecibido);

    _subSala = _repositorio.flujoSala.listen(
      (sala) => add(SalaLobbyRecibidaInterna(sala)),
    );
    _subConexion = _repositorio.flujoConexion.listen(
      (con) => add(ConexionLobbyRecibidaInterna(con)),
    );
    _subErrores = _repositorio.flujoErrores.listen(
      (err) => add(ErrorLobbyRecibidoInterno(err)),
    );
  }

  void _onCambiarUrl(
    CambiarUrlServidorLobby event,
    Emitter<LobbyEstado> emit,
  ) {
    _repositorio.configurarUrlServidor(event.nuevaUrl);
    if (state is LobbyAccesoInicial) {
      emit(
        (state as LobbyAccesoInicial).copiarCon(
          urlServidor: _repositorio.urlServidorActual,
          limpiarError: true,
        ),
      );
    }
  }

  Future<void> _onCrearSala(
    SolicitarCrearSala event,
    Emitter<LobbyEstado> emit,
  ) async {
    final apodo = event.apodo.trim();
    if (apodo.length < ConstantesMultijugador.minLongitudApodo ||
        apodo.length > ConstantesMultijugador.maxLongitudApodo) {
      emit(
        LobbyAccesoInicial(
          urlServidor: _repositorio.urlServidorActual,
          mensajeError: 'Ingresa un apodo válido (entre 2 y 18 caracteres).',
        ),
      );
      return;
    }

    emit(
      LobbyCargando(
        urlServidor: _repositorio.urlServidorActual,
        descripcion: 'Creando sala multijugador...',
      ),
    );

    try {
      final sala = await _repositorio.crearSala(
        apodo: apodo,
        nivelId: event.nivelId,
      );
      emit(
        LobbyEnSalaEspera(
          urlServidor: _repositorio.urlServidorActual,
          sala: sala,
          conexion: _repositorio.estadoConexionActual,
        ),
      );
    } on FalloMultijugador catch (f) {
      emit(
        LobbyAccesoInicial(
          urlServidor: _repositorio.urlServidorActual,
          mensajeError: f.mensaje,
        ),
      );
    } catch (_) {
      emit(
        LobbyAccesoInicial(
          urlServidor: _repositorio.urlServidorActual,
          mensajeError: 'No se pudo crear la sala. Revisa tu conexión.',
        ),
      );
    }
  }

  Future<void> _onUnirseASala(
    SolicitarUnirseASala event,
    Emitter<LobbyEstado> emit,
  ) async {
    final apodo = event.apodo.trim();
    final codigo = event.codigoSala.trim().toUpperCase();

    if (apodo.length < ConstantesMultijugador.minLongitudApodo ||
        apodo.length > ConstantesMultijugador.maxLongitudApodo) {
      emit(
        LobbyAccesoInicial(
          urlServidor: _repositorio.urlServidorActual,
          mensajeError: 'Ingresa un apodo válido (entre 2 y 18 caracteres).',
        ),
      );
      return;
    }

    if (codigo.length != ConstantesMultijugador.longitudCodigoSala) {
      emit(
        LobbyAccesoInicial(
          urlServidor: _repositorio.urlServidorActual,
          mensajeError: 'El código de invitación debe tener 6 caracteres.',
        ),
      );
      return;
    }

    emit(
      LobbyCargando(
        urlServidor: _repositorio.urlServidorActual,
        descripcion: 'Uniéndose a la sala $codigo...',
      ),
    );

    try {
      final sala = await _repositorio.unirseASala(
        codigoSala: codigo,
        apodo: apodo,
      );
      emit(
        LobbyEnSalaEspera(
          urlServidor: _repositorio.urlServidorActual,
          sala: sala,
          conexion: _repositorio.estadoConexionActual,
        ),
      );
    } on FalloMultijugador catch (f) {
      emit(
        LobbyAccesoInicial(
          urlServidor: _repositorio.urlServidorActual,
          mensajeError: f.mensaje,
        ),
      );
    } catch (_) {
      emit(
        LobbyAccesoInicial(
          urlServidor: _repositorio.urlServidorActual,
          mensajeError: 'No se pudo entrar a la sala $codigo.',
        ),
      );
    }
  }

  Future<void> _onCambiarNivel(
    CambiarNivelLobby event,
    Emitter<LobbyEstado> emit,
  ) async {
    try {
      await _repositorio.seleccionarNivel(event.nivelId);
    } on FalloMultijugador catch (f) {
      if (state is LobbyEnSalaEspera) {
        emit((state as LobbyEnSalaEspera).copiarCon(avisoError: f.mensaje));
      }
    }
  }

  Future<void> _onAlternarListo(
    AlternarEstadoListoLobby event,
    Emitter<LobbyEstado> emit,
  ) async {
    try {
      await _repositorio.alternarListo(event.listo);
    } on FalloMultijugador catch (f) {
      if (state is LobbyEnSalaEspera) {
        emit((state as LobbyEnSalaEspera).copiarCon(avisoError: f.mensaje));
      }
    }
  }

  Future<void> _onIniciarPartida(
    SolicitarIniciarPartidaLobby event,
    Emitter<LobbyEstado> emit,
  ) async {
    if (state is! LobbyEnSalaEspera) return;
    final actual = state as LobbyEnSalaEspera;
    if (!actual.sala.todosListosParaIniciar) {
      emit(
        actual.copiarCon(
          avisoError:
              'Se requieren de 2 a 6 jugadores y que todos pulsen "Listo".',
        ),
      );
      return;
    }

    try {
      await _repositorio.iniciarPartida();
    } on FalloMultijugador catch (f) {
      emit(actual.copiarCon(avisoError: f.mensaje));
    }
  }

  Future<void> _onReintentarConexion(
    ReintentarConexionLobby event,
    Emitter<LobbyEstado> emit,
  ) async {
    try {
      await _repositorio.reintentarReconexionManual();
    } on FalloMultijugador catch (f) {
      emit(
        LobbyAccesoInicial(
          urlServidor: _repositorio.urlServidorActual,
          mensajeError: f.mensaje,
        ),
      );
    }
  }

  void _onLimpiarError(
    LimpiarErrorLobby event,
    Emitter<LobbyEstado> emit,
  ) {
    if (state is LobbyAccesoInicial) {
      emit((state as LobbyAccesoInicial).copiarCon(limpiarError: true));
    } else if (state is LobbyEnSalaEspera) {
      emit((state as LobbyEnSalaEspera).copiarCon(limpiarAviso: true));
    }
  }

  Future<void> _onSalirDelLobby(
    SalirDelLobby event,
    Emitter<LobbyEstado> emit,
  ) async {
    await _repositorio.salirDeSala();
    emit(LobbyAccesoInicial(urlServidor: _repositorio.urlServidorActual));
  }

  void _onSalaRecibida(
    SalaLobbyRecibidaInterna event,
    Emitter<LobbyEstado> emit,
  ) {
    if (event.sala.fase != FaseSala.enLobby) {
      emit(
        LobbyTransicionAPartida(
          urlServidor: _repositorio.urlServidorActual,
          salaInicial: event.sala,
          conexion: _repositorio.estadoConexionActual,
        ),
      );
      return;
    }

    if (state is LobbyEnSalaEspera &&
        identical((state as LobbyEnSalaEspera).sala, event.sala)) {
      return;
    }

    emit(
      LobbyEnSalaEspera(
        urlServidor: _repositorio.urlServidorActual,
        sala: event.sala,
        conexion: _repositorio.estadoConexionActual,
      ),
    );
  }

  void _onConexionRecibida(
    ConexionLobbyRecibidaInterna event,
    Emitter<LobbyEstado> emit,
  ) {
    if (state is LobbyEnSalaEspera) {
      final actual = state as LobbyEnSalaEspera;
      if (identical(actual.conexion, event.conexion) ||
          (actual.conexion.tipo == event.conexion.tipo &&
              actual.conexion.intentoActual == event.conexion.intentoActual)) {
        return;
      }
      emit(actual.copiarCon(conexion: event.conexion));
    }
  }

  void _onErrorRecibido(
    ErrorLobbyRecibidoInterno event,
    Emitter<LobbyEstado> emit,
  ) {
    if (event.fallo.codigo == CodigoFalloMultijugador.sesionExpirada) {
      emit(
        LobbyAccesoInicial(
          urlServidor: _repositorio.urlServidorActual,
          mensajeError: event.fallo.mensaje,
        ),
      );
      return;
    }

    if (state is LobbyEnSalaEspera) {
      emit(
        (state as LobbyEnSalaEspera).copiarCon(avisoError: event.fallo.mensaje),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subSala?.cancel();
    await _subConexion?.cancel();
    await _subErrores?.cancel();
    return super.close();
  }
}
