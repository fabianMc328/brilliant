import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../constantes_multijugador.dart';
import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';
import '../dominio/mensajes_protocolo.dart';
import '../dominio/modelos_mapa.dart';
import '../dominio/repositorio_multijugador.dart';

typedef FabricaCanalWebSocket = WebSocketChannel Function(Uri uri);

/// Cliente WebSocket resiliente con reconexión automática, heartbeats y manejo tipado de fallos.
class ClienteWebsocketMultijugador implements RepositorioMultijugador {
  final FabricaCanalWebSocket _fabricaCanal;
  final Duration _timeoutOperacion;
  final Duration _intervaloPing;
  final List<Duration> _tiemposEsperaReconexion;

  String _urlServidor;
  WebSocketChannel? _canal;
  StreamSubscription<dynamic>? _suscripcionCanal;
  Timer? _timerPing;
  Timer? _timerReconexion;

  CredencialSesionSala? _credencialActiva;
  EstadoSalaMultijugador? _ultimoEstadoSala;
  EstadoConexionCliente _estadoConexion =
      const EstadoConexionCliente.desconectado();

  bool _cerrandoVoluntariamente = false;
  bool _reconectandoEnCurso = false;
  int _secuenciaSolicitud = 0;

  final Map<String, Completer<EventoServidor>> _solicitudesPendientes = {};

  final StreamController<EstadoSalaMultijugador> _controladorSala =
      StreamController<EstadoSalaMultijugador>.broadcast();
  final StreamController<EstadoConexionCliente> _controladorConexion =
      StreamController<EstadoConexionCliente>.broadcast();
  final StreamController<FalloMultijugador> _controladorErrores =
      StreamController<FalloMultijugador>.broadcast();
  final StreamController<MensajeChat> _controladorChat =
      StreamController<MensajeChat>.broadcast();

  ClienteWebsocketMultijugador({
    String urlInicial = ConstantesMultijugador.urlServidorLocalPorDefecto,
    FabricaCanalWebSocket? fabricaCanal,
    Duration timeoutOperacion = ConstantesMultijugador.timeoutConexionInicial,
    Duration intervaloPing = ConstantesMultijugador.intervaloHeartbeat,
    List<Duration>? tiemposEsperaReconexion,
  })  : _urlServidor = _normalizarUrl(urlInicial),
        _fabricaCanal = fabricaCanal ?? WebSocketChannel.connect,
        _timeoutOperacion = timeoutOperacion,
        _intervaloPing = intervaloPing,
        _tiemposEsperaReconexion = tiemposEsperaReconexion ??
            const [
              Duration(seconds: 1),
              Duration(seconds: 2),
              Duration(seconds: 3),
              Duration(seconds: 5),
              Duration(seconds: 8),
            ];

  @override
  Stream<EstadoSalaMultijugador> get flujoSala => _controladorSala.stream;

  @override
  Stream<EstadoConexionCliente> get flujoConexion =>
      _controladorConexion.stream;

  @override
  Stream<FalloMultijugador> get flujoErrores => _controladorErrores.stream;

  @override
  Stream<MensajeChat> get flujoChat => _controladorChat.stream;

  @override
  EstadoSalaMultijugador? get ultimoEstadoSala => _ultimoEstadoSala;

  @override
  EstadoConexionCliente get estadoConexionActual => _estadoConexion;

  @override
  String get urlServidorActual => _urlServidor;

  @override
  void configurarUrlServidor(String nuevaUrl) {
    final limpia = nuevaUrl.trim();
    if (limpia.isEmpty) return;
    _urlServidor = _normalizarUrl(limpia);
  }

