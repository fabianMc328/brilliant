import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/autenticacion/dominio/usuario.dart';
import 'package:brilliant/multijugador/bloc/partida_multijugador_bloc.dart';
import 'package:brilliant/multijugador/dominio/estado_carrera_region.dart';
import 'package:brilliant/multijugador/dominio/estado_sala_multijugador.dart';
import 'package:brilliant/multijugador/dominio/estados_jugador_sala.dart';
import 'package:brilliant/multijugador/dominio/jugador_multijugador.dart';
import 'package:brilliant/multijugador/dominio/modelos_mapa.dart';
import 'package:brilliant/multijugador/infraestructura/repositorio_multijugador_fake.dart';
import 'package:brilliant/multijugador/vistas/pantalla_inicio_modo.dart';
import 'package:brilliant/multijugador/vistas/pantalla_lobby_multijugador.dart';
import 'package:brilliant/multijugador/vistas/pantalla_partida_multijugador.dart';
import 'package:brilliant/niveles/catalogo_niveles.dart';

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
    testWidgets('PantallaInicioModo muestra diseño nuevo y navega a Solitario y Multijugador',
        (tester) async {
      final repo = RepositorioMultijugadorFake();
      addTearDown(repo.cerrar);

      final usuario = Usuario(
        id: 'u1',
        apodo: 'Fabian',
        email: 'fabian@brilliant.com',
        fechaRegistro: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PantallaInicioModo(
            repositorioMultijugador: repo,
            usuarioAutenticado: usuario,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido, Fabian'), findsOneWidget);
      expect(find.text('Cómo jugar'), findsOneWidget);
      expect(find.text('Salir'), findsOneWidget);
      expect(find.text('Modos de juego'), findsOneWidget);
      expect(
        find.text('Juego de tablero y lógica de dados en regiones'),
        findsNothing,
      );
      expect(find.text('Modo Solitario'), findsOneWidget);
      expect(find.text('Multijugador (2 a 6 Jugadores)'), findsOneWidget);
      expect(
        find.text(
            'Crea o únete a salas con el código para competir con tus amigos.'),
        findsOneWidget,
      );

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

      // Abrir selector visual de mapa en Crear Sala y elegir Nivel 3
      await tester.tap(find.byKey(const Key('boton_seleccionar_mapa_crear')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialogo_selector_mapa')), findsOneWidget);
      expect(find.byKey(const Key('opcion_mapa_nivel_1')), findsOneWidget);
      expect(find.byKey(const Key('opcion_mapa_nivel_3')), findsOneWidget);
      await tester.tap(find.byKey(const Key('opcion_mapa_nivel_3')));
      await tester.pumpAndSettle();
      expect(find.text('Nivel 3 • Avanzado'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('campo_apodo_multijugador')),
        'Jugador1',
      );
      await tester.tap(find.byKey(const Key('boton_crear_sala')));
      await tester.pumpAndSettle();

      // Estamos en la sala con código ABC234 y 1/6 jugadores
      expect(find.byKey(const Key('texto_codigo_sala')), findsOneWidget);
      expect(find.text('ABC234'), findsOneWidget);

      // Cambiar mapa desde el Lobby con la ventana de selección
      await tester.tap(find.byKey(const Key('boton_seleccionar_mapa_lobby')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialogo_selector_mapa')), findsOneWidget);
      await tester.tap(find.byKey(const Key('opcion_mapa_nivel_2')));
      await tester.pumpAndSettle();
      expect(find.text('Mapa Compartido: Nivel 2'), findsOneWidget);

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

    testWidgets(
        'Muestra aviso central al completar región, nombres por lugar al pulsar tarjeta y puntos visibles',
        (tester) async {
      final repo = RepositorioMultijugadorFake();
      repo.emitirEstadoConexion(const EstadoConexionCliente.conectado());
      addTearDown(repo.cerrar);

      final primeraRegion = CatalogoNiveles.nivel1.regiones.first;
      final regionId = primeraRegion.id;
      final nombreRegionBonito = regionId.replaceAll('_', ' ');

      final salaInicial = EstadoSalaMultijugador(
        codigoSala: 'K7M4P9',
        miJugadorId: 'j1',
        fase: FaseSala.jugandoRondas,
        nivelId: 'nivel_1',
        rondaActual: 1,
        dado1: 4,
        dado2: 2,
        segundosRestantes: 50,
        metaPuntos: 20,
        jugadores: _crearSeisJugadores(todosListos: true),
      );

      final bloc = PartidaMultijugadorBloc(
        repositorio: repo,
        salaInicial: salaInicial,
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

      // Puntos visibles en formato "18 pts"
      expect(find.text('18 pts'), findsOneWidget);
      expect(find.text('15 pts'), findsOneWidget);

      // Jugador2 completa la primera región -> aparece aviso central no bloqueante
      repo.emitirEstadoSala(
        EstadoSalaMultijugador(
          codigoSala: 'K7M4P9',
          miJugadorId: 'j1',
          fase: FaseSala.jugandoRondas,
          nivelId: 'nivel_1',
          rondaActual: 2,
          dado1: 5,
          dado2: 1,
          segundosRestantes: 60,
          metaPuntos: 20,
          carreraPorRegion: {
            regionId: EstadoCarreraRegion(
              regionId: regionId,
              completadosPrevios: 1,
              idsJugadoresCompletaron: const ['j2'],
            ),
          },
          jugadores: _crearSeisJugadores(todosListos: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('aviso_central_region_completada')),
        findsOneWidget,
      );
      expect(
        find.text('¡Jugador2 completó $nombreRegionBonito!'),
        findsOneWidget,
      );

      // Tocar la tarjeta de color de esa región y ver el lugar + nombre del jugador
      await tester.tap(find.text(nombreRegionBonito));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('lista_completados_$regionId')), findsOneWidget);
      expect(find.text('1.º Lugar'), findsWidgets);
      expect(find.text('Jugador2'), findsWidgets);

      // Esperar a que termine el timer de 3s del aviso central
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets(
        'Solo el anfitrión ve Tirar Dados cuando esperandoTiroDados=true y acceso muestra IP sin campo manual',
        (tester) async {
      final repo = RepositorioMultijugadorFake();
      repo.configurarUrlServidor('ws://192.168.0.13:8080');
      repo.emitirEstadoConexion(const EstadoConexionCliente.conectado());
      addTearDown(repo.cerrar);

      // 1. VistaAccesoSala muestra mensaje "Conectado al servidor: 192.168.0.13" sin campo manual
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaLobbyMultijugador(repositorioExterno: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Conectado al servidor: 192.168.0.13'), findsOneWidget);
      expect(find.byKey(const Key('campo_url_servidor')), findsNothing);

      // 2. Anfitrión (j1) esperando tiro de dados -> ve botón Tirar Dados
      final blocHost = PartidaMultijugadorBloc(
        repositorio: repo,
        salaInicial: EstadoSalaMultijugador(
          codigoSala: 'K7M4P9',
          miJugadorId: 'j1',
          fase: FaseSala.jugandoRondas,
          nivelId: 'nivel_1',
          rondaActual: 1,
          esperandoTiroDados: true,
          jugadores: _crearSeisJugadores(todosListos: true),
        ),
      );
      addTearDown(blocHost.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: blocHost,
            child: const PantallaPartidaMultijugador(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('boton_tirar_dados_multi')), findsOneWidget);
      await tester.tap(find.byKey(const Key('boton_tirar_dados_multi')));
      await tester.pumpAndSettle();
      expect(repo.tirarDadosFueLlamado, isTrue);

      // 3. Invitado (j2) esperando tiro de dados -> NO ve botón, ve mensaje de espera
      final blocInvitado = PartidaMultijugadorBloc(
        repositorio: repo,
        salaInicial: EstadoSalaMultijugador(
          codigoSala: 'K7M4P9',
          miJugadorId: 'j2',
          fase: FaseSala.jugandoRondas,
          nivelId: 'nivel_1',
          rondaActual: 2,
          esperandoTiroDados: true,
          jugadores: _crearSeisJugadores(todosListos: true),
        ),
      );
      addTearDown(blocInvitado.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: blocInvitado,
            child: const PantallaPartidaMultijugador(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('boton_tirar_dados_multi')), findsNothing);
      expect(
        find.byKey(const Key('aviso_esperando_dados_anfitrion')),
        findsOneWidget,
      );
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
          MaterialApp(
            home: PantallaInicioModo(
              repositorioMultijugador: repo,
              usuarioAutenticado: Usuario(
                id: 'u1',
                apodo: 'Fabian',
                email: 'fabian@brilliant.com',
                fechaRegistro: DateTime(2026, 1, 1),
              ),
            ),
          ),
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

  group('Flujos UX corregidos (Persistencia de formulario y reconexión anfitrión)', () {
    testWidgets(
      'PantallaLobbyMultijugador conserva apodo y código si falla al unirse',
      (tester) async {
        final repo = RepositorioMultijugadorFake();
        addTearDown(repo.cerrar);

        await tester.pumpWidget(
          MaterialApp(
            home: PantallaLobbyMultijugador(
              repositorioExterno: repo,
              apodoInicial: 'Fabian',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('campo_codigo_invitacion')),
          'K7M4P9',
        );
        repo.proximoFalloSimulado = const FalloMultijugador(
          codigo: CodigoFalloMultijugador.salaNoEncontrada,
          mensaje: 'No se encontró ninguna sala con ese código.',
        );

        await tester.tap(find.byKey(const Key('boton_unirse_sala')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('alerta_error_lobby')), findsOneWidget);
        final campoApodo = tester.widget<TextField>(
          find.byKey(const Key('campo_apodo_multijugador')),
        );
        final campoCodigo = tester.widget<TextField>(
          find.byKey(const Key('campo_codigo_invitacion')),
        );
        expect(campoApodo.controller?.text, 'Fabian');
        expect(campoCodigo.controller?.text, 'K7M4P9');
      },
    );

    testWidgets(
      'Invitado ve aviso explícito si el anfitrión está reconectando al tirar dados',
      (tester) async {
        final repo = RepositorioMultijugadorFake();
        addTearDown(repo.cerrar);

        final bloc = PartidaMultijugadorBloc(
          repositorio: repo,
          salaInicial: const EstadoSalaMultijugador(
            codigoSala: 'K7M4P9',
            miJugadorId: 'j2',
            fase: FaseSala.jugandoRondas,
            nivelId: 'nivel_1',
            rondaActual: 2,
            esperandoTiroDados: true,
            jugadores: [
              ResumenJugador(
                id: 'j1',
                apodo: 'Fabian',
                esAnfitrion: true,
                estaListo: true,
                participacion: EstadoParticipacion.reconectando,
              ),
              ResumenJugador(
                id: 'j2',
                apodo: 'Invitado',
                esAnfitrion: false,
                estaListo: true,
                participacion: EstadoParticipacion.conectado,
              ),
            ],
          ),
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

        expect(
          find.textContaining('perdió conexión (esperando reconexión)'),
          findsWidgets,
        );

        // Actualiza contador en tiempo real cuando llegan segundosReconexionRestantes
        repo.emitirEstadoSala(
          const EstadoSalaMultijugador(
            codigoSala: 'K7M4P9',
            miJugadorId: 'j2',
            fase: FaseSala.jugandoRondas,
            nivelId: 'nivel_1',
            rondaActual: 2,
            esperandoTiroDados: true,
            mensajeEventoReciente:
                'Fabian se desconectó. Tiempo para reconectar: 27s',
            jugadores: [
              ResumenJugador(
                id: 'j1',
                apodo: 'Fabian',
                esAnfitrion: true,
                estaListo: true,
                participacion: EstadoParticipacion.reconectando,
                segundosReconexionRestantes: 27,
              ),
              ResumenJugador(
                id: 'j2',
                apodo: 'Invitado',
                esAnfitrion: false,
                estaListo: true,
                participacion: EstadoParticipacion.conectado,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('27s'), findsWidgets);
        expect(find.text('Reconectando (27s)'), findsOneWidget);
      },
    );

    testWidgets(
      'Al pulsar tarjeta de región se muestra el mapa con esa zona resaltada',
      (tester) async {
        final repo = RepositorioMultijugadorFake();
        addTearDown(repo.cerrar);

        final bloc = PartidaMultijugadorBloc(
          repositorio: repo,
          salaInicial: const EstadoSalaMultijugador(
            codigoSala: 'K7M4P9',
            miJugadorId: 'j1',
            fase: FaseSala.jugandoRondas,
            nivelId: 'nivel_1',
            rondaActual: 1,
            dado1: 2,
            dado2: 4,
            jugadores: [
              ResumenJugador(
                id: 'j1',
                apodo: 'Fabian',
                esAnfitrion: true,
                estaListo: true,
                participacion: EstadoParticipacion.conectado,
              ),
            ],
          ),
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

        // Pulsamos la tarjeta "verde 1" en el panel de carrera de regiones
        await tester.ensureVisible(find.text('verde 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('verde 1'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('mapa_region_resaltada_verde_1')),
          findsOneWidget,
        );
        expect(
          find.text('Ubicación de verde 1 en el mapa'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Abandonar partida tras pérdida definitiva de red cierra sin bloquearse en PopScope',
      (tester) async {
        final repo = RepositorioMultijugadorFake();
        addTearDown(repo.cerrar);

        final bloc = PartidaMultijugadorBloc(
          repositorio: repo,
          salaInicial: const EstadoSalaMultijugador(
            codigoSala: 'K7M4P9',
            miJugadorId: 'j1',
            fase: FaseSala.jugandoRondas,
            nivelId: 'nivel_1',
            rondaActual: 2,
            dado1: 2,
            dado2: 4,
            jugadores: [
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
          ),
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  key: const Key('abrir_multi_pop'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: const PantallaPartidaMultijugador(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('abrir_multi_pop')));
        await tester.pumpAndSettle();

        repo.emitirEstadoConexion(
          const EstadoConexionCliente.perdidaDefinitiva('Red caída'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salir'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('abrir_multi_pop')), findsOneWidget);
      },
    );
  });
}
