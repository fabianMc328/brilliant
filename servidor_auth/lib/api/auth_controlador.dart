import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../seguridad/jwt_servicio.dart';
import '../servicios/auth_servicio.dart';
import 'auth_middleware.dart';

class AuthControlador {
  final AuthServicio authServicio;
  final JwtServicio jwtServicio;

  AuthControlador({
    required this.authServicio,
    required this.jwtServicio,
  });

  Router get router {
    final r = Router();

    // Rutas públicas
    r.post('/registro', _registroHandler);
    r.post('/login', _loginHandler);

    // Rutas protegidas con middleware JWT
    final pipelineProtegido = const Pipeline()
        .addMiddleware(crearAuthMiddleware(jwtServicio));

    r.get('/perfil', pipelineProtegido.addHandler(_perfilHandler));
    r.delete('/cuenta', pipelineProtegido.addHandler(_eliminarCuentaHandler));

    return r;
  }

  Future<Response> _registroHandler(Request request) async {
    try {
      final bodyStr = await request.readAsString();
      if (bodyStr.trim().isEmpty) {
        return _jsonResponse(400, {'error': 'El cuerpo de la petición no puede estar vacío.'});
      }

      final body = jsonDecode(bodyStr) as Map<String, dynamic>;
      final email = body['email'] as String? ?? '';
      final password = body['password'] as String? ?? '';

      final resultado = await authServicio.registrar(email, password);
      return _jsonResponse(201, {
        'exito': true,
        'mensaje': 'Usuario registrado exitosamente.',
        'datos': resultado.toJson(),
      });
    } on AuthException catch (e) {
      return _jsonResponse(e.statusCode, {'error': e.mensaje});
    } on FormatException {
      return _jsonResponse(400, {'error': 'Formato JSON inválido.'});
    } catch (e) {
      return _jsonResponse(500, {'error': 'Error interno del servidor al registrar.'});
    }
  }

  Future<Response> _loginHandler(Request request) async {
    try {
      final bodyStr = await request.readAsString();
      if (bodyStr.trim().isEmpty) {
        return _jsonResponse(400, {'error': 'El cuerpo de la petición no puede estar vacío.'});
      }

      final body = jsonDecode(bodyStr) as Map<String, dynamic>;
      final email = body['email'] as String? ?? '';
      final password = body['password'] as String? ?? '';

      final resultado = await authServicio.iniciarSesion(email, password);
      return _jsonResponse(200, {
        'exito': true,
        'mensaje': 'Sesión iniciada con éxito.',
        'datos': resultado.toJson(),
      });
    } on AuthException catch (e) {
      return _jsonResponse(e.statusCode, {'error': e.mensaje});
    } on FormatException {
      return _jsonResponse(400, {'error': 'Formato JSON inválido.'});
    } catch (e) {
      return _jsonResponse(500, {'error': 'Error interno del servidor al iniciar sesión.'});
    }
  }

  Future<Response> _perfilHandler(Request request) async {
    try {
      final usuarioId = request.context['usuario_id'] as String;
      final usuario = await authServicio.obtenerPerfil(usuarioId);
      return _jsonResponse(200, {
        'exito': true,
        'datos': usuario.toJsonPublico(),
      });
    } on AuthException catch (e) {
      return _jsonResponse(e.statusCode, {'error': e.mensaje});
    } catch (e) {
      return _jsonResponse(500, {'error': 'Error interno del servidor al obtener perfil.'});
    }
  }

  Future<Response> _eliminarCuentaHandler(Request request) async {
    try {
      final usuarioId = request.context['usuario_id'] as String;
      final bodyStr = await request.readAsString();
      if (bodyStr.trim().isEmpty) {
        return _jsonResponse(400, {'error': 'Se requiere confirmar tu contraseña para eliminar la cuenta.'});
      }

      final body = jsonDecode(bodyStr) as Map<String, dynamic>;
      final password = body['password'] as String? ?? '';

      await authServicio.eliminarCuenta(usuarioId, password);
      return _jsonResponse(200, {
        'exito': true,
        'mensaje': 'Cuenta eliminada definitivamente con éxito.',
      });
    } on AuthException catch (e) {
      return _jsonResponse(e.statusCode, {'error': e.mensaje});
    } on FormatException {
      return _jsonResponse(400, {'error': 'Formato JSON inválido.'});
    } catch (e) {
      return _jsonResponse(500, {'error': 'Error interno del servidor al eliminar cuenta.'});
    }
  }

  Response _jsonResponse(int status, Map<String, dynamic> datos) {
    return Response(
      status,
      body: jsonEncode(datos),
      headers: {'content-type': 'application/json'},
    );
  }
}
