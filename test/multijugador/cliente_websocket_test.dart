import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:brilliant/multijugador/dominio/estado_sala_multijugador.dart';
import 'package:brilliant/multijugador/dominio/estados_jugador_sala.dart';
import 'package:brilliant/multijugador/dominio/jugador_multijugador.dart';
import 'package:brilliant/multijugador/dominio/mensajes_protocolo.dart';
import 'package:brilliant/multijugador/dominio/modelos_mapa.dart';
import 'package:brilliant/multijugador/infraestructura/cliente_websocket_multijugador.dart';

/// Canal WebSocket falso en memoria para probar el cliente desacoplado del servidor.
class _CanalWebSocketMemoria implements WebSocketChannel {
  final StreamController<dynamic> _delServidorAlCliente =
      StreamController<dynamic>();
  final StreamController<dynamic> _delClienteAlServidor =
      StreamController<dynamic>();
  late final _SinkMemoria _sink = _SinkMemoria(_delClienteAlServidor);

  @override
  Future<void> get ready => Future<void>.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Stream<dynamic> get stream => _delServidorAlCliente.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Stream<ComandoCliente> get comandosRecibidos =>
      _delClienteAlServidor.stream.map((raw) {
        return ComandoCliente.fromJson(
          jsonDecode(raw as String) as Map<String, dynamic>,
        );
      });

  void enviarEventoAlCliente(EventoServidor evento) {
    if (!_delServidorAlCliente.isClosed) {
      _delServidorAlCliente.add(jsonEncode(evento.toJson()));
    }
  }

  Future<void> simularCaidaDeRed() async {
    if (!_delServidorAlCliente.isClosed) {
      await _delServidorAlCliente.close();
    }
  }
}

class _SinkMemoria implements WebSocketSink {
  final StreamController<dynamic> _ctrl;

  _SinkMemoria(this._ctrl);

  @override
  void add(dynamic data) {
    if (!_ctrl.isClosed) _ctrl.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_ctrl.isClosed) _ctrl.addError(error, stackTrace);
  }

  @override
  Future<dynamic> addStream(Stream<dynamic> stream) => _ctrl.addStream(stream);

  @override
  Future<dynamic> close([int? closeCode, String? closeReason]) => _ctrl.close();

  @override
  Future<dynamic> get done => _ctrl.done;
}

EstadoSalaMultijugador _salaEjemplo({
  FaseSala fase = FaseSala.enLobby,
  String codigo = 'K7M4P9',
}) {
  return EstadoSalaMultijugador(
    codigoSala: codigo,
    miJugadorId: 'jug_1',
    fase: fase,
    nivelId: 'nivel_2',
    rondaActual: 1,
    dado1: 4,
    dado2: 2,
    jugadores: const [
      ResumenJugador(
        id: 'jug_1',
        apodo: 'Fabian',
        esAnfitrion: true,
        estaListo: true,
        participacion: EstadoParticipacion.conectado,
      ),
    ],
  );
}

