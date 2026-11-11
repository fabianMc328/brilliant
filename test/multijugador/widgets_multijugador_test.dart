import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/multijugador/bloc/partida_multijugador_bloc.dart';
import 'package:brilliant/multijugador/dominio/estado_sala_multijugador.dart';
import 'package:brilliant/multijugador/dominio/estados_jugador_sala.dart';
import 'package:brilliant/multijugador/dominio/jugador_multijugador.dart';
import 'package:brilliant/multijugador/dominio/modelos_mapa.dart';
import 'package:brilliant/multijugador/infraestructura/repositorio_multijugador_fake.dart';
import 'package:brilliant/multijugador/vistas/pantalla_inicio_modo.dart';
import 'package:brilliant/multijugador/vistas/pantalla_lobby_multijugador.dart';
import 'package:brilliant/multijugador/vistas/pantalla_partida_multijugador.dart';

List<ResumenJugador> _crearSeisJugadores({required bool todosListos}) {
  return List.generate(
    6,
    (i) => ResumenJugador(
      id: 'j${i + 1}',
      apodo: 'Jugador${i + 1}',
      esAnfitrion: i == 0,
      estaListo: todosListos,
      participacion: EstadoParticipacion.conectado,
      puntuacion: (6 - i) * 3,
      regionesCompletadas: i % 3,
    ),
  );
}

