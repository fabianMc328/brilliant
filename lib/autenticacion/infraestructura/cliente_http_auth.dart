import 'cliente_http_auth_web.dart'
    if (dart.library.io) 'cliente_http_auth_io.dart' as impl;

/// Respuesta HTTP simple para operaciones de autenticación contra `servidorBrilliant`.
class RespuestaHttpAuth {
  final int statusCode;
  final Map<String, dynamic> datos;

  const RespuestaHttpAuth({
    required this.statusCode,
    required this.datos,
  });
}

/// Cliente HTTP multiplataforma (IO nativo + stub Web) para `/auth/*`.
class ClienteHttpAuth {
  const ClienteHttpAuth();

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
