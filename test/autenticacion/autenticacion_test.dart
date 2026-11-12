import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brilliant/autenticacion/bloc/auth_bloc.dart';
import 'package:brilliant/autenticacion/bloc/auth_estado.dart';
import 'package:brilliant/autenticacion/bloc/auth_evento.dart';
import 'package:brilliant/autenticacion/dominio/repositorio_autenticacion.dart';
import 'package:brilliant/autenticacion/infraestructura/repositorio_autenticacion_local.dart';
import 'package:brilliant/autenticacion/vistas/pantalla_login.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RepositorioAutenticacionLocal', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Inicia sesión con usuario demo pre-sembrado', () async {
      final repo = RepositorioAutenticacionLocal();
      final user = await repo.iniciarSesion(
        identificador: 'fabian@brilliant.com',
        contrasena: 'password123',
      );

      expect(user.apodo, 'Fabian');
      expect(user.email, 'fabian@brilliant.com');

      final sesion = await repo.obtenerUsuarioSesion();
      expect(sesion?.id, user.id);
    });

    test('Registra un nuevo usuario y persiste la sesión', () async {
      final repo = RepositorioAutenticacionLocal();
      final nuevo = await repo.registrarUsuario(
        apodo: 'Carlos',
        email: 'carlos@test.com',
        contrasena: 'secreto123',
      );

      expect(nuevo.apodo, 'Carlos');
      expect(nuevo.email, 'carlos@test.com');

      // Puede iniciar sesión con su apodo
      final login = await repo.iniciarSesion(
        identificador: 'carlos',
        contrasena: 'secreto123',
      );
      expect(login.id, nuevo.id);

      // Cierre de sesión
      await repo.cerrarSesion();
      final sesion = await repo.obtenerUsuarioSesion();
      expect(sesion, isNull);
    });

    test('Rechaza contraseñas incorrectas y correos duplicados', () async {
      final repo = RepositorioAutenticacionLocal();
      await repo.registrarUsuario(
        apodo: 'Maria',
        email: 'maria@test.com',
        contrasena: 'clave123',
      );

      expect(
        () => repo.iniciarSesion(
          identificador: 'maria@test.com',
          contrasena: 'incorrecta',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );

      expect(
        () => repo.registrarUsuario(
          apodo: 'Maria2',
          email: 'maria@test.com',
          contrasena: 'clave123',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );
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

    test('IniciarSesionSolicitado emite AuthAutenticado con credenciales válidas', () async {
      final bloc = AuthBloc(repositorio: repo);
      bloc.add(const IniciarSesionSolicitado(
        identificador: 'fabian@brilliant.com',
        contrasena: 'password123',
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

    test('CerrarSesionSolicitado limpia el estado a AuthNoAutenticado', () async {
      final bloc = AuthBloc(repositorio: repo);
      bloc.add(const IniciarSesionSolicitado(
        identificador: 'fabian@brilliant.com',
        contrasena: 'password123',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          isA<AuthAutenticado>(),
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

      await bloc.close();
    });
  });

  group('PantallaLogin Widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Muestra pestañas de Iniciar Sesión y Registro', (tester) async {
      final repo = RepositorioAutenticacionLocal();
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
    });
  });
}
