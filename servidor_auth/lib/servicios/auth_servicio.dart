import 'dart:math';
import '../modelos/usuario.dart';
import '../repositorio/usuario_repositorio.dart';
import '../seguridad/hasher.dart';
import '../seguridad/jwt_servicio.dart';

abstract class AuthException implements Exception {
  final String mensaje;
  final int statusCode;
  AuthException(this.mensaje, {this.statusCode = 400});

  @override
  String toString() => mensaje;
}

class ValidacionException extends AuthException {
  ValidacionException(super.mensaje) : super(statusCode: 400);
}

class EmailYaRegistradoException extends AuthException {
  EmailYaRegistradoException()
      : super('El usuario o correo ya se encuentra registrado.', statusCode: 409);
}

class CredencialesInvalidasException extends AuthException {
  CredencialesInvalidasException()
      : super('Credenciales incorrectas. Verifica tu usuario y contraseña.', statusCode: 401);
}

class UsuarioNoEncontradoException extends AuthException {
  UsuarioNoEncontradoException()
      : super('El usuario solicitado no existe.', statusCode: 404);
}

class ResultadoAutenticacion {
  final Usuario usuario;
  final String token;

  const ResultadoAutenticacion({
    required this.usuario,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
    'usuario': usuario.toJsonPublico(),
    'token': token,
  };
}

/// Servicio de Autenticación con soporte para nombres de usuario (ej: admin) y correos.
class AuthServicio {
  final UsuarioRepositorio usuarioRepositorio;
  final HasherContrasena hasher;
  final JwtServicio jwtServicio;

  AuthServicio({
    required this.usuarioRepositorio,
    required this.hasher,
    required this.jwtServicio,
  });

  /// Valida formato de usuario/correo y fortaleza mínima de la contraseña.
  void validarCredenciales(String identificador, String password) {
    final usuarioLimpio = identificador.trim();
    if (usuarioLimpio.isEmpty) {
      throw ValidacionException('El usuario o correo no puede estar vacío.');
    }
    if (usuarioLimpio.length < 3) {
      throw ValidacionException('El usuario debe tener al menos 3 caracteres.');
    }

    if (password.length < 6) {
      throw ValidacionException('La contraseña debe tener al menos 6 caracteres.');
    }
    final tieneLetra = RegExp(r'[a-zA-Z]').hasMatch(password);
    final tieneNumero = RegExp(r'[0-9]').hasMatch(password);
    if (!tieneLetra || !tieneNumero) {
      throw ValidacionException('La contraseña debe contener al menos una letra y un número.');
    }
  }

  /// Registra una nueva cuenta.
  Future<ResultadoAutenticacion> registrar(String identificador, String password) async {
    final usuarioNormalizado = identificador.trim().toLowerCase();
    validarCredenciales(usuarioNormalizado, password);

    final usuarioExistente = await usuarioRepositorio.buscarPorEmail(usuarioNormalizado);
    if (usuarioExistente != null) {
      throw EmailYaRegistradoException();
    }

    final id = _generarIdUnico();
    final passwordHash = hasher.hashear(password);
    final nuevoUsuario = Usuario(
      id: id,
      email: usuarioNormalizado,
      passwordHash: passwordHash,
      fechaCreacion: DateTime.now().toUtc(),
    );

    await usuarioRepositorio.guardar(nuevoUsuario);

    final token = jwtServicio.generarToken(
      usuarioId: nuevoUsuario.id,
      email: nuevoUsuario.email,
    );

    return ResultadoAutenticacion(usuario: nuevoUsuario, token: token);
  }

  /// Inicia sesión con usuario/correo y contraseña.
  Future<ResultadoAutenticacion> iniciarSesion(String identificador, String password) async {
    final usuarioNormalizado = identificador.trim().toLowerCase();
    if (usuarioNormalizado.isEmpty || password.isEmpty) {
      throw ValidacionException('El usuario y la contraseña son requeridos.');
    }

    final usuario = await usuarioRepositorio.buscarPorEmail(usuarioNormalizado);
    if (usuario == null) {
      throw CredencialesInvalidasException();
    }

    final esCorrecta = hasher.verificar(password, usuario.passwordHash);
    if (!esCorrecta) {
      throw CredencialesInvalidasException();
    }

    final token = jwtServicio.generarToken(
      usuarioId: usuario.id,
      email: usuario.email,
    );

    return ResultadoAutenticacion(usuario: usuario, token: token);
  }

  /// Obtiene los datos de perfil de un usuario autenticado.
  Future<Usuario> obtenerPerfil(String usuarioId) async {
    final usuario = await usuarioRepositorio.buscarPorId(usuarioId);
    if (usuario == null) {
      throw UsuarioNoEncontradoException();
    }
    return usuario;
  }

  /// Elimina definitivamente la cuenta del usuario validando su contraseña actual.
  Future<void> eliminarCuenta(String usuarioId, String passwordConfirmacion) async {
    if (passwordConfirmacion.isEmpty) {
      throw ValidacionException('Debes ingresar tu contraseña para confirmar la eliminación de la cuenta.');
    }

    final usuario = await usuarioRepositorio.buscarPorId(usuarioId);
    if (usuario == null) {
      throw UsuarioNoEncontradoException();
    }

    final esValida = hasher.verificar(passwordConfirmacion, usuario.passwordHash);
    if (!esValida) {
      throw ValidacionException('La contraseña de confirmación es incorrecta.');
    }

    final eliminado = await usuarioRepositorio.eliminarPorId(usuarioId);
    if (!eliminado) {
      throw UsuarioNoEncontradoException();
    }
  }

  String _generarIdUnico() {
    final random = Random.secure();
    final millis = DateTime.now().millisecondsSinceEpoch;
    final randSuffix = random.nextInt(999999).toString().padLeft(6, '0');
    return 'usr_${millis}_$randSuffix';
  }
}
