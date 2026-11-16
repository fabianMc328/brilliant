import 'descubridor_servidor_local_web.dart'
    if (dart.library.io) 'descubridor_servidor_local_io.dart' as impl;

/// Descubre automáticamente en la red local (casa, escuela, emulador o web)
/// la URL WebSocket de `servidorBrilliant` sin necesidad de escribir la IP a mano.
class DescubridorServidorLocal {
  DescubridorServidorLocal._();

  static Future<String?> buscarServidorEnRed({
    Duration timeout = const Duration(seconds: 5),
  }) {
    return impl.buscarServidorEnRedImpl(timeout: timeout);
  }

  static Future<bool> verificarServidorActivo(
    String urlWs, {
    Duration timeout = const Duration(milliseconds: 600),
  }) {
    return impl.verificarServidorActivoImpl(urlWs, timeout: timeout);
  }
}