  @override
  Future<EstadoSalaMultijugador> crearSala({
    required String apodo,
    String nivelId = 'nivel_1',
  }) async {
    await _limpiarSesionActivaSinCerrarControladores();
    _cerrandoVoluntariamente = false;
    await _abrirCanalFisico();

    final evento = await _enviarEsperandoRespuesta(
      ComandoCliente(
        tipo: TipoComandoCliente.crearSala,
        solicitudId: _nuevaSolicitudId(),
        datos: {
          'apodo': apodo,
          'nivelId': nivelId,
        },
      ),
    );
    return evento.estadoSala!;
  }

  @override
  Future<EstadoSalaMultijugador> unirseASala({
    required String codigoSala,
    required String apodo,
  }) async {
    await _limpiarSesionActivaSinCerrarControladores();
    _cerrandoVoluntariamente = false;
    await _abrirCanalFisico();

    final evento = await _enviarEsperandoRespuesta(
      ComandoCliente(
        tipo: TipoComandoCliente.unirseSala,
        solicitudId: _nuevaSolicitudId(),
        datos: {
          'codigoSala': codigoSala.trim().toUpperCase(),
          'apodo': apodo,
        },
      ),
    );
    return evento.estadoSala!;
  }

  @override
  Future<void> reintentarReconexionManual() async {
    if (_credencialActiva == null) {
      throw const FalloMultijugador(
        codigo: CodigoFalloMultijugador.sesionExpirada,
        mensaje: 'No hay una sesión activa para reconectar.',
      );
    }
    _timerReconexion?.cancel();
    _reconectandoEnCurso = false;
    await _intentarCicloReconexion(desdeIntento: 1);
  }

  @override
  Future<void> seleccionarNivel(String nivelId) async {
    _enviarComandoSimple(
      ComandoCliente(
        tipo: TipoComandoCliente.seleccionarNivel,
        datos: {'nivelId': nivelId},
      ),
    );
  }

  @override
  Future<void> alternarListo(bool listo) async {
    _enviarComandoSimple(
      ComandoCliente(
        tipo: TipoComandoCliente.alternarListo,
        datos: {'listo': listo},
      ),
    );
  }

  @override
  Future<void> iniciarPartida() async {
    _enviarComandoSimple(
      const ComandoCliente(tipo: TipoComandoCliente.iniciarPartida),
    );
  }

  @override
  Future<void> confirmarValoresIniciales(
    Map<PosicionMapa, int> valoresEstrellas,
  ) async {
    _enviarComandoSimple(
      ComandoCliente(
        tipo: TipoComandoCliente.confirmarIniciales,
        datos: {
          'valoresEstrellas':
              ComandoCliente.serializarMapaPosiciones(valoresEstrellas),
        },
      ),
    );
  }

  @override
  Future<void> colocarNumeroEnRonda({
    required int ronda,
    required PosicionMapa ancla,
    required PosicionMapa destino,
    required int valorColocado,
  }) async {
    _enviarComandoSimple(
      ComandoCliente(
        tipo: TipoComandoCliente.jugarTurno,
        datos: {
          'ronda': ronda,
          'ancla': ancla.toJson(),
          'destino': destino.toJson(),
          'valorColocado': valorColocado,
        },
      ),
    );
  }

  @override
  Future<void> pasarTurnoEnRonda({required int ronda}) async {
    _enviarComandoSimple(
      ComandoCliente(
        tipo: TipoComandoCliente.pasarTurno,
        datos: {'ronda': ronda},
      ),
    );
  }

  @override
  Future<void> concederPartida() async {
    _enviarComandoSimple(
      const ComandoCliente(tipo: TipoComandoCliente.concederPartida),
    );
  }

  @override
  Future<void> enviarMensajeChat(String texto) async {
    _enviarComandoSimple(
      ComandoCliente(
        tipo: TipoComandoCliente.enviarMensajeChat,
        datos: {'texto': texto},
      ),
    );
  }

