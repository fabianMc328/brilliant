import '../dominio/repositorio_autenticacion.dart';
import 'cliente_http_auth.dart';

/// Stub para compilación en Flutter Web.
Future<RespuestaHttpAuth> enviarHttpAuthImpl({
  required String metodo,
  required String urlWsOBaseHttp,
  required String ruta,
  Map<String, dynamic>? cuerpoJson,
  String? bearerToken,
  Duration? timeout,
}) async {
  throw const FalloAutenticacion(
    'La autenticación HTTP directa requiere plataforma móvil o escritorio.',
  );
}
