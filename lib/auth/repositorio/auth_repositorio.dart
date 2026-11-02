import '../modelos/usuario_sesion.dart';

class AuthClienteException implements Exception {
  final String mensaje;
  const AuthClienteException(this.mensaje);

  @override
  String toString() => mensaje;
}

abstract class AuthRepositorio {
  Future<UsuarioSesion> registrar({
    required String email,
    required String password,
  });

  Future<UsuarioSesion> iniciarSesion({
    required String email,
    required String password,
  });

  Future<UsuarioSesion?> obtenerSesionActual();

  Future<void> cerrarSesion();

  Future<void> eliminarCuenta({
    required String passwordConfirmacion,
  });
}
