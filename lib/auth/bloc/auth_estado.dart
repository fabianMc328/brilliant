import '../modelos/usuario_sesion.dart';

/// Estados del AuthBloc.
abstract class AuthEstado {
  const AuthEstado();
}

/// Estado inicial al levantar el bloc antes de verificar token.
class AuthInicial extends AuthEstado {
  const AuthInicial();
}

/// Estado mientras se procesa una petición de red (login, registro, borrado).
class AuthCargando extends AuthEstado {
  final String mensaje;
  const AuthCargando({this.mensaje = 'Procesando...'});
}

/// Usuario autenticado con sesión válida.
class Autenticado extends AuthEstado {
  final UsuarioSesion usuario;
  const Autenticado({required this.usuario});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Autenticado &&
          runtimeType == other.runtimeType &&
          usuario == other.usuario;

  @override
  int get hashCode => usuario.hashCode;
}

/// No hay sesión activa (muestra pantalla de login/registro).
class NoAutenticado extends AuthEstado {
  final String? mensajeInformativo;
  const NoAutenticado({this.mensajeInformativo});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoAutenticado &&
          runtimeType == other.runtimeType &&
          mensajeInformativo == other.mensajeInformativo;

  @override
  int get hashCode => mensajeInformativo.hashCode;
}

/// Ocurrió un error (muestra banner o snackbar y permite reintentar).
class AuthError extends AuthEstado {
  final String mensaje;
  final AuthEstado estadoPrevio;

  const AuthError({
    required this.mensaje,
    required this.estadoPrevio,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          mensaje == other.mensaje;

  @override
  int get hashCode => mensaje.hashCode;
}
