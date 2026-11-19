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
  return urlWs.trim().isNotEmpty;
}
