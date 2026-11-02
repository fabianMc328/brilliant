import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/auth/bloc/auth_bloc.dart';
import 'package:brilliant/auth/bloc/auth_estado.dart';
import 'package:brilliant/auth/modelos/usuario_sesion.dart';
import 'package:brilliant/auth/repositorio/auth_repositorio.dart';
import 'package:brilliant/auth/vistas/auth_guard.dart';
import 'package:brilliant/auth/vistas/dialogo_eliminar_cuenta.dart';
import 'package:brilliant/auth/vistas/pantalla_login.dart';
import 'package:brilliant/auth/vistas/pantalla_registro.dart';
import 'package:brilliant/pantalla_seleccion_nivel.dart';

class MockAuthRepoParaVistas implements AuthRepositorio {
  UsuarioSesion? sesion;
  bool simularFallo = false;

  @override
  Future<UsuarioSesion> registrar({required String email, required String password}) async {
    sesion = UsuarioSesion(id: 'usr_reg', email: email, token: 'tok_reg');
    return sesion!;
  }

  @override
  Future<UsuarioSesion> iniciarSesion({required String email, required String password}) async {
    if (simularFallo) throw const AuthClienteException('Credenciales inválidas.');
    sesion = UsuarioSesion(id: 'usr_log', email: email, token: 'tok_log');
    return sesion!;
  }

  @override
  Future<UsuarioSesion?> obtenerSesionActual() async => sesion;

  @override
  Future<void> cerrarSesion() async => sesion = null;

  @override
  Future<void> eliminarCuenta({required String passwordConfirmacion}) async => sesion = null;
}

void main() {
  group('Vistas de Autenticación', () {
    late MockAuthRepoParaVistas mockRepo;
    late AuthBloc authBloc;

    setUp(() {
      mockRepo = MockAuthRepoParaVistas();
      authBloc = AuthBloc(authRepositorio: mockRepo);
    });

    tearDown(() {
      authBloc.close();
    });

    Widget crearEntorno(Widget widget) {
      return MaterialApp(
        home: BlocProvider.value(
          value: authBloc,
          child: widget,
        ),
      );
    }

    testWidgets('PantallaLogin muestra campos y botones de login y registro', (tester) async {
      await tester.pumpWidget(crearEntorno(const PantallaLogin()));
      await tester.pumpAndSettle();

      expect(find.text('Brilliant'), findsOneWidget);
      expect(find.byKey(const Key('input_login_email')), findsOneWidget);
      expect(find.byKey(const Key('input_login_password')), findsOneWidget);
      expect(find.byKey(const Key('btn_enviar_login')), findsOneWidget);
      expect(find.byKey(const Key('btn_ir_a_registro')), findsOneWidget);
    });

    testWidgets('PantallaLogin permite ingresar credenciales e intentar inicio de sesión', (tester) async {
      await tester.pumpWidget(crearEntorno(const PantallaLogin()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_login_email')), 'jugador@brilliant.com');
      await tester.enterText(find.byKey(const Key('input_login_password')), 'Password123');

      await tester.tap(find.byKey(const Key('btn_enviar_login')));
      // Drenar la cola de microtareas asíncronas del BLoC
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(authBloc.state, isA<Autenticado>());
    });

    testWidgets('PantallaRegistro muestra campos para crear cuenta y valida coincidencia', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(crearEntorno(const PantallaRegistro()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_registro_email')), findsOneWidget);
      expect(find.byKey(const Key('input_registro_password')), findsOneWidget);
      expect(find.byKey(const Key('input_registro_confirm')), findsOneWidget);
      expect(find.byKey(const Key('btn_enviar_registro')), findsOneWidget);

      // Ingresar datos con passwords diferentes
      await tester.enterText(find.byKey(const Key('input_registro_email')), 'nuevo@brilliant.com');
      await tester.enterText(find.byKey(const Key('input_registro_password')), 'Clave123');
      await tester.enterText(find.byKey(const Key('input_registro_confirm')), 'OtraClave99');

      await tester.ensureVisible(find.byKey(const Key('btn_enviar_registro')));
      await tester.tap(find.byKey(const Key('btn_enviar_registro')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authBloc.state, isA<AuthError>());
      final errorState = authBloc.state as AuthError;
      expect(errorState.mensaje, 'Las contraseñas no coinciden.');
    });

    testWidgets('DialogoEliminarCuenta muestra advertencia y campo de contraseña', (tester) async {
      await tester.pumpWidget(crearEntorno(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => DialogoEliminarCuenta.mostrar(context),
            child: const Text('Abrir Modal'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar Cuenta'), findsOneWidget);
      expect(find.byKey(const Key('input_password_eliminar')), findsOneWidget);
      expect(find.byKey(const Key('btn_cancelar_eliminar')), findsOneWidget);
      expect(find.byKey(const Key('btn_confirmar_eliminar')), findsOneWidget);

      // Cancelar cierra el diálogo
      await tester.tap(find.byKey(const Key('btn_cancelar_eliminar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('input_password_eliminar')), findsNothing);
    });

    testWidgets('AuthGuard conmuta entre Login y la pantalla del juego según el estado de autenticación', (tester) async {
      authBloc.emit(const NoAutenticado());

      await tester.pumpWidget(crearEntorno(
        const AuthGuard(
          child: Text('CONTENIDO_DEL_JUEGO'),
        ),
      ));
      await tester.pumpAndSettle();

      // Sin sesión -> Muestra Login
      expect(find.text('Brilliant'), findsOneWidget);
      expect(find.text('CONTENIDO_DEL_JUEGO'), findsNothing);

      // Simular login exitoso
      authBloc.emit(const Autenticado(
        usuario: UsuarioSesion(id: '1', email: 'user@test.com', token: 'tok'),
      ));
      await tester.pumpAndSettle();

      // Ahora muestra el contenido del juego
      expect(find.text('CONTENIDO_DEL_JUEGO'), findsOneWidget);
    });

    testWidgets('PantallaSeleccionNivel muestra menú de usuario cuando está autenticado', (tester) async {
      authBloc.emit(const Autenticado(
        usuario: UsuarioSesion(id: '1', email: 'pro_gamer@brilliant.com', token: 'tok'),
      ));

      await tester.pumpWidget(crearEntorno(const PantallaSeleccionNivel()));
      await tester.pumpAndSettle();

      // Debe aparecer el ícono de cuenta en el AppBar
      final menuBoton = find.byKey(const Key('menu_cuenta_usuario'));
      expect(menuBoton, findsOneWidget);

      await tester.tap(menuBoton);
      await tester.pumpAndSettle();

      expect(find.text('pro_gamer@brilliant.com'), findsOneWidget);
      expect(find.byKey(const Key('opcion_cerrar_sesion')), findsOneWidget);
      expect(find.byKey(const Key('opcion_eliminar_cuenta')), findsOneWidget);
    });
  });
}
