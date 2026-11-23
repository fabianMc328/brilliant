import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'cliente_http_auth.dart';

/// Implementación para Flutter Web mediante `window.fetch` contra `servidorBrilliant`.
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

  final headers = web.Headers();
  headers.append('Content-Type', 'application/json');
  if (bearerToken != null && bearerToken.isNotEmpty) {
    headers.append('Authorization', 'Bearer $bearerToken');
  }

  final abortController = web.AbortController();
  final init = cuerpoJson != null
      ? web.RequestInit(
          method: metodo,
          headers: headers,
          body: jsonEncode(cuerpoJson).toJS,
          signal: abortController.signal,
        )
      : web.RequestInit(
          method: metodo,
          headers: headers,
          signal: abortController.signal,
        );

  final timer = Timer(timeoutEfectivo, () {
    abortController.abort();
  });

  try {
    final response = await web.window
        .fetch(uriFinal.toString().toJS, init)
        .toDart
        .timeout(timeoutEfectivo);
    final textoJs = await response.text().toDart.timeout(timeoutEfectivo);
    final texto = textoJs.toDart;

    Map<String, dynamic> decoded = {};
    if (texto.trim().isNotEmpty) {
      final raw = jsonDecode(texto);
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      }
    }
    return RespuestaHttpAuth(statusCode: response.status, datos: decoded);
  } finally {
    timer.cancel();
  }
}
