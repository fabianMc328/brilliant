import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/multijugador/bloc/lobby_bloc.dart';
import 'package:brilliant/multijugador/bloc/lobby_estado.dart';
import 'package:brilliant/multijugador/bloc/lobby_evento.dart';
import 'package:brilliant/multijugador/bloc/partida_multijugador_bloc.dart';
import 'package:brilliant/multijugador/bloc/partida_multijugador_estado.dart';
import 'package:brilliant/multijugador/bloc/partida_multijugador_evento.dart';
import 'package:brilliant/multijugador/dominio/estado_sala_multijugador.dart';
import 'package:brilliant/multijugador/dominio/estados_jugador_sala.dart';
import 'package:brilliant/multijugador/dominio/jugador_multijugador.dart';
import 'package:brilliant/multijugador/dominio/modelos_mapa.dart';
import 'package:brilliant/multijugador/infraestructura/repositorio_multijugador_fake.dart';
import 'package:brilliant/region.dart';

void main() {
  group('LobbyBloc', () {
    late RepositorioMultijugadorFake repo;

    setUp(() {
      repo = RepositorioMultijugadorFake();
    });

    tearDown(() async {
      await repo.cerrar();
    });

    blocTest<LobbyBloc, LobbyEstado>(
      'Valida apodo corto y código incompleto antes de intentar conectar',
      build: () => LobbyBloc(repositorio: repo),
      act: (bloc) {
        bloc.add(const SolicitarCrearSala(apodo: 'A'));
        bloc.add(const SolicitarUnirseASala(codigoSala: '123', apodo: 'Fabian'));
      },
      expect: () => [
        isA<LobbyAccesoInicial>().having(
          (s) => s.mensajeError,
          'error apodo',
          contains('apodo'),
        ),
        isA<LobbyAccesoInicial>().having(
          (s) => s.mensajeError,
          'error código',
          contains('6 caracteres'),
        ),
      ],
    );

    blocTest<LobbyBloc, LobbyEstado>(
      'Crea sala exitosamente y pasa a LobbyEnSalaEspera',
      build: () => LobbyBloc(repositorio: repo),
      act: (bloc) =>
          bloc.add(const SolicitarCrearSala(apodo: 'Fabian', nivelId: 'nivel_2')),
      expect: () => [
        isA<LobbyCargando>(),
        isA<LobbyEnSalaEspera>()
            .having((s) => s.sala.codigoSala, 'codigo', 'ABC234')
            .having((s) => s.sala.nivelId, 'nivelId', 'nivel_2'),
      ],
    );

    blocTest<LobbyBloc, LobbyEstado>(
      'Muestra error amigable si el servidor rechaza la unión (ej. sala llena)',
      build: () {
        repo.proximoFalloSimulado = const FalloMultijugador(
          codigo: CodigoFalloMultijugador.salaLlena,
          mensaje: 'La sala ya alcanzó el máximo de 6 jugadores.',
        );
        return LobbyBloc(repositorio: repo);
      },
      act: (bloc) => bloc.add(
        const SolicitarUnirseASala(codigoSala: 'ABC234', apodo: 'Invitado'),
      ),
      expect: () => [
        isA<LobbyCargando>(),
        isA<LobbyAccesoInicial>().having(
          (s) => s.mensajeError,
          'mensaje',
          contains('6 jugadores'),
        ),
      ],
    );

    blocTest<LobbyBloc, LobbyEstado>(
      'Exige que todos pulsen Listo y emite LobbyTransicionAPartida cuando inicia',
      build: () => LobbyBloc(repositorio: repo),
      act: (bloc) async {
        bloc.add(const SolicitarUnirseASala(codigoSala: 'K7M4P9', apodo: 'Ana'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // Intenta iniciar sin estar lista aún
        bloc.add(const SolicitarIniciarPartidaLobby());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // Ahora Ana pulsa Listo (Host ya estaba listo en el fake) y arranca
        bloc.add(const AlternarEstadoListoLobby(true));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const SolicitarIniciarPartidaLobby());
      },
      verify: (bloc) {
        expect(bloc.state, isA<LobbyTransicionAPartida>());
      },
    );
  });

  group('PartidaMultijugadorBloc', () {
    late RepositorioMultijugadorFake repo;

    setUp(() {
      repo = RepositorioMultijugadorFake();
      repo.emitirEstadoConexion(const EstadoConexionCliente.conectado());
    });

    tearDown(() async {
      await repo.cerrar();
    });

    test('Llena estrellas aleatorias y envía confirmación al repositorio', () async {
      const salaFase1 = EstadoSalaMultijugador(
        codigoSala: 'ABC234',
        miJugadorId: 'j1',
        fase: FaseSala.configurandoIniciales,
        nivelId: 'nivel_1',
        jugadores: [
          ResumenJugador(
            id: 'j1',
            apodo: 'Fabian',
            esAnfitrion: true,
            estaListo: true,
            participacion: EstadoParticipacion.conectado,
          ),
        ],
      );

      final bloc = PartidaMultijugadorBloc(
        repositorio: repo,
        salaInicial: salaFase1,
        random: Random(1),
      );

      bloc.add(const LlenarEstrellasAleatoriasLocales());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final trasAleatorio = bloc.state as PartidaMultijugadorActiva;
      expect(trasAleatorio.estrellasCompletasParaConfirmar, isTrue);

      bloc.add(const ConfirmarEstrellasMultijugador());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repo.ultimasEstrellasConfirmadas?.length, 6);
      await bloc.close();
    });

    test('Selecciona ancla, conserva selección ante ticks del reloj, juega turno y permite conceder', () async {
      final salaRonda1 = EstadoSalaMultijugador(
        codigoSala: 'ABC234',
        miJugadorId: 'j1',
        fase: FaseSala.jugandoRondas,
        nivelId: 'nivel_1',
        rondaActual: 1,
        dado1: 2,
        dado2: 2,
        segundosRestantes: 40,
        misValoresTablero: {
          const PosicionMapa(1, 2): 2, // Estrella en azul_1 (todos iguales)
        },
        jugadores: const [
          ResumenJugador(
            id: 'j1',
            apodo: 'Fabian',
            esAnfitrion: true,
            estaListo: true,
            participacion: EstadoParticipacion.conectado,
          ),
          ResumenJugador(
            id: 'j2',
            apodo: 'Rival',
            esAnfitrion: false,
            estaListo: true,
            participacion: EstadoParticipacion.conectado,
          ),
        ],
      );

      final bloc = PartidaMultijugadorBloc(
        repositorio: repo,
        salaInicial: salaRonda1,
      );

      // Seleccionamos el ancla (1, 2) que tiene valor 2
      bloc.add(const SeleccionarAnclaMultijugador(Coordenada(1, 2)));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      var estado = bloc.state as PartidaMultijugadorActiva;
      expect(estado.anclaSeleccionada, const Coordenada(1, 2));
      expect(estado.casillasValidas.contains(const Coordenada(0, 2)), isTrue);

      // Llega un tick del reloj (segundosRestantes: 39) en la misma ronda 1: NO debe borrar el ancla
      repo.emitirEstadoSala(
        EstadoSalaMultijugador(
          codigoSala: salaRonda1.codigoSala,
          miJugadorId: salaRonda1.miJugadorId,
          fase: salaRonda1.fase,
          nivelId: salaRonda1.nivelId,
          rondaActual: 1,
          dado1: 2,
          dado2: 2,
          segundosRestantes: 39,
          misValoresTablero: salaRonda1.misValoresTablero,
          jugadores: salaRonda1.jugadores,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      estado = bloc.state as PartidaMultijugadorActiva;
      expect(estado.anclaSeleccionada, const Coordenada(1, 2));

      // Colocamos el 2 en la casilla vecina (0, 2) de azul_1
      bloc.add(const ColocarNumeroMultijugador(Coordenada(0, 2)));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.ultimaJugadaEnviada?.$1, 1);
      expect(repo.ultimaJugadaEnviada?.$3, const PosicionMapa(0, 2));
      expect(repo.ultimaJugadaEnviada?.$4, 2);

      // Probamos conceder partida y estado de reconexión
      repo.emitirEstadoConexion(
        const EstadoConexionCliente.reconectando(
          intentoActual: 1,
          maxIntentos: 5,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        (bloc.state as PartidaMultijugadorActiva).conexion.tipo,
        TipoEstadoConexionCliente.reconectando,
      );

      bloc.add(const SolicitarConcederPartida());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.concederFueLlamado, isTrue);

      await bloc.close();
    });
  });
}
