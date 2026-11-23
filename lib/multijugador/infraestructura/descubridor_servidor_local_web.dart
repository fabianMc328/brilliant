import '../../autenticacion/infraestructura/cliente_http_auth.dart';
import '../constantes_multijugador.dart';

/// En Flutter Web (Edge/Chrome), usa por defecto el servidor en la nube salvo que se solicite solo red local.
Future<String?> buscarServidorEnRedImpl({
  Duration timeout = const Duration(seconds: 5),
  bool incluirNube = true,
}) async {
  if (incluirNube) {
    return ConstantesMultijugador.urlServidorNubePorDefecto;
  }
  final host = Uri.base.host;
  if (host.isEmpty) {
    return ConstantesMultijugador.urlServidorLocalPorDefecto;
  }
  return 'ws://$host:${ConstantesMultijugador.puertoServidorPorDefecto}';
}

Future<bool> verificarServidorActivoImpl(
  String urlWs, {
  Duration timeout = const Duration(milliseconds: 600),
}) async {
  final limpia = urlWs.trim();
  if (limpia.isEmpty) return false;
  final uri = Uri.tryParse(limpia);
  if (uri == null || uri.host.isEmpty) return false;

  final esSeguro = uri.scheme == 'wss' || uri.scheme == 'https';
  final timeoutEfectivo = esSeguro && timeout < const Duration(seconds: 35)
      ? const Duration(seconds: 35)
      : timeout;

  try {
    final respuesta = await const ClienteHttpAuth().enviar(
      metodo: 'GET',
      urlWsOBaseHttp: limpia,
      ruta: '/salud',
      timeout: timeoutEfectivo,
    );
    return respuesta.statusCode == 200 &&
        respuesta.datos['servicio'] == 'servidorBrilliant';
  } catch (_) {
    return false;
  }
}
