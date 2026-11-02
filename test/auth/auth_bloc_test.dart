import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/auth/bloc/auth_bloc.dart';
import 'package:brilliant/auth/bloc/auth_estado.dart';
import 'package:brilliant/auth/bloc/auth_evento.dart';
import 'package:brilliant/auth/modelos/usuario_sesion.dart';
import 'package:brilliant/auth/repositorio/auth_repositorio.dart';

class MockAuthRepositorio implements AuthRepositorio {
  UsuarioSesion? sesionSimulada;
  bool lanzarError = false;
  String mensajeError = 'Error simulado';

  @override
  Future<UsuarioSesion> registrar({
    required String email,
    required String password,
  }) async {
    if (lanzarError) throw AuthClienteException(mensajeError);
    sesionSimulada = UsuarioSesion(id: 'usr_mock_1', email: email, token: 'token_mock_reg');
    return sesionSimulada!;
  }

  @override
  Future<UsuarioSesion> iniciarSesion({
    required String email,
    required String password,
  }) async {
    if (lanzarError) throw AuthClienteException(mensajeError);
    sesionSimulada = UsuarioSesion(id: 'usr_mock_1', email: email, token: 'token_mock_login');
    return sesionSimulada!;
  }

  @override
  Future<UsuarioSesion?> obtenerSesionActual() async {
    if (lanzarError) throw AuthClienteException(mensajeError);
    return sesionSimulada;
  }

  @override
  Future<void> cerrarSesion() async {
    sesionSimulada = null;
  }

  @override
  Future<void> eliminarCuenta({required String passwordConfirmacion}) async {
    if (lanzarError) throw AuthClienteException(mensajeError);
    if (passwordConfirmacion != 'PasswordValida123') {
      throw const AuthClienteException('Contraseña de confirmación incorrecta.');
    }
    sesionSimulada = null;
  }
}

void main() {
  group('AuthBloc', () {
    late MockAuthRepositorio mockRepo;
    late AuthBloc authBloc;

    setUp(() {
      mockRepo = MockAuthRepositorio();
      authBloc = AuthBloc(authRepositorio: mockRepo);
    });

    tearDown(() {
      authBloc.close();
    });

    test('Estado inicial es NoAutenticado', () {
      expect(authBloc.state, isA<NoAutenticado>());
    });

    test('VerificarSesionInicial emite NoAutenticado si no hay sesión previa', () async {
      expectLater(
        authBloc.stream,
        emits(isA<NoAutenticado>()),
      );

      authBloc.add(const VerificarSesionInicial());
    });

    test('VerificarSesionInicial emite Autenticado si hay sesión activa', () async {
      mockRepo.sesionSimulada = const UsuarioSesion(
        id: 'u1',
        email: 'activo@brilliant.com',
        token: 'jwt_activo',
      );

      expectLater(
        authBloc.stream,
        emits(isA<Autenticado>()),
      );

      authBloc.add(const VerificarSesionInicial());
    });

    test('IniciarSesionSolicitado con credenciales válidas emite Autenticado', () async {
      expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          predicate<AuthEstado>((s) => s is Autenticado && s.usuario.email == 'test@brilliant.com'),
        ]),
      );

      authBloc.add(const IniciarSesionSolicitado(
        email: 'test@brilliant.com',
        password: 'Password123',
      ));
    });

    test('IniciarSesionSolicitado con campos vacíos emite AuthError', () async {
      expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthError>(),
        ]),
      );

      authBloc.add(const IniciarSesionSolicitado(
        email: '',
        password: '',
      ));
    });

    test('RegistrarSolicitado valida coincidencia de contraseñas', () async {
      expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthEstado>((s) => s is AuthError && s.mensaje.contains('no coinciden')),
        ]),
      );

      authBloc.add(const RegistrarSolicitado(
        email: 'nuevo@brilliant.com',
        password: 'Password123',
        confirmacionPassword: 'PasswordDistinta123',
      ));
    });

    test('RegistrarSolicitado exitoso emite Autenticado', () async {
      expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          predicate<AuthEstado>((s) => s is Autenticado && s.usuario.email == 'nuevo@brilliant.com'),
        ]),
      );

      authBloc.add(const RegistrarSolicitado(
        email: 'nuevo@brilliant.com',
        password: 'Password123',
        confirmacionPassword: 'Password123',
      ));
    });

    test('CerrarSesionSolicitado emite NoAutenticado', () async {
      mockRepo.sesionSimulada = const UsuarioSesion(
        id: 'u1',
        email: 'activo@brilliant.com',
        token: 'jwt_activo',
      );

      expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          isA<NoAutenticado>(),
        ]),
      );

      authBloc.add(const CerrarSesionSolicitado());
    });

    test('EliminarCuentaSolicitada con confirmación correcta emite NoAutenticado', () async {
      mockRepo.sesionSimulada = const UsuarioSesion(
        id: 'u1',
        email: 'activo@brilliant.com',
        token: 'jwt_activo',
      );

      expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          predicate<AuthEstado>((s) => s is NoAutenticado && s.mensajeInformativo != null),
        ]),
      );

      authBloc.add(const EliminarCuentaSolicitada(
        passwordConfirmacion: 'PasswordValida123',
      ));
    });

    test('EliminarCuentaSolicitada con confirmación incorrecta emite AuthError', () async {
      expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthCargando>(),
          isA<AuthError>(),
        ]),
      );

      authBloc.add(const EliminarCuentaSolicitada(
        passwordConfirmacion: 'ClaveEquivocada',
      ));
    });
  });
}