void main() {
  group('Pantallas y Widgets Multijugador', () {
    testWidgets('PantallaInicioModo navega a Solitario y a Multijugador',
        (tester) async {
      final repo = RepositorioMultijugadorFake();
      addTearDown(repo.cerrar);

      await tester.pumpWidget(
        MaterialApp(
          home: PantallaInicioModo(repositorioMultijugador: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modo Solitario'), findsOneWidget);
      expect(find.text('Multijugador (2 a 6 Jugadores)'), findsOneWidget);

      // Navega a Modo Solitario y regresa
      await tester.tap(find.byKey(const Key('boton_modo_solitario')));
      await tester.pumpAndSettle();
      expect(find.text('Selecciona tu Tablero'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Navega a Multijugador
      await tester.tap(find.byKey(const Key('boton_modo_multijugador')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('campo_apodo_multijugador')), findsOneWidget);
      expect(find.byKey(const Key('campo_codigo_invitacion')), findsOneWidget);
    });

    testWidgets(
        'Lobby muestra código de invitación, 6 espacios, botón Listo y arranca al estar todos listos',
        (tester) async {
      final repo = RepositorioMultijugadorFake();
      addTearDown(repo.cerrar);

      await tester.pumpWidget(
        MaterialApp(
          home: PantallaLobbyMultijugador(repositorioExterno: repo),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('campo_apodo_multijugador')),
        'Jugador1',
      );
      await tester.tap(find.byKey(const Key('boton_crear_sala')));
      await tester.pumpAndSettle();

      // Estamos en la sala con código ABC234 y 1/6 jugadores
      expect(find.byKey(const Key('texto_codigo_sala')), findsOneWidget);
      expect(find.text('ABC234'), findsOneWidget);

      // Con 1 solo jugador, Comenzar Partida está deshabilitado
      final btnIniciarSolo = tester.widget<ElevatedButton>(
        find.byKey(const Key('boton_iniciar_partida_multi')),
      );
      expect(btnIniciarSolo.onPressed, isNull);

      // Llegan 6 jugadores y los 6 dan Listo
      repo.emitirEstadoSala(
        EstadoSalaMultijugador(
          codigoSala: 'ABC234',
          miJugadorId: 'j1',
          fase: FaseSala.enLobby,
          nivelId: 'nivel_1',
          jugadores: _crearSeisJugadores(todosListos: true),
        ),
      );
      await tester.pumpAndSettle();

      final btnIniciarListos = tester.widget<ElevatedButton>(
        find.byKey(const Key('boton_iniciar_partida_multi')),
      );
      expect(btnIniciarListos.onPressed, isNotNull);

      // Al iniciar partida, navega a PantallaPartidaMultijugador en Fase Inicial
      await tester.tap(find.byKey(const Key('boton_iniciar_partida_multi')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('boton_confirmar_estrellas_multi')),
        findsOneWidget,
      );
    });

    testWidgets(
        'Partida multijugador muestra banner de desconexión, diálogo de conceder y podio final',
        (tester) async {
      final repo = RepositorioMultijugadorFake();
      repo.emitirEstadoConexion(const EstadoConexionCliente.conectado());
      addTearDown(repo.cerrar);

      final salaEnRonda = EstadoSalaMultijugador(
        codigoSala: 'K7M4P9',
        miJugadorId: 'j1',
        fase: FaseSala.jugandoRondas,
        nivelId: 'nivel_1',
        rondaActual: 3,
        dado1: 4,
        dado2: 2,
        segundosRestantes: 35,
        metaPuntos: 20,
        misValoresTablero: {const PosicionMapa(1, 2): 4},
        jugadores: _crearSeisJugadores(todosListos: true),
      );

      final bloc = PartidaMultijugadorBloc(
        repositorio: repo,
        salaInicial: salaEnRonda,
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const PantallaPartidaMultijugador(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('multi_dado_1')), findsOneWidget);
      expect(find.byKey(const Key('barra_marcador_jugadores')), findsOneWidget);

      // Simular reconexión en curso -> aparece banner_reconectando (con spinner animado, usar pump)
      repo.emitirEstadoConexion(
        const EstadoConexionCliente.reconectando(
          intentoActual: 2,
          maxIntentos: 5,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('banner_reconectando')), findsOneWidget);

      // Restablecer conexión
      repo.emitirEstadoConexion(const EstadoConexionCliente.conectado());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_reconectando')), findsNothing);

      // Tocar Conceder y confirmar en el diálogo
      await tester.tap(find.byKey(const Key('boton_conceder_partida')));
      await tester.pumpAndSettle();
      expect(find.text('¿Conceder partida?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('boton_confirmar_conceder')));
      await tester.pumpAndSettle();
      expect(repo.concederFueLlamado, isTrue);

      // Al finalizar la partida, muestra el podio con la clasificación de los 6 jugadores
      repo.emitirEstadoSala(
        EstadoSalaMultijugador(
          codigoSala: 'K7M4P9',
          miJugadorId: 'j1',
          fase: FaseSala.finalizada,
          nivelId: 'nivel_1',
          metaPuntos: 20,
          ganadoresIds: const ['j1'],
          motivoFin: MotivoFinPartida.metaPuntosAlcanzada,
          jugadores: _crearSeisJugadores(todosListos: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vista_podio_multijugador')), findsOneWidget);
      expect(find.text('¡Victoria Brillante!'), findsOneWidget);
    });
  });

  group('Responsividad Móvil Multijugador (320x480 a 412x915)', () {
    final dimensiones = [
      const Size(320, 480),
      const Size(360, 640),
      const Size(375, 667),
      const Size(390, 844),
      const Size(412, 915),
    ];

    for (final dim in dimensiones) {
      testWidgets(
          'Cero desbordamientos multijugador en ${dim.width}x${dim.height}',
          (tester) async {
        tester.view.physicalSize = dim;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = RepositorioMultijugadorFake();
        addTearDown(repo.cerrar);

        // 1. PantallaInicioModo
        await tester.pumpWidget(
          MaterialApp(home: PantallaInicioModo(repositorioMultijugador: repo)),
        );
        await tester.pumpAndSettle();

        // 2. PantallaLobbyMultijugador (Acceso + Sala de 6 jugadores)
        await tester.pumpWidget(
          MaterialApp(
            home: PantallaLobbyMultijugador(repositorioExterno: repo),
          ),
        );
        await tester.pumpAndSettle();

        repo.emitirEstadoConexion(const EstadoConexionCliente.conectado());
        repo.emitirEstadoSala(
          EstadoSalaMultijugador(
            codigoSala: 'M9P4X2',
            miJugadorId: 'j1',
            fase: FaseSala.enLobby,
            nivelId: 'nivel_4',
            jugadores: _crearSeisJugadores(todosListos: false),
          ),
        );
        await tester.pumpAndSettle();

        // 3. Partida Multijugador (Fase Estrellas -> Fase Rondas con 6 jugadores -> Podio)
        final salaFase1 = EstadoSalaMultijugador(
          codigoSala: 'M9P4X2',
          miJugadorId: 'j1',
          fase: FaseSala.configurandoIniciales,
          nivelId: 'nivel_4',
          segundosRestantes: 50,
          metaPuntos: 20,
          jugadores: _crearSeisJugadores(todosListos: true),
        );
        final bloc = PartidaMultijugadorBloc(
          repositorio: repo,
          salaInicial: salaFase1,
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const PantallaPartidaMultijugador(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        repo.emitirEstadoSala(
          EstadoSalaMultijugador(
            codigoSala: 'M9P4X2',
            miJugadorId: 'j1',
            fase: FaseSala.jugandoRondas,
            nivelId: 'nivel_4',
            rondaActual: 2,
            dado1: 5,
            dado2: 3,
            segundosRestantes: 25,
            metaPuntos: 20,
            misValoresTablero: {const PosicionMapa(0, 4): 5},
            jugadores: _crearSeisJugadores(todosListos: true),
          ),
        );
        await tester.pumpAndSettle();

        repo.emitirEstadoSala(
          EstadoSalaMultijugador(
            codigoSala: 'M9P4X2',
            miJugadorId: 'j1',
            fase: FaseSala.finalizada,
            nivelId: 'nivel_4',
            metaPuntos: 20,
            ganadoresIds: const ['j1', 'j2'],
            motivoFin: MotivoFinPartida.metaPuntosAlcanzada,
            jugadores: _crearSeisJugadores(todosListos: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vista_podio_multijugador')), findsOneWidget);
      });
    }
  });
}
