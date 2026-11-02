/// Eventos para el AuthBloc.
abstract class AuthEvento {
  const AuthEvento();
}

/// Evento disparado al arrancar la aplicación para verificar si hay sesión activa previa.
class VerificarSesionInicial extends AuthEvento {
  const VerificarSesionInicial();
}

/// Evento para iniciar sesión con correo y contraseña.
class IniciarSesionSolicitado extends AuthEvento {
  final String email;
  final String password;

  const IniciarSesionSolicitado({
    required this.email,
    required this.password,
  });
}

/// Evento para registrar una nueva cuenta.
class RegistrarSolicitado extends AuthEvento {
  final String email;
  final String password;
  final String confirmacionPassword;

  const RegistrarSolicitado({
    required this.email,
    required this.password,
    required this.confirmacionPassword,
  });
}

/// Evento para cerrar la sesión actual.
class CerrarSesionSolicitado extends AuthEvento {
  const CerrarSesionSolicitado();
}

/// Evento para eliminar definitivamente la cuenta.
class EliminarCuentaSolicitada extends AuthEvento {
  final String passwordConfirmacion;

  const EliminarCuentaSolicitada({
    required this.passwordConfirmacion,
  });
}
