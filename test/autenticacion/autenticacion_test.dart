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

class _ClienteHttpAuthSimulado extends ClienteHttpAuth {
  final Map<String, Map<String, dynamic>> _porApodo = {};
  final Map<String, Map<String, dynamic>> _porEmail = {};
  final Set<String> _tokensActivos = {};
  int _seq = 0;

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
      final usuario = {
        'id': 'usr_$_seq',
        'apodo': apodo,
        'email': email,
        'fechaRegistro': DateTime.utc(2026, 1, 1).toIso8601String(),
      };
      _porApodo[clave] = {...usuario, 'pass': body['contrasena']};
      _porEmail[email] = _porApodo[clave]!;
      final token = 'tok_$_seq';
      _tokensActivos.add(token);

      return RespuestaHttpAuth(
        statusCode: 201,
        datos: {'usuario': usuario, 'token': token},
      );
    }

    if (ruta == '/auth/login' && metodo == 'POST') {
      final id = (body['identificador'] as String? ?? '').trim();
      final found = id.contains('@')
          ? _porEmail[id.toLowerCase()]
          : _porApodo[ValidadorAuth.normalizarApodoClave(id)];
      if (found == null || found['pass'] != body['contrasena']) {
        return const RespuestaHttpAuth(
          statusCode: 401,
          datos: {'error': 'Credenciales inválidas.'},
        );
      }
      final token = 'tok_login_${++_seq}';
      _tokensActivos.add(token);
      return RespuestaHttpAuth(
        statusCode: 200,
        datos: {'usuario': found, 'token': token},
      );
    }

    if (ruta == '/auth/logout' && metodo == 'POST') {
      if (bearerToken != null) {
        _tokensActivos.remove(bearerToken);
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

  group('RepositorioAutenticacionServidor (unificación entre dispositivos)', () {
    test('Impide que dos dispositivos registren el mismo apodo contra el servidor HTTP', () async {
      final clienteCompartido = _ClienteHttpAuthSimulado();
      const urlServidor = 'wss://servidorbrilliant.onrender.com';

      // Dispositivo 1 (PC)
      SharedPreferences.setMockInitialValues({});
      final prefsPc = await SharedPreferences.getInstance();
      final repoPc = RepositorioAutenticacionServidor(
        preferences: prefsPc,
        resolverUrlServidor: () async => urlServidor,
        clienteHttp: clienteCompartido,
      );

      final userPc = await repoPc.registrarUsuario(
        apodo: 'Fabian',
        email: 'pc@correo.com',
        contrasena: 'clavePC123',
      );
      expect(userPc.apodo, 'Fabian');

      // Dispositivo 2 (Celular intentando registrar el mismo apodo con distinto correo)
      SharedPreferences.setMockInitialValues({});
      final prefsCel = await SharedPreferences.getInstance();
      final repoCel = RepositorioAutenticacionServidor(
        preferences: prefsCel,
        resolverUrlServidor: () async => urlServidor,
        clienteHttp: clienteCompartido,
      );

      await expectLater(
        repoCel.registrarUsuario(
          apodo: 'fabian',
          email: 'cel@correo.com',
          contrasena: 'claveCel123',
        ),
        throwsA(
          predicate<FalloAutenticacion>(
            (e) => e.mensaje.contains('ya está registrado'),
          ),
        ),
      );

      // Con otro apodo único sí registra en Celular
      final userCel = await repoCel.registrarUsuario(
        apodo: 'InvitadoPro',
        email: 'cel@correo.com',
        contrasena: 'claveCel123',
      );
      expect(userCel.apodo, 'InvitadoPro');

      // Sesión persistida funciona y cierra limpio
      final sesion = await repoCel.obtenerUsuarioSesion();
      expect(sesion?.apodo, 'InvitadoPro');
      await repoCel.cerrarSesion();
      expect(await repoCel.obtenerUsuarioSesion(), isNull);
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
  });
}