  @override
  Future<void> salirDeSala() async {
    _cerrandoVoluntariamente = true;
    _timerReconexion?.cancel();
    _credencialActiva = null;
    _ultimoEstadoSala = null;

    if (_canal != null &&
        _estadoConexion.tipo == TipoEstadoConexionCliente.conectado) {
      try {
        _canal!.sink.add(
          jsonEncode(
            const ComandoCliente(tipo: TipoComandoCliente.salirSala).toJson(),
          ),
        );
      } catch (_) {}
    }

    await _cerrarCanalActual();
    _actualizarEstadoConexion(const EstadoConexionCliente.desconectado());
  }

  @override
  Future<void> cerrar() async {
    await salirDeSala();
    if (!_controladorSala.isClosed) await _controladorSala.close();
    if (!_controladorConexion.isClosed) await _controladorConexion.close();
    if (!_controladorErrores.isClosed) await _controladorErrores.close();
    if (!_controladorChat.isClosed) await _controladorChat.close();
  }

  // --- Gestión interna del canal, heartbeats y reconexión ---

  Future<void> _abrirCanalFisico() async {
    await _cerrarCanalActual();
    _actualizarEstadoConexion(const EstadoConexionCliente.conectando());

    final Uri uri;
    try {
      uri = Uri.parse(_urlServidor);
      if (!uri.hasScheme || (uri.scheme != 'ws' && uri.scheme != 'wss')) {
        throw const FormatException('Esquema inválido');
      }
    } catch (_) {
      _actualizarEstadoConexion(
        const EstadoConexionCliente.desconectado('URL inválida'),
      );
      throw const FalloMultijugador(
        codigo: CodigoFalloMultijugador.sinConexionServidor,
        mensaje: 'La dirección del servidor no tiene un formato válido (ws://...).',
      );
    }

    WebSocketChannel? canalTentativo;
    try {
      canalTentativo = _fabricaCanal(uri);
      await canalTentativo.ready.timeout(_timeoutOperacion);
    } on TimeoutException {
      canalTentativo?.ready.ignore();
      try {
        canalTentativo?.sink.close().ignore();
      } catch (_) {}
      _actualizarEstadoConexion(
        const EstadoConexionCliente.desconectado('Tiempo agotado'),
      );
      throw const FalloMultijugador(
        codigo: CodigoFalloMultijugador.tiempoEsperaAgotado,
        mensaje: 'Tiempo agotado al intentar conectar con el servidor.',
      );
    } catch (_) {
      canalTentativo?.ready.ignore();
      _actualizarEstadoConexion(
        const EstadoConexionCliente.desconectado('Servidor no disponible'),
      );
      throw FalloMultijugador(
        codigo: CodigoFalloMultijugador.sinConexionServidor,
        mensaje:
            'No se pudo conectar al servidor ($_urlServidor). Verifica que esté encendido y en la misma red.',
      );
    }

    final canal = canalTentativo;

    _canal = canal;
    _actualizarEstadoConexion(const EstadoConexionCliente.conectado());

    _suscripcionCanal = canal.stream.listen(
      _procesarMensajeEntrante,
      onDone: _manejarCaidaInesperada,
      onError: (_) => _manejarCaidaInesperada(),
      cancelOnError: true,
    );

    _timerPing = Timer.periodic(_intervaloPing, (_) {
      if (_estadoConexion.tipo == TipoEstadoConexionCliente.conectado) {
        try {
          _canal?.sink.add(
            jsonEncode(
              const ComandoCliente(tipo: TipoComandoCliente.ping).toJson(),
            ),
          );
        } catch (_) {
          _manejarCaidaInesperada();
        }
      }
    });
  }

  void _procesarMensajeEntrante(dynamic raw) {
    if (raw is! String) return;
    EventoServidor evento;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      evento = EventoServidor.fromJson(json);
    } catch (_) {
      return;
    }

    if (evento.tipo == TipoEventoServidor.pong) return;

    if (evento.credencial != null) {
      _credencialActiva = evento.credencial;
    }

    if (evento.estadoSala != null) {
      _ultimoEstadoSala = evento.estadoSala;
      if (!_controladorSala.isClosed) {
        _controladorSala.add(evento.estadoSala!);
      }
    }

