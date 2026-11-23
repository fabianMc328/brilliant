import 'cliente_http_auth_web.dart'
    if (dart.library.io) 'cliente_http_auth_io.dart' as impl;

/// Construye la URI HTTP/HTTPS equivalente a partir de una URL `ws://`, `wss://`, `http://` o `https://`,
/// preservando cualquier query string presente en [ruta] (ej. `/auth/sesion?dispositivoId=...`).
Uri construirUriHttpAuth(String urlWsOBaseHttp, String ruta) {
  final uriBase = Uri.parse(urlWsOBaseHttp.trim());
  final esSeguro = uriBase.scheme == 'wss' || uriBase.scheme == 'https';
  final scheme = esSeguro ? 'https' : 'http';
  final rutaNormalizada = ruta.startsWith('/') ? ruta : '/$ruta';
  final uriRuta = Uri.parse(rutaNormalizada);

  return Uri(
    scheme: scheme,
    host: uriBase.host,
    port: uriBase.hasPort ? uriBase.port : null,
    path: uriRuta.path,
    query: uriRuta.hasQuery ? uriRuta.query : null,
  );
}

/// Timeout por defecto: 40 s para HTTPS (Render gratuito al despertar) y 8 s en LAN.
Duration timeoutPorDefectoHttpAuth(Uri uri) {
  return uri.scheme == 'https'
      ? const Duration(seconds: 40)
      : const Duration(seconds: 8);
}

/// Respuesta HTTP simple para operaciones de autenticación contra `servidorBrilliant`.
class RespuestaHttpAuth {
  final int statusCode;
  final Map<String, dynamic> datos;

  const RespuestaHttpAuth({
    required this.statusCode,
    required this.datos,
  });
}

/// Cliente HTTP multiplataforma (IO nativo y Web `fetch`) para `/auth/*` y `/salud`.
class ClienteHttpAuth {
  const ClienteHttpAuth();

  /// En Web devuelve un ID único por pestaña (`sessionStorage`) que sobrevive a F5
  /// en la misma pestaña pero es distinto al abrir una pestaña nueva. En IO devuelve `null`.
  static String? obtenerIdInstanciaNavegador() {
    return impl.obtenerIdInstanciaNavegadorImpl();
  }

  Future<RespuestaHttpAuth> enviar({
    required String metodo,
    required String urlWsOBaseHttp,
    required String ruta,
    Map<String, dynamic>? cuerpoJson,
    String? bearerToken,
    Duration? timeout,
  }) {
    return impl.enviarHttpAuthImpl(
      metodo: metodo,
      urlWsOBaseHttp: urlWsOBaseHttp,
      ruta: ruta,
      cuerpoJson: cuerpoJson,
      bearerToken: bearerToken,
      timeout: timeout,
    );
  }
}
