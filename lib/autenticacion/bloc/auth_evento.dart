/// Eventos de autenticación de usuario.
abstract class AuthEvento {
  const AuthEvento();
}

class ComprobarSesionInicial extends AuthEvento {
  const ComprobarSesionInicial();
}

class IniciarSesionSolicitado extends AuthEvento {
  final String identificador;
  final String contrasena;

  const IniciarSesionSolicitado({
    required this.identificador,
    required this.contrasena,
  });
}

class RegistrarUsuarioSolicitado extends AuthEvento {
  final String apodo;
  final String email;
  final String contrasena;
  final String confirmacionContrasena;

  const RegistrarUsuarioSolicitado({
    required this.apodo,
    required this.email,
    required this.contrasena,
    required this.confirmacionContrasena,
  });
}

class CerrarSesionSolicitado extends AuthEvento {
  const CerrarSesionSolicitado();
}

class LimpiarErrorAuth extends AuthEvento {
  const LimpiarErrorAuth();
}
