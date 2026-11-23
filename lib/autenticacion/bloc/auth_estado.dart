import '../dominio/usuario.dart';

/// Estados posibles del flujo de autenticación.
abstract class AuthEstado {
  const AuthEstado();
}

class AuthInicial extends AuthEstado {
  const AuthInicial();
}

class AuthCargando extends AuthEstado {
  final String? mensaje;
  final bool esComprobacionInicial;

  const AuthCargando({
    this.mensaje,
    this.esComprobacionInicial = false,
  });
}

class AuthNoAutenticado extends AuthEstado {
  final String? mensajeError;
  final String? mensajeExito;

  const AuthNoAutenticado({
    this.mensajeError,
    this.mensajeExito,
  });

  AuthNoAutenticado copiarCon({
    String? mensajeError,
    String? mensajeExito,
    bool limpiarError = false,
  }) {
    return AuthNoAutenticado(
      mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
      mensajeExito: limpiarError ? null : (mensajeExito ?? this.mensajeExito),
    );
  }
}

class AuthAutenticado extends AuthEstado {
  final Usuario usuario;

  const AuthAutenticado({required this.usuario});
}
