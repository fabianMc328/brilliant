import '../constantes_multijugador.dart';

/// En Flutter Web (Edge/Chrome), el host actual suele coincidir con el servidor.
Future<String?> buscarServidorEnRedImpl({
  Duration timeout = const Duration(seconds: 5),
}) async {
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
  return urlWs.trim().isNotEmpty;
}
