import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brilliant/autenticacion/bloc/auth_bloc.dart';
import 'package:brilliant/autenticacion/bloc/auth_estado.dart';
import 'package:brilliant/autenticacion/bloc/auth_evento.dart';
import 'package:brilliant/autenticacion/dominio/repositorio_autenticacion.dart';
import 'package:brilliant/autenticacion/dominio/validador_auth.dart';
import 'package:brilliant/autenticacion/infraestructura/cliente_http_auth.dart';
import 'package:brilliant/autenticacion/infraestructura/repositorio_autenticacion_local.dart';
import 'package:brilliant/autenticacion/infraestructura/repositorio_autenticacion_servidor.dart';
import 'package:brilliant/autenticacion/vistas/pantalla_login.dart';
import 'package:brilliant/main.dart';

class _ClienteHttpAuthSimulado extends ClienteHttpAuth {
  final Map<String, Map<String, dynamic>> _porApodo = {};
  final Map<String, Map<String, dynamic>> _porEmail = {};
  final Map<String, String> _usuarioPorToken = {};
  final Map<String, String> _dispositivoPorUsuario = {};
  int _seq = 0;

  void limpiarServidorSimulado() {
    _porApodo.clear();
    _porEmail.clear();
    _usuarioPorToken.clear();
    _dispositivoPorUsuario.clear();
  }

