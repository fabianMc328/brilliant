import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../modelos/usuario_sesion.dart';
import 'auth_repositorio.dart';
import 'token_almacenamiento.dart';

class HttpAuthRepositorio implements AuthRepositorio {
  final String baseUrl;
  final http.Client _client;
  final TokenAlmacenamiento _tokenStorage;
  final Duration timeout;

  HttpAuthRepositorio({
    this.baseUrl = 'http://127.0.0.1:8080/api/auth',
    http.Client? client,
    TokenAlmacenamiento? tokenStorage,
    this.timeout = const Duration(seconds: 4),
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenAlmacenamientoMemoria();

  @override
  Future<UsuarioSesion> registrar({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/registro');
    final response = await _ejecutarPeticion(() => _client.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ));

    final json = _procesarRespuesta(response);
    final datos = json['datos'] as Map<String, dynamic>;
    final sesion = UsuarioSesion.fromJson(datos);

    await _tokenStorage.guardarToken(sesion.token);
    return sesion;
  }

  @override
  Future<UsuarioSesion> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login');
    final response = await _ejecutarPeticion(() => _client.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ));

    final json = _procesarRespuesta(response);
    final datos = json['datos'] as Map<String, dynamic>;
    final sesion = UsuarioSesion.fromJson(datos);

    await _tokenStorage.guardarToken(sesion.token);
    return sesion;
  }

  @override
  Future<UsuarioSesion?> obtenerSesionActual() async {
    try {
      final token = await _tokenStorage.obtenerToken();
      if (token == null || token.isEmpty) return null;

      final uri = Uri.parse('$baseUrl/perfil');
      final response = await _client.get(
        uri,
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final datos = json['datos'] as Map<String, dynamic>;
        return UsuarioSesion(
          id: datos['id'] as String? ?? '',
          email: datos['email'] as String? ?? '',
          token: token,
        );
      } else {
        await _tokenStorage.borrarToken();
        return null;
      }
    } catch (_) {
      // Si el servidor no está encendido o hay timeout, no bloqueamos la app
      return null;
    }
  }

  @override
  Future<void> cerrarSesion() async {
    await _tokenStorage.borrarToken();
  }

  @override
  Future<void> eliminarCuenta({
    required String passwordConfirmacion,
  }) async {
    final token = await _tokenStorage.obtenerToken();
    if (token == null || token.isEmpty) {
      throw const AuthClienteException('No hay sesión activa para eliminar la cuenta.');
    }

    final uri = Uri.parse('$baseUrl/cuenta');
    final response = await _ejecutarPeticion(() => _client.delete(
      uri,
      headers: {
        'content-type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'password': passwordConfirmacion}),
    ));

    _procesarRespuesta(response);
    await _tokenStorage.borrarToken();
  }

  Future<http.Response> _ejecutarPeticion(Future<http.Response> Function() accion) async {
    try {
      return await accion().timeout(timeout);
    } on TimeoutException {
      throw const AuthClienteException(
        'El servidor de autenticación tardó demasiado en responder. Asegúrate de tener abierto iniciar_servidor.bat.',
      );
    } catch (e) {
      throw const AuthClienteException(
        'No fue posible conectar con el servidor de autenticación (http://127.0.0.1:8080). Asegúrate de tener abierto iniciar_servidor.bat.',
      );
    }
  }

  Map<String, dynamic> _procesarRespuesta(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthClienteException(
        'Respuesta inválida del servidor (código ${response.statusCode}).',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final mensajeError = json['error'] as String? ??
        'Error inesperado en el servidor (${response.statusCode}).';
    throw AuthClienteException(mensajeError);
  }
}
