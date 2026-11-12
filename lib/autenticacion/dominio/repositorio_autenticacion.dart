import 'usuario.dart';

/// Excepción de fallos de autenticación.
class FalloAutenticacion implements Exception {
  final String mensaje;
  const FalloAutenticacion(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Contrato abstracto para el servicio de autenticación tradicional (DIP).
abstract class RepositorioAutenticacion {
  /// Obtiene el usuario de la sesión actual persistida si existe.
  Future<Usuario?> obtenerUsuarioSesion();

  /// Inicia sesión con usuario/correo y contraseña.
  Future<Usuario> iniciarSesion({
    required String identificador,
    required String contrasena,
  });

  /// Registra una nueva cuenta de usuario.
  Future<Usuario> registrarUsuario({
    required String apodo,
    required String email,
    required String contrasena,
  });

  /// Cierra la sesión activa actual.
  Future<void> cerrarSesion();
}