  @override
  Future<RespuestaHttpAuth> enviar({
    required String metodo,
    required String urlWsOBaseHttp,
    required String ruta,
    Map<String, dynamic>? cuerpoJson,
    String? bearerToken,
    Duration? timeout,
  }) async {
    final body = cuerpoJson ?? const <String, dynamic>{};

    if (ruta == '/auth/registro' && metodo == 'POST') {
      final apodo = (body['apodo'] as String? ?? '').trim();
      final email = (body['email'] as String? ?? '').trim().toLowerCase();
      final disp = (body['dispositivoId'] as String? ?? '').trim();
      final clave = ValidadorAuth.normalizarApodoClave(apodo);

      if (_porApodo.containsKey(clave)) {
        return RespuestaHttpAuth(
          statusCode: 409,
          datos: {
            'error': 'El apodo "$apodo" ya está registrado. Elige otro nombre.',
            'codigo': 'APODO_EN_USO',
          },
        );
      }
      if (_porEmail.containsKey(email)) {
        return const RespuestaHttpAuth(
          statusCode: 409,
          datos: {
            'error': 'El correo electrónico ya está registrado.',
            'codigo': 'EMAIL_EN_USO',
          },
        );
      }

      _seq += 1;
      final uid = 'usr_$_seq';
      final usuario = {
        'id': uid,
        'apodo': apodo,
        'email': email,
        'fechaRegistro': DateTime.utc(2026, 1, 1).toIso8601String(),
      };
      _porApodo[clave] = {...usuario, 'pass': body['contrasena']};
      _porEmail[email] = _porApodo[clave]!;
      final token = 'tok_$_seq';
      _usuarioPorToken[token] = uid;
      if (disp.isNotEmpty) {
        _dispositivoPorUsuario[uid] = disp;
      }

      return RespuestaHttpAuth(
        statusCode: 201,
        datos: {'usuario': usuario, 'token': token},
      );
    }

    if (ruta == '/auth/login' && metodo == 'POST') {
      final id = (body['identificador'] as String? ?? '').trim();
      final disp = (body['dispositivoId'] as String? ?? '').trim();
      final found = id.contains('@')
          ? _porEmail[id.toLowerCase()]
          : _porApodo[ValidadorAuth.normalizarApodoClave(id)];
      if (found == null || found['pass'] != body['contrasena']) {
        return const RespuestaHttpAuth(
          statusCode: 401,
          datos: {'error': 'Credenciales inválidas.'},
        );
      }

      final uid = found['id'] as String;
      final tieneSesionActiva = _usuarioPorToken.values.contains(uid);
      final dispActivo = _dispositivoPorUsuario[uid];
      if (tieneSesionActiva && (disp.isEmpty || dispActivo != disp)) {
        return const RespuestaHttpAuth(
          statusCode: 409,
          datos: {
            'error':
                'Esta cuenta ya está conectada en otro dispositivo. Cierra sesión allá antes de entrar.',
            'codigo': 'SESION_YA_ACTIVA',
          },
        );
      }

      _usuarioPorToken.removeWhere((_, v) => v == uid);
      final token = 'tok_login_${++_seq}';
      _usuarioPorToken[token] = uid;
      if (disp.isNotEmpty) {
        _dispositivoPorUsuario[uid] = disp;
      }
      return RespuestaHttpAuth(
        statusCode: 200,
        datos: {'usuario': found, 'token': token},
      );
    }

    if (ruta.startsWith('/auth/sesion') && metodo == 'GET') {
      final uid = bearerToken == null ? null : _usuarioPorToken[bearerToken];
      if (uid == null) {
        return const RespuestaHttpAuth(
          statusCode: 401,
          datos: {'error': 'Sesión expirada o no válida.'},
        );
      }
      final uriRuta = Uri.parse(ruta);
      final dispQuery = uriRuta.queryParameters['dispositivoId']?.trim();
      final dispDueno = _dispositivoPorUsuario[uid];
      if (dispQuery != null &&
          dispQuery.isNotEmpty &&
          dispDueno != null &&
          dispDueno != dispQuery) {
        return const RespuestaHttpAuth(
          statusCode: 409,
          datos: {
            'error':
                'La cuenta ya está conectada en otra pestaña o dispositivo.',
            'codigo': 'SESION_YA_ACTIVA',
          },
        );
      }
      final found = _porApodo.values.firstWhere((u) => u['id'] == uid);
      return RespuestaHttpAuth(
        statusCode: 200,
        datos: {'usuario': found},
      );
    }

    if (ruta == '/auth/logout' && metodo == 'POST') {
      if (bearerToken != null) {
        final uid = _usuarioPorToken.remove(bearerToken);
        if (uid != null) {
          _dispositivoPorUsuario.remove(uid);
        }
      }
      return const RespuestaHttpAuth(statusCode: 200, datos: {'ok': true});
    }

    return const RespuestaHttpAuth(
      statusCode: 404,
      datos: {'error': 'Ruta no encontrada.'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ValidadorAuth', () {
    test('Normaliza clave de apodo sin distinguir mayúsculas, espacios ni acentos', () {
      expect(ValidadorAuth.normalizarApodoClave('  Fabian '), 'fabian');
      expect(ValidadorAuth.normalizarApodoClave('Fabián'), 'fabian');
      expect(ValidadorAuth.normalizarApodoClave('EL  PRO'), 'el pro');
      expect(ValidadorAuth.normalizarApodoClave('Peña'), 'peña');
    });

    test('construirUriHttpAuth convierte wss/ws a https/http correctamente para Web y móvil', () {
      expect(
        construirUriHttpAuth(
          'wss://servidorbrilliant.onrender.com',
          '/auth/registro',
        ).toString(),
        'https://servidorbrilliant.onrender.com/auth/registro',
      );
      expect(
        construirUriHttpAuth(
          'ws://127.0.0.1:8080',
          'auth/login',
        ).toString(),
        'http://127.0.0.1:8080/auth/login',
      );
    });
  });

  group('RepositorioAutenticacionLocal', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Permite registrar el primer usuario con su apodo real y rechaza duplicados', () async {
      final repo = RepositorioAutenticacionLocal();
      final fabian = await repo.registrarUsuario(
        apodo: 'Fabian',
        email: 'fabian@correo.com',
        contrasena: 'contraseña123',
      );

      expect(fabian.apodo, 'Fabian');
      expect(fabian.email, 'fabian@correo.com');

      // Apodo idéntico o distinto solo por mayúsculas / acento -> rechazado
      await expectLater(
        repo.registrarUsuario(
          apodo: 'fabian',
          email: 'otro@correo.com',
          contrasena: 'clave123',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );
      await expectLater(
        repo.registrarUsuario(
          apodo: 'Fabián',
          email: 'otro2@correo.com',
          contrasena: 'clave123',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );

      // Correo duplicado -> rechazado
      await expectLater(
        repo.registrarUsuario(
          apodo: 'OtroJugador',
          email: 'FABIAN@CORREO.COM',
          contrasena: 'clave123',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );
    });

    test('Rechaza espacios en contraseña, correo inválido y apodos inválidos', () async {
      final repo = RepositorioAutenticacionLocal();
      await repo.registrarUsuario(
        apodo: 'Fabian',
        email: 'fabian@brilliant.com',
        contrasena: 'contraseña123',
      );

      // Contraseña con espacios en login
      await expectLater(
        repo.iniciarSesion(
          identificador: 'fabian@brilliant.com',
          contrasena: 'contra seña123',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );

      // Contraseña con espacios en registro
      await expectLater(
        repo.registrarUsuario(
          apodo: 'Luis',
          email: 'luis@test.com',
          contrasena: ' clave123',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );

      // Correo con espacios en registro
      await expectLater(
        repo.registrarUsuario(
          apodo: 'Luis',
          email: 'lu is@test.com',
          contrasena: 'clave123',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );

      // Apodo con solo espacios o símbolo @
      await expectLater(
        repo.registrarUsuario(
          apodo: '   ',
          email: 'luis@test.com',
          contrasena: 'clave123',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );
      await expectLater(
        repo.registrarUsuario(
          apodo: 'luis@pro',
          email: 'luis@test.com',
          contrasena: 'clave123',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );

      // Identificador con espacios al inicio/fin pero válido sí hace trim
      final user = await repo.iniciarSesion(
        identificador: '  fabian@brilliant.com  ',
        contrasena: 'contraseña123',
      );
      expect(user.apodo, 'Fabian');
    });

    test('Inicia sesión con apodo o correo, persiste sesión y cierra sesión', () async {
      final repo = RepositorioAutenticacionLocal();
      final nuevo = await repo.registrarUsuario(
        apodo: 'Carlos',
        email: 'carlos@test.com',
        contrasena: 'secreto123',
      );

      expect(nuevo.apodo, 'Carlos');
      expect(nuevo.email, 'carlos@test.com');

      // Puede iniciar sesión con su apodo en minúsculas
      final login = await repo.iniciarSesion(
        identificador: 'carlos',
        contrasena: 'secreto123',
      );
      expect(login.id, nuevo.id);

      final sesion = await repo.obtenerUsuarioSesion();
      expect(sesion?.id, nuevo.id);

      // Contraseña incorrecta
      await expectLater(
        repo.iniciarSesion(
          identificador: 'carlos@test.com',
          contrasena: 'incorrecta',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );

      // Cierre de sesión
      await repo.cerrarSesion();
      final trasSalida = await repo.obtenerUsuarioSesion();
      expect(trasSalida, isNull);
    });
  });

  group('RepositorioAutenticacionServidor (unificación y sesión única entre dispositivos)', () {
    test('Impide registrar apodos iguales, bloquea doble login simultáneo y valida sesión con el servidor', () async {
      final clienteCompartido = _ClienteHttpAuthSimulado();
      const urlServidor = 'wss://servidorbrilliant.onrender.com';

      // Dispositivo 1 (Celular)
      SharedPreferences.setMockInitialValues({
        'brilliant_dispositivo_id_v1': 'disp_celular_1',
      });
      final prefsCel = await SharedPreferences.getInstance();
      final repoCel = RepositorioAutenticacionServidor(
        preferences: prefsCel,
        resolverUrlServidor: () async => urlServidor,
        clienteHttp: clienteCompartido,
      );

      final userCel = await repoCel.registrarUsuario(
        apodo: 'Fabian',
        email: 'cel@correo.com',
        contrasena: 'clave123',
      );
      expect(userCel.apodo, 'Fabian');

      // Dispositivo 2 (Página Web / PC con otro dispositivoId)
      SharedPreferences.setMockInitialValues({
        'brilliant_dispositivo_id_v1': 'disp_web_2',
      });
      final prefsWeb = await SharedPreferences.getInstance();
      final repoWeb = RepositorioAutenticacionServidor(
        preferences: prefsWeb,
        resolverUrlServidor: () async => urlServidor,
        clienteHttp: clienteCompartido,
      );

      // 1. No permite registrar usuario igual en el segundo dispositivo
      await expectLater(
        repoWeb.registrarUsuario(
          apodo: 'fabian',
          email: 'web@correo.com',
          contrasena: 'clave123',
        ),
        throwsA(
          predicate<FalloAutenticacion>(
            (e) => e.mensaje.contains('ya está registrado'),
          ),
        ),
      );

      // 2. Tampoco permite iniciar sesión con la misma cuenta mientras el celular sigue conectado
      await expectLater(
        repoWeb.iniciarSesion(
          identificador: 'Fabian',
          contrasena: 'clave123',
        ),
        throwsA(
          predicate<FalloAutenticacion>(
            (e) => e.mensaje.contains('ya está conectada en otro dispositivo'),
          ),
        ),
      );

      // 3. Si el primer dispositivo cierra sesión, el segundo dispositivo ya puede entrar
      await repoCel.cerrarSesion();
      final userWeb = await repoWeb.iniciarSesion(
        identificador: 'Fabian',
        contrasena: 'clave123',
      );
      expect(userWeb.apodo, 'Fabian');

      // 4. obtenerUsuarioSesion verifica contra /auth/sesion del servidor
      final sesionVerificada = await repoWeb.obtenerUsuarioSesion();
      expect(sesionVerificada?.apodo, 'Fabian');

      // 5. Si el servidor se reinicia o revoca la sesión (401), obtenerUsuarioSesion limpia la sesión fantasma local
      clienteCompartido.limpiarServidorSimulado();
      expect(await repoWeb.obtenerUsuarioSesion(), isNull);
    });
  });

  group('AuthBloc', () {
    late RepositorioAutenticacionLocal repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = RepositorioAutenticacionLocal();
    });

    test('ComprobarSesionInicial arranca no autenticado cuando no hay sesión', () async {
      final bloc = AuthBloc(repositorio: repo);
      bloc.add(const ComprobarSesionInicial());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          isA<AuthNoAutenticado>(),
        ]),
      );

      await bloc.close();
    });

    test('RegistrarUsuarioSolicitado y IniciarSesionSolicitado emiten AuthAutenticado', () async {
      final bloc = AuthBloc(repositorio: repo);
      bloc.add(const RegistrarUsuarioSolicitado(
        apodo: 'Fabian',
        email: 'fabian@brilliant.com',
        contrasena: 'contraseña123',
        confirmacionContrasena: 'contraseña123',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          predicate<AuthAutenticado>((estado) => estado.usuario.apodo == 'Fabian'),
        ]),
      );

      bloc.add(const CerrarSesionSolicitado());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          isA<AuthNoAutenticado>(),
        ]),
      );

      bloc.add(const IniciarSesionSolicitado(
        identificador: 'Fabian',
        contrasena: 'contraseña123',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          predicate<AuthAutenticado>((estado) => estado.usuario.apodo == 'Fabian'),
        ]),
      );

      await bloc.close();
    });
  });

  group('PantallaLogin Widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Muestra pestañas de Iniciar Sesión y Registro, valida campos y rechaza apodo repetido', (tester) async {
      final repo = RepositorioAutenticacionLocal();
      await repo.registrarUsuario(
        apodo: 'Fabian',
        email: 'fabian@brilliant.com',
        contrasena: 'contraseña123',
      );
      await repo.cerrarSesion();

      final bloc = AuthBloc(repositorio: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const PantallaLogin(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Iniciar Sesión'), findsWidgets);
      expect(find.text('Registrarse'), findsWidgets);
      expect(find.byKey(const Key('input_login_usuario')), findsOneWidget);
      expect(find.byKey(const Key('input_login_password')), findsOneWidget);
      expect(find.byKey(const Key('boton_iniciar_sesion')), findsOneWidget);

      final campoUsuario = tester.widget<TextFormField>(
        find.byKey(const Key('input_login_usuario')),
      );
      final campoPassword = tester.widget<TextFormField>(
        find.byKey(const Key('input_login_password')),
      );
      expect(campoUsuario.controller?.text, isEmpty);
      expect(campoPassword.controller?.text, isEmpty);
      expect(find.textContaining('contraseña123'), findsNothing);

      // Validar rechazo visual de espacios en contraseña
      await tester.enterText(find.byKey(const Key('input_login_password')), 'clave 123');
      await tester.pumpAndSettle();
      expect(find.text('La contraseña no puede contener espacios'), findsOneWidget);

      // Cambiar a pestaña Registrarse e intentar registrar un apodo ya tomado
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('input_registro_apodo')), 'fabian');
      await tester.enterText(find.byKey(const Key('input_registro_email')), 'nuevo@test.com');
      await tester.enterText(find.byKey(const Key('input_registro_password')), 'clave1234');
      await tester.enterText(find.byKey(const Key('input_registro_confirm_password')), 'clave1234');
      await tester.ensureVisible(find.byKey(const Key('boton_crear_cuenta')));
      await tester.tap(find.byKey(const Key('boton_crear_cuenta')));
      await tester.pumpAndSettle();

      expect(find.textContaining('ya está en uso'), findsOneWidget);
    });

    testWidgets('AplicacionBrilliant mantiene PantallaLogin montada ante error de cuenta ya conectada o duplicada', (tester) async {
      final cliente = _ClienteHttpAuthSimulado();
      const urlServidor = 'wss://servidorbrilliant.onrender.com';

      SharedPreferences.setMockInitialValues({
        'brilliant_dispositivo_id_v1': 'disp_1',
      });
      final prefs1 = await SharedPreferences.getInstance();
      final repo1 = RepositorioAutenticacionServidor(
        preferences: prefs1,
        resolverUrlServidor: () async => urlServidor,
        clienteHttp: cliente,
      );
      await repo1.registrarUsuario(
        apodo: 'Fabian',
        email: 'fabian@brilliant.com',
        contrasena: 'contraseña123',
      );

      // Segundo dispositivo intenta entrar con la cuenta que ya está conectada en disp_1
      SharedPreferences.setMockInitialValues({
        'brilliant_dispositivo_id_v1': 'disp_2',
      });
      final prefs2 = await SharedPreferences.getInstance();
      final repo2 = RepositorioAutenticacionServidor(
        preferences: prefs2,
        resolverUrlServidor: () async => urlServidor,
        clienteHttp: cliente,
      );

      await tester.pumpWidget(AplicacionBrilliant(repositorioAuth: repo2));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('input_login_usuario')),
        'Fabian',
      );
      await tester.enterText(
        find.byKey(const Key('input_login_password')),
        'contraseña123',
      );
      await tester.tap(find.byKey(const Key('boton_iniciar_sesion')));
      await tester.pumpAndSettle();

      // No lo deja entrar, muestra el error y conserva el texto escrito en PantallaLogin
      expect(
        find.textContaining('ya está conectada en otro dispositivo'),
        findsOneWidget,
      );
      final campoUsuario = tester.widget<TextFormField>(
        find.byKey(const Key('input_login_usuario')),
      );
      expect(campoUsuario.controller?.text, 'Fabian');
    });
  });
}
