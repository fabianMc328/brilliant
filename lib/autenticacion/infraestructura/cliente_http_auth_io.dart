import 'dart:convert';
import 'dart:io';

import 'cliente_http_auth.dart';

String? obtenerIdInstanciaNavegadorImpl() => null;

/// Implementación nativa (`dart:io`) de peticiones HTTP de autenticación.
Future<RespuestaHttpAuth> enviarHttpAuthImpl({
  required String metodo,
  required String urlWsOBaseHttp,
  required String ruta,
  Map<String, dynamic>? cuerpoJson,
  String? bearerToken,
  Duration? timeout,
}) async {
  final uriFinal = construirUriHttpAuth(urlWsOBaseHttp, ruta);
  final timeoutEfectivo = timeout ?? timeoutPorDefectoHttpAuth(uriFinal);

  final client = HttpClient()..connectionTimeout = timeoutEfectivo;
  try {
    final req = await client.openUrl(metodo, uriFinal).timeout(timeoutEfectivo);
    req.headers.contentType = ContentType.json;
    if (bearerToken != null && bearerToken.isNotEmpty) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
    }
    if (cuerpoJson != null) {
      req.add(utf8.encode(jsonEncode(cuerpoJson)));
    }
    final res = await req.close().timeout(timeoutEfectivo);
    final texto = await utf8.decodeStream(res).timeout(timeoutEfectivo);
    Map<String, dynamic> decoded = {};
    if (texto.trim().isNotEmpty) {
      final raw = jsonDecode(texto);
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      }
    }
    return RespuestaHttpAuth(statusCode: res.statusCode, datos: decoded);
  } finally {
    client.close(force: true);
  }
}