void main() {
  group('ClienteWebsocketMultijugador - Protocolo y Resiliencia Desacoplada', () {
    test('Normaliza URL, envía crearSala y despacha comandos de lobby y partida', () async {
      late _CanalWebSocketMemoria canalActivo;
      final comandos = <ComandoCliente>[];

      final cliente = ClienteWebsocketMultijugador(
        urlInicial: 'http://192.168.0.3:8080',
        fabricaCanal: (uri) {
          expect(uri.toString(), 'ws://192.168.0.3:8080');
          canalActivo = _CanalWebSocketMemoria();
          canalActivo.comandosRecibidos.listen((cmd) {
            comandos.add(cmd);
            if (cmd.tipo == TipoComandoCliente.crearSala) {
              canalActivo.enviarEventoAlCliente(
                EventoServidor(
                  tipo: TipoEventoServidor.sesionEstablecida,
                  solicitudId: cmd.solicitudId,
                  credencial: const CredencialSesionSala(
                    codigoSala: 'K7M4P9',
                    jugadorId: 'jug_1',
                    tokenSesion: 'tok_123',
                    apodo: 'Fabian',
                  ),
                  estadoSala: _salaEjemplo(),
                ),
              );
            }
          });
          return canalActivo;
        },
      );
      addTearDown(cliente.cerrar);

      final sala = await cliente.crearSala(apodo: 'Fabian', nivelId: 'nivel_2');
      expect(sala.codigoSala, 'K7M4P9');
      expect(cliente.estadoConexionActual.tipo, TipoEstadoConexionCliente.conectado);

      await cliente.alternarListo(true);
      await cliente.colocarNumeroEnRonda(
        ronda: 1,
        ancla: const PosicionMapa(1, 2),
        destino: const PosicionMapa(1, 3),
        valorColocado: 4,
      );
      await cliente.concederPartida();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        comandos.map((c) => c.tipo),
        containsAll([
          TipoComandoCliente.crearSala,
          TipoComandoCliente.alternarListo,
          TipoComandoCliente.jugarTurno,
          TipoComandoCliente.concederPartida,
        ]),
      );
    });

    test('Propaga errores tipados del servidor (ej. salaLlena) y reconecta automáticamente ante caída', () async {
      final canales = <_CanalWebSocketMemoria>[];
      bool rechazarUnirse = true;

      final cliente = ClienteWebsocketMultijugador(
        fabricaCanal: (_) {
          final c = _CanalWebSocketMemoria();
          canales.add(c);
          c.comandosRecibidos.listen((cmd) {
            if (cmd.tipo == TipoComandoCliente.unirseSala && rechazarUnirse) {
              c.enviarEventoAlCliente(
                EventoServidor(
                  tipo: TipoEventoServidor.errorOperacion,
                  solicitudId: cmd.solicitudId,
                  fallo: const FalloMultijugador(
                    codigo: CodigoFalloMultijugador.salaLlena,
                    mensaje: 'Sala llena (6/6).',
                  ),
                ),
              );
            } else if (cmd.tipo == TipoComandoCliente.unirseSala &&
                !rechazarUnirse) {
              c.enviarEventoAlCliente(
                EventoServidor(
                  tipo: TipoEventoServidor.sesionEstablecida,
                  solicitudId: cmd.solicitudId,
                  credencial: const CredencialSesionSala(
                    codigoSala: 'K7M4P9',
                    jugadorId: 'jug_2',
                    tokenSesion: 'tok_secreto_2',
                    apodo: 'Invitado',
                  ),
                  estadoSala: _salaEjemplo(fase: FaseSala.jugandoRondas),
                ),
              );
            } else if (cmd.tipo == TipoComandoCliente.reconectarSala) {
              expect(cmd.datos['tokenSesion'], 'tok_secreto_2');
              c.enviarEventoAlCliente(
                EventoServidor(
                  tipo: TipoEventoServidor.sesionEstablecida,
                  solicitudId: cmd.solicitudId,
                  credencial: const CredencialSesionSala(
                    codigoSala: 'K7M4P9',
                    jugadorId: 'jug_2',
                    tokenSesion: 'tok_secreto_2',
                    apodo: 'Invitado',
                  ),
                  estadoSala: _salaEjemplo(fase: FaseSala.jugandoRondas),
                ),
              );
            }
          });
          return c;
        },
        tiemposEsperaReconexion: const [Duration(milliseconds: 50)],
      );
      addTearDown(cliente.cerrar);

      // 1. Sala llena lanza FalloMultijugador(salaLlena)
      await expectLater(
        () => cliente.unirseASala(codigoSala: 'K7M4P9', apodo: 'Invitado'),
        throwsA(
          isA<FalloMultijugador>().having(
            (f) => f.codigo,
            'codigo',
            CodigoFalloMultijugador.salaLlena,
          ),
        ),
      );

      // 2. Unión exitosa guarda credencial y al caer el canal reconecta solo
      rechazarUnirse = false;
      await cliente.unirseASala(codigoSala: 'K7M4P9', apodo: 'Invitado');

      final vioReconectando = cliente.flujoConexion.firstWhere(
        (e) => e.tipo == TipoEstadoConexionCliente.reconectando,
      );
      final vioReconectado = cliente.flujoConexion
          .skipWhile((e) => e.tipo != TipoEstadoConexionCliente.reconectando)
          .firstWhere((e) => e.tipo == TipoEstadoConexionCliente.conectado);

      await canales.last.simularCaidaDeRed();

      await vioReconectando.timeout(const Duration(seconds: 2));
      await vioReconectado.timeout(const Duration(seconds: 2));
      expect(
        cliente.estadoConexionActual.tipo,
        TipoEstadoConexionCliente.conectado,
      );
    });

    test('Falla limpiamente cuando servidorBrilliant está apagado o inalcanzable', () async {
      final clienteSinRed = ClienteWebsocketMultijugador(
        urlInicial: 'ws://127.0.0.1:1',
        timeoutOperacion: const Duration(milliseconds: 250),
      );
      addTearDown(clienteSinRed.cerrar);

      await expectLater(
        () => clienteSinRed.crearSala(apodo: 'Solo'),
        throwsA(
          isA<FalloMultijugador>().having(
            (f) => f.codigo,
            'codigo',
            isIn([
              CodigoFalloMultijugador.sinConexionServidor,
              CodigoFalloMultijugador.tiempoEsperaAgotado,
            ]),
          ),
        ),
      );
    });
  });
}
