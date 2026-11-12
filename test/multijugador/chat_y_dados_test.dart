import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/juego_bloc.dart';
import 'package:brilliant/juego_estado.dart';
import 'package:brilliant/juego_evento.dart';
import 'package:brilliant/multijugador/bloc/lobby_bloc.dart';
import 'package:brilliant/multijugador/bloc/lobby_estado.dart';
import 'package:brilliant/multijugador/bloc/lobby_evento.dart';
import 'package:brilliant/multijugador/bloc/partida_multijugador_bloc.dart';
import 'package:brilliant/multijugador/bloc/partida_multijugador_estado.dart';
import 'package:brilliant/multijugador/dominio/estado_sala_multijugador.dart';
import 'package:brilliant/multijugador/dominio/estados_jugador_sala.dart';
import 'package:brilliant/multijugador/dominio/jugador_multijugador.dart';
import 'package:brilliant/multijugador/dominio/mensajes_protocolo.dart';
import 'package:brilliant/multijugador/dominio/modelos_mapa.dart';
import 'package:brilliant/multijugador/infraestructura/repositorio_multijugador_fake.dart';
import 'package:brilliant/niveles/catalogo_niveles.dart';
import 'package:brilliant/region.dart';
import 'package:brilliant/tablero.dart';
import 'package:brilliant/tipo.dart';

