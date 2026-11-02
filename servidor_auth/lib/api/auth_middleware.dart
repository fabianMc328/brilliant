import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../seguridad/jwt_servicio.dart';

/// Middleware que verifica el token Bearer en el encabezado Authorization
/// e inyecta `usuario_id` en el contexto del request.
Middleware crearAuthMiddleware(JwtServicio jwtServicio) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'] ?? request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(
          401,
          body: jsonEncode({'error': 'Token de autorización requerido en encabezado Authorization.'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final token = authHeader.substring(7).trim();
      try {
        final claims = jwtServicio.verificarToken(token);
        final usuarioId = claims['sub'] as String;
        final email = claims['email'] as String?;

        final updatedRequest = request.change(context: {
          'usuario_id': usuarioId,
          'usuario_email': email,
        });

        return await innerHandler(updatedRequest);
      } on TokenInvalidoException catch (e) {
        return Response(
          401,
          body: jsonEncode({'error': e.mensaje}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response(
          401,
          body: jsonEncode({'error': 'Token inválido o corrupto.'}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
