import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constantes_multijugador.dart';

/// Descubre automáticamente el servidor Brilliant en la red local mediante:
/// 1) Broadcast UDP en el puerto 45454 (respuesta en <150 ms en redes permisivas).
/// 2) Comprobación rápida de localhost/emulador y escaneo HTTP /salud en subredes privadas reales.
Future<String?> buscarServidorEnRedImpl({
  Duration timeout = const Duration(seconds: 5),
}) async {
  final subredesPriorizadas = await _obtenerSubredesLocalesOrdenadas();

  final encontradoUdp = await _descubrirPorUdp(
    subredes: subredesPriorizadas,
    timeout: const Duration(milliseconds: 900),
  );
  if (encontradoUdp != null) {
    return encontradoUdp;
  }

  final candidatos = <String>{};
  candidatos.add('127.0.0.1');
  candidatos.add('10.0.2.2');

  for (final prefijo in subredesPriorizadas) {
    for (int host = 1; host <= 254; host++) {
      candidatos.add('$prefijo.$host');
    }
  }

  return _escanearSaludEnParalelo(
    candidatos.toList(),
    puerto: ConstantesMultijugador.puertoServidorPorDefecto,
    timeoutTotal: timeout,
  );
}

/// Verifica con timeout corto si una URL WebSocket de Brilliant responde en /salud.
Future<bool> verificarServidorActivoImpl(
  String urlWs, {
  Duration timeout = const Duration(milliseconds: 600),
}) async {
  final uri = Uri.tryParse(urlWs.trim());
  if (uri == null || uri.host.isEmpty) return false;
  final puerto = uri.hasPort
      ? uri.port
      : ConstantesMultijugador.puertoServidorPorDefecto;
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final resultado = await _probarSalud(
      client,
      uri.host,
      puerto,
      timeout: timeout,
    );
    return resultado != null;
  } finally {
    client.close(force: true);
  }
}

Future<String?> _descubrirPorUdp({
  required List<String> subredes,
  required Duration timeout,
}) async {
  RawDatagramSocket? socket;
  final completer = Completer<String?>();
  Timer? timer;

  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    socket.listen(
      (event) {
        if (event != RawSocketEvent.read || completer.isCompleted) return;
        final datagram = socket?.receive();
        if (datagram == null) return;

        try {
          final texto = utf8.decode(datagram.data, allowMalformed: true).trim();
          final json = jsonDecode(texto);
          if (json is Map && json['servicio'] == 'servidorBrilliant') {
            final puerto =
                (json['puerto'] as num?)?.toInt() ??
                    ConstantesMultijugador.puertoServidorPorDefecto;
            completer.complete('ws://${datagram.address.address}:$puerto');
          }
        } catch (_) {}
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    final carga = utf8.encode(ConstantesMultijugador.mensajeDescubrimientoUdp);
    socket.send(
      carga,
      InternetAddress('255.255.255.255'),
      ConstantesMultijugador.puertoDescubrimientoUdp,
    );
    // Enviar también broadcast dirigido por subred (más fiable en hotspots/redes Wi-Fi escolares)
    for (final prefijo in subredes) {
      try {
        socket.send(
          carga,
          InternetAddress('$prefijo.255'),
          ConstantesMultijugador.puertoDescubrimientoUdp,
        );
      } catch (_) {}
    }

    timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });

    return await completer.future;
  } catch (_) {
    return null;
  } finally {
    timer?.cancel();
    socket?.close();
  }
}

Future<List<String>> _obtenerSubredesLocalesOrdenadas() async {
  final prioritarias = <String>{};
  final secundarias = <String>{};

  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in interfaces) {
      final nombre = iface.name.toLowerCase();
      if (_esInterfazVirtualODescartable(nombre)) continue;

      final esPreferida = nombre.contains('wlan') ||
          nombre.contains('wi-fi') ||
          nombre.contains('wifi') ||
          nombre.startsWith('en') ||
          nombre.startsWith('eth');

      for (final addr in iface.addresses) {
        final ip = addr.address;
        if (!_esIpv4PrivadaValida(ip)) continue;
        final partes = ip.split('.');
        if (partes.length != 4) continue;
        final prefijo = '${partes[0]}.${partes[1]}.${partes[2]}';
        if (esPreferida) {
          prioritarias.add(prefijo);
        } else {
          secundarias.add(prefijo);
        }
      }
    }
  } catch (_) {}

  return [...prioritarias, ...secundarias];
}

bool _esInterfazVirtualODescartable(String nombreMinuscula) {
  const patronesExcluidos = [
    'virtual',
    'vbox',
    'vmware',
    'hyper-v',
    'vethernet',
    'wsl',
    'docker',
    'tun',
    'tap',
    'tailscale',
    'zerotier',
    'loopback',
    'rmnet',
    'ccmni',
  ];
  for (final patron in patronesExcluidos) {
    if (nombreMinuscula.contains(patron)) return true;
  }
  return false;
}

bool _esIpv4PrivadaValida(String ip) {
  if (ip.startsWith('127.') || ip.startsWith('169.254.')) return false;
  // Evita la subred por defecto de VirtualBox Host-Only
  if (ip.startsWith('192.168.56.')) return false;
  final partes = ip.split('.');
  if (partes.length != 4) return false;
  final primero = int.tryParse(partes[0]);
  final segundo = int.tryParse(partes[1]);
  if (primero == null || segundo == null) return false;

  if (primero == 10) return true;
  if (primero == 172 && segundo >= 16 && segundo <= 31) return true;
  if (primero == 192 && segundo == 168) return true;
  return false;
}

Future<String?> _escanearSaludEnParalelo(
  List<String> hosts, {
  required int puerto,
  required Duration timeoutTotal,
}) async {
  if (hosts.isEmpty) return null;

  final client = HttpClient()
    ..connectionTimeout = const Duration(milliseconds: 420);
  final completer = Completer<String?>();
  final limite = Timer(timeoutTotal, () {
    if (!completer.isCompleted) completer.complete(null);
  });

  int indice = 0;
  const concurrenciaMax = 48;

  Future<void> worker() async {
    while (!completer.isCompleted) {
      final actual = indice++;
      if (actual >= hosts.length) break;
      final ip = hosts[actual];
      final encontrado = await _probarSalud(
        client,
        ip,
        puerto,
        timeout: const Duration(milliseconds: 480),
      );
      if (encontrado != null && !completer.isCompleted) {
        completer.complete(encontrado);
        return;
      }
    }
  }

  try {
    final workers = List.generate(
      hosts.length < concurrenciaMax ? hosts.length : concurrenciaMax,
      (_) => worker(),
    );
    await Future.any([
      Future.wait(workers).then((_) {
        if (!completer.isCompleted) completer.complete(null);
      }),
      completer.future,
    ]);
    return await completer.future;
  } finally {
    limite.cancel();
    client.close(force: true);
  }
}

Future<String?> _probarSalud(
  HttpClient client,
  String host,
  int puerto, {
  required Duration timeout,
}) async {
  try {
    final req = await client
        .getUrl(Uri.parse('http://$host:$puerto/salud'))
        .timeout(timeout);
    final res = await req.close().timeout(timeout);
    if (res.statusCode != HttpStatus.ok) {
      await res.drain<void>();
      return null;
    }
    final cuerpo = await utf8.decodeStream(res).timeout(timeout);
    final json = jsonDecode(cuerpo);
    if (json is Map && json['servicio'] == 'servidorBrilliant') {
      return 'ws://$host:$puerto';
    }
  } catch (_) {}
  return null;
}
