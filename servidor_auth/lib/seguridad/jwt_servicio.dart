import 'dart:convert';
import 'package:crypto/crypto.dart';

class TokenInvalidoException implements Exception {
  final String mensaje;
  TokenInvalidoException(this.mensaje);

  @override
  String toString() => 'TokenInvalidoException: $mensaje';
}

/// Servicio de generación y verificación de JWT (JSON Web Tokens) usando HMAC-SHA256 (HS256).
class JwtServicio {
  final String claveSecreta;
  final Duration duracionToken;

  const JwtServicio({
    required this.claveSecreta,
    this.duracionToken = const Duration(hours: 24),
  });

  /// Genera un token JWT firmado.
  String generarToken({required String usuarioId, required String email}) {
    final ahora = DateTime.now().toUtc();
    final expiracion = ahora.add(duracionToken);

    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final payload = {
      'sub': usuarioId,
      'email': email,
      'iat': ahora.millisecondsSinceEpoch ~/ 1000,
      'exp': expiracion.millisecondsSinceEpoch ~/ 1000,
    };

    final headerBase64 = _base64UrlEncode(jsonEncode(header));
    final payloadBase64 = _base64UrlEncode(jsonEncode(payload));
    final cuerpo = '$headerBase64.$payloadBase64';

    final firma = _firmar(cuerpo);
    return '$cuerpo.$firma';
  }

  /// Verifica la firma y expiración del JWT y devuelve los claims del payload.
  Map<String, dynamic> verificarToken(String token) {
    final partes = token.split('.');
    if (partes.length != 3) {
      throw TokenInvalidoException('El token no tiene un formato JWT válido.');
    }

    final cuerpo = '${partes[0]}.${partes[1]}';
    final firmaRecibida = partes[2];
    final firmaEsperada = _firmar(cuerpo);

    if (!_comparacionTiempoConstante(firmaRecibida, firmaEsperada)) {
      throw TokenInvalidoException('Firma del token inválida.');
    }

    final payloadJson = _base64UrlDecode(partes[1]);
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

    final exp = payload['exp'] as int?;
    if (exp == null) {
      throw TokenInvalidoException('El token no contiene tiempo de expiración.');
    }

    final ahoraSegundos = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (ahoraSegundos > exp) {
      throw TokenInvalidoException('El token ha expirado.');
    }

    return payload;
  }

  String _firmar(String datos) {
    final hmac = Hmac(sha256, utf8.encode(claveSecreta));
    final digest = hmac.convert(utf8.encode(datos));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _base64UrlEncode(String texto) {
    return base64Url.encode(utf8.encode(texto)).replaceAll('=', '');
  }

  String _base64UrlDecode(String textoBase64) {
    String normalizada = textoBase64;
    while (normalizada.length % 4 != 0) {
      normalizada += '=';
    }
    return utf8.decode(base64Url.decode(normalizada));
  }

  bool _comparacionTiempoConstante(String a, String b) {
    if (a.length != b.length) return false;
    int res = 0;
    for (int i = 0; i < a.length; i++) {
      res |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return res == 0;
  }
}