void main() {
  group('Mensaje corto explicativo de regla en cada color', () {
    test('Cada subclase de Tipo expone su regla corta oficial', () {
      expect(TipoAzul().reglaCorta, 'Todos =');
      expect(TipoGris().reglaCorta, 'Todos =');
      expect(TipoMorado().reglaCorta, 'Máx 2 dif.');
      expect(TipoVerde().reglaCorta, 'Libre');
      expect(TipoAmarillo().reglaCorta, 'Todos ≠');
      expect(TipoRojo().reglaCorta, 'Todos ≠');
      expect(TipoNaranja1a3().reglaCorta, '1 a 3');
      expect(TipoNaranja4a6().reglaCorta, '4 a 6');
    });
  });

  group('Selección de dado y tirada obligatoria en Solitario', () {
    late Tablero tablero;
    late List<Coordenada> estrellas;

    setUp(() {
      final nivel = CatalogoNiveles.nivel1;
      tablero = nivel.crearTablero();
      estrellas = nivel.casillasIniciales;
    });

    test('Tablero.obtenerPosiblesLugaresParaDado busca casillas vacías adyacentes al ancla', () {
      // Colocar un 3 en una casilla
      final coordAncla = estrellas.first;
      tablero.celdas[coordAncla]?.valor = 3;

      // Colocar número 4 teniendo valorAncla = 3
      final posibles = tablero.obtenerPosiblesLugaresParaDado(
        numeroAColocar: 4,
        valorAncla: 3,
      );

      expect(posibles.isNotEmpty, isTrue);
      for (final p in posibles) {
        expect(tablero.obtenerVecinosOrtogonales(p).contains(coordAncla), isTrue);
        expect(tablero.celdas[p]?.estaVacia, isTrue);
      }
    });

    test('JuegoBloc: seleccionar dado, colocar número activa debeTirarDados y exige tirar dados', () async {
      final bloc = JuegoBloc();
      bloc.add(IniciarConfiguracionInicial(estrellas));

      // Llenar estrellas
      for (int i = 0; i < 6; i++) {
        bloc.add(ColocarValorInicial(estrellas[i], i + 1));
      }
      bloc.add(AvanzarJuego());

      // Estado en progreso
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<JuegoEstado>((e) => e is JuegoEnProgreso)),
      );

      final estadoProgreso = bloc.state as JuegoEnProgreso;
      final d1 = estadoProgreso.dado1;
      final d2 = estadoProgreso.dado2;

      // Seleccionar el dado 1
      bloc.add(SeleccionarDado(indiceDado: 1, valor: d1));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<JuegoEstado>((e) {
          if (e is! JuegoEnProgreso) return false;
          return e.indiceDadoSeleccionado == 1 && e.numeroAColocar == d1;
        })),
      );

      final estadoConDado = bloc.state as JuegoEnProgreso;
      if (estadoConDado.casillasValidas.isNotEmpty) {
        final destino = estadoConDado.casillasValidas.first;
        bloc.add(ColocarNumero(destino));

        await expectLater(
          bloc.stream,
          emitsThrough(predicate<JuegoEstado>((e) {
            if (e is! JuegoEnProgreso) return false;
            return e.debeTirarDados == true;
          })),
        );

        // Intentar seleccionar otro dado no cambia antes de tirar dados obligatorios
        bloc.add(SeleccionarDado(indiceDado: 2, valor: d2));
        expect((bloc.state as JuegoEnProgreso).debeTirarDados, isTrue);

        // Tirar dados obligatorio
        bloc.add(TirarDados());
        await expectLater(
          bloc.stream,
          emitsThrough(predicate<JuegoEstado>((e) {
            if (e is! JuegoEnProgreso) return false;
            return e.debeTirarDados == false;
          })),
        );
      }

      await bloc.close();
    });
  });

  group('Chat en tiempo real en Lobby y Partida Multijugador', () {
    late RepositorioMultijugadorFake repoFake;

    setUp(() {
      repoFake = RepositorioMultijugadorFake();
    });

    tearDown(() {
      repoFake.cerrar();
    });

    test('LobbyBloc recibe mensajes de chat y los acumula en historialChat', () async {
      final lobbyBloc = LobbyBloc(repositorio: repoFake);
      lobbyBloc.add(const SolicitarCrearSala(apodo: 'Fabian', nivelId: 'nivel_1'));

      await expectLater(
        lobbyBloc.stream,
        emitsThrough(isA<LobbyEnSalaEspera>()),
      );

      // Simular llegada de mensaje de chat
      final mensaje = MensajeChat(
        id: 'msg_1',
        codigoSala: 'TEST01',
        remitenteId: 'jug_2',
        remitenteApodo: 'Pedro',
        texto: '¡Hola a todos!',
        fecha: DateTime.now(),
      );

      repoFake.emitirMensajeChat(mensaje);

      await expectLater(
        lobbyBloc.stream,
        emitsThrough(predicate<LobbyEstado>((e) {
          if (e is! LobbyEnSalaEspera) return false;
          return e.historialChat.length == 1 && e.historialChat.first.texto == '¡Hola a todos!';
        })),
      );

      await lobbyBloc.close();
    });

    test('PartidaMultijugadorBloc recibe mensajes de chat y permite enviar', () async {
      final mapaTablero = <PosicionMapa, int>{
        const PosicionMapa(1, 2): 3,
        const PosicionMapa(1, 5): 5,
      };

      final salaInicial = EstadoSalaMultijugador(
        codigoSala: 'TEST01',
        miJugadorId: 'jug_1',
        nivelId: 'nivel_1',
        fase: FaseSala.jugandoRondas,
        rondaActual: 1,
        segundosRestantes: 60,
        dado1: 3,
        dado2: 5,
        misValoresTablero: mapaTablero,
        jugadores: const [
          ResumenJugador(
            id: 'jug_1',
            apodo: 'Fabian',
            esAnfitrion: true,
            estaListo: true,
            participacion: EstadoParticipacion.conectado,
            puntuacion: 0,
          ),
        ],
      );

      final partidaBloc = PartidaMultijugadorBloc(
        repositorio: repoFake,
        salaInicial: salaInicial,
      );

      final msg = MensajeChat(
        id: 'msg_partida_1',
        codigoSala: 'TEST01',
        remitenteId: 'jug_1',
        remitenteApodo: 'Fabian',
        texto: 'Buena jugada',
        fecha: DateTime.now(),
      );

      repoFake.emitirMensajeChat(msg);

      await expectLater(
        partidaBloc.stream,
        emitsThrough(predicate<PartidaMultijugadorEstado>((e) {
          if (e is! PartidaMultijugadorActiva) return false;
          return e.historialChat.length == 1 && e.historialChat.first.texto == 'Buena jugada';
        })),
      );

      await partidaBloc.close();
    });
  });
}
