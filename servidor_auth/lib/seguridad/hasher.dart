import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Servicio de hashing de contraseñas seguro usando PBKDF2-HMAC-SHA256
/// con sal criptográfica aleatoria y comparación en tiempo constante.
class HasherContrasena {
  final int iteraciones;
  final int longitudSalBytes;

  const HasherContrasena({
    this.iteraciones = 10000,
    this.longitudSalBytes = 16,
  });

  /// Genera una sal criptográfica segura en hexadecimal.
  String generarSal() {
    final random = Random.secure();
    final bytes = Uint8List(longitudSalBytes);
    for (int i = 0; i < longitudSalBytes; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Calcula el hash de una contraseña usando PBKDF2 con HMAC-SHA256.
  String hashear(String contrasena, {String? sal}) {
    final salEfectiva = sal ?? generarSal();
    final salBytes = utf8.encode(salEfectiva);
    final contrasenaBytes = utf8.encode(contrasena);

    // PBKDF2 implementation con HMAC-SHA256
    var bloque = Uint8List.fromList([...salBytes, 0, 0, 0, 1]);
    var hmac = Hmac(sha256, contrasenaBytes);
    var u = Uint8List.fromList(hmac.convert(bloque).bytes);
    var resultado = Uint8List.fromList(u);

    for (int i = 1; i < iteraciones; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (int k = 0; k < resultado.length; k++) {
        resultado[k] ^= u[k];
      }
    }

    final hashHex = resultado.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'pbkdf2:sha256:$iteraciones:$salEfectiva:$hashHex';
  }

  /// Verifica si una contraseña en texto plano coincide con el hash almacenado.
  bool verificar(String contrasena, String hashAlmacenado) {
    final partes = hashAlmacenado.split(':');
    if (partes.length != 5 || partes[0] != 'pbkdf2' || partes[1] != 'sha256') {
      return false;
    }

    final iteracionesAlmacenadas = int.tryParse(partes[2]);
    if (iteracionesAlmacenadas == null) return false;

    final sal = partes[3];
    final hashCalculado = HasherContrasena(iteraciones: iteracionesAlmacenadas)
        .hashear(contrasena, sal: sal);

    return _comparacionTiempoConstante(hashCalculado, hashAlmacenado);
  }

  /// Evita ataques de temporización (timing attacks) comparando cada byte.
  bool _comparacionTiempoConstante(String a, String b) {
    if (a.length != b.length) return false;
    int resultado = 0;
    for (int i = 0; i < a.length; i++) {
      resultado |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return resultado == 0;
  }
}