    if (evento.tipo == TipoEventoServidor.mensajeChatRecibido &&
        evento.mensajeChat != null) {
      if (!_controladorChat.isClosed) {
        _controladorChat.add(evento.mensajeChat!);
      }
    }

    final reqId = evento.solicitudId;
    if (reqId != null && _solicitudesPendientes.containsKey(reqId)) {
      final completer = _solicitudesPendientes.remove(reqId)!;
      if (evento.tipo == TipoEventoServidor.errorOperacion &&
          evento.fallo != null) {
        completer.completeError(evento.fallo!);
      } else {
        completer.complete(evento);
      }
      return;
    }

    if (evento.tipo == TipoEventoServidor.errorOperacion &&
        evento.fallo != null) {
      if (evento.fallo!.codigo == CodigoFalloMultijugador.sesionExpirada) {
        _credencialActiva = null;
      }
      if (!_controladorErrores.isClosed) {
        _controladorErrores.add(evento.fallo!);
      }
    }
  }

  void _manejarCaidaInesperada() {
    _fallarSolicitudesPendientes(
      const FalloMultijugador(
        codigo: CodigoFalloMultijugador.sinConexionServidor,
        mensaje: 'La conexión se interrumpió antes de completar la operación.',
      ),
    );

    if (_cerrandoVoluntariamente) return;

    final faseActual = _ultimoEstadoSala?.fase;
    if (_credencialActiva == null || faseActual == FaseSala.finalizada) {
      _actualizarEstadoConexion(const EstadoConexionCliente.desconectado());
      return;
    }

    if (!_reconectandoEnCurso) {
      _intentarCicloReconexion(desdeIntento: 1);
    }
  }

  Future<void> _intentarCicloReconexion({required int desdeIntento}) async {
    if (_reconectandoEnCurso) return;
    _reconectandoEnCurso = true;

    final maxIntentos = _tiemposEsperaReconexion.length;

    for (int intento = desdeIntento; intento <= maxIntentos; intento++) {
      if (_cerrandoVoluntariamente || _credencialActiva == null) {
        _reconectandoEnCurso = false;
        return;
      }

      _actualizarEstadoConexion(
        EstadoConexionCliente.reconectando(
          intentoActual: intento,
          maxIntentos: maxIntentos,
          detalle: 'Reconectando con la sala (${_credencialActiva!.codigoSala})...',
        ),
      );

      final espera = _tiemposEsperaReconexion[intento - 1];
      final completadorEspera = Completer<void>();
      _timerReconexion = Timer(espera, () {
        if (!completadorEspera.isCompleted) completadorEspera.complete();
      });
      await completadorEspera.future;

      if (_cerrandoVoluntariamente || _credencialActiva == null) {
        _reconectandoEnCurso = false;
        return;
      }

      try {
        await _abrirCanalFisico();
        final cred = _credencialActiva!;
        await _enviarEsperandoRespuesta(
          ComandoCliente(
            tipo: TipoComandoCliente.reconectarSala,
            solicitudId: _nuevaSolicitudId(),
            datos: {
              'codigoSala': cred.codigoSala,
              'jugadorId': cred.jugadorId,
              'tokenSesion': cred.tokenSesion,
            },
          ),
        );
        _actualizarEstadoConexion(const EstadoConexionCliente.conectado());
        _reconectandoEnCurso = false;
        return;
      } on FalloMultijugador catch (fallo) {
        if (fallo.codigo == CodigoFalloMultijugador.sesionExpirada) {
          _credencialActiva = null;
          _reconectandoEnCurso = false;
          _actualizarEstadoConexion(
            EstadoConexionCliente.perdidaDefinitiva(fallo.mensaje),
          );
          if (!_controladorErrores.isClosed) {
            _controladorErrores.add(fallo);
          }
          return;
        }
      } catch (_) {}
    }

    _reconectandoEnCurso = false;
    _actualizarEstadoConexion(
      const EstadoConexionCliente.perdidaDefinitiva(
        'No se pudo recuperar la conexión tras varios intentos.',
      ),
    );
  }

  Future<EventoServidor> _enviarEsperandoRespuesta(
    ComandoCliente comando,
  ) async {
    final canal = _canal;
    if (canal == null ||
        _estadoConexion.tipo != TipoEstadoConexionCliente.conectado) {
      throw const FalloMultijugador(
        codigo: CodigoFalloMultijugador.sinConexionServidor,
        mensaje: 'No hay conexión activa con el servidor.',
      );
    }

    final reqId = comando.solicitudId ?? _nuevaSolicitudId();
    final completer = Completer<EventoServidor>();
    _solicitudesPendientes[reqId] = completer;

    try {
      canal.sink.add(jsonEncode(comando.toJson()));
      return await completer.future.timeout(_timeoutOperacion);
    } on TimeoutException {
      _solicitudesPendientes.remove(reqId);
      throw const FalloMultijugador(
        codigo: CodigoFalloMultijugador.tiempoEsperaAgotado,
        mensaje: 'El servidor tardó demasiado en responder.',
      );
    } catch (e) {
      _solicitudesPendientes.remove(reqId);
      if (e is FalloMultijugador) rethrow;
      throw const FalloMultijugador(
        codigo: CodigoFalloMultijugador.sinConexionServidor,
        mensaje: 'Error de red al enviar la solicitud.',
      );
    }
  }

  void _enviarComandoSimple(ComandoCliente comando) {
    final canal = _canal;
    if (canal == null ||
        _estadoConexion.tipo != TipoEstadoConexionCliente.conectado) {
      if (!_controladorErrores.isClosed) {
        _controladorErrores.add(
          const FalloMultijugador(
            codigo: CodigoFalloMultijugador.sinConexionServidor,
            mensaje: 'Sin conexión en este momento. Espera a reconectar.',
          ),
        );
      }
      return;
    }

    try {
      canal.sink.add(jsonEncode(comando.toJson()));
    } catch (_) {
      _manejarCaidaInesperada();
    }
  }

  Future<void> _limpiarSesionActivaSinCerrarControladores() async {
    _cerrandoVoluntariamente = true;
    _timerReconexion?.cancel();
    _reconectandoEnCurso = false;
    _credencialActiva = null;
    _ultimoEstadoSala = null;
    await _cerrarCanalActual();
  }

  Future<void> _cerrarCanalActual() async {
    _timerPing?.cancel();
    _timerPing = null;

    final sub = _suscripcionCanal;
    _suscripcionCanal = null;
    await sub?.cancel();

    final canal = _canal;
    _canal = null;
    try {
      await canal?.sink.close();
    } catch (_) {}
  }

  void _fallarSolicitudesPendientes(FalloMultijugador fallo) {
    final pendientes = _solicitudesPendientes.values.toList();
    _solicitudesPendientes.clear();
    for (final c in pendientes) {
      if (!c.isCompleted) {
        c.completeError(fallo);
      }
    }
  }

  void _actualizarEstadoConexion(EstadoConexionCliente nuevo) {
    _estadoConexion = nuevo;
    if (!_controladorConexion.isClosed) {
      _controladorConexion.add(nuevo);
    }
  }

  String _nuevaSolicitudId() {
    _secuenciaSolicitud += 1;
    return 'sol_$_secuenciaSolicitud';
  }

  static String _normalizarUrl(String entrada) {
    final limpia = entrada.trim();
    if (limpia.startsWith('ws://') || limpia.startsWith('wss://')) {
      return limpia;
    }
    if (limpia.startsWith('http://')) {
      return 'ws://${limpia.substring(7)}';
    }
    if (limpia.startsWith('https://')) {
      return 'wss://${limpia.substring(8)}';
    }
    return 'ws://$limpia';
  }
}
