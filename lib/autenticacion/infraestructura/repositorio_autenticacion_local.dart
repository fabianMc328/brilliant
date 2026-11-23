import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/repositorio_autenticacion.dart';
import '../dominio/usuario.dart';
import '../dominio/validador_auth.dart';

/// Implementación local de autenticación en SharedPreferences + SHA-256 (ideal para pruebas offline).
class RepositorioAutenticacionLocal implements RepositorioAutenticacion {
  static const String _claveUsuarios = 'brilliant_usuarios_registrados_v1';
  static const String _claveSesionActiva = 'brilliant_sesion_activa_usuario_v1';

  final SharedPreferences? _prefsInyectadas;

  RepositorioAutenticacionLocal({SharedPreferences? preferences})
      : _prefsInyectadas = preferences;

  Future<SharedPreferences> _obtenerPrefs() async {
    final prefs = _prefsInyectadas;
    if (prefs != null) return prefs;
    return SharedPreferences.getInstance();
  }

  String _hashear(String texto) {
    const sal = 'brilliant_secure_salt_2026_';
    final bytes = utf8.encode('$sal$texto');
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, Map<String, dynamic>>> _cargarBaseDatosUsuarios() async {
    final prefs = await _obtenerPrefs();
    final jsonStr = prefs.getString(_claveUsuarios);
    if (jsonStr == null || jsonStr.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _guardarBaseDatosUsuarios(
    Map<String, Map<String, dynamic>> bd,
  ) async {
    final prefs = await _obtenerPrefs();
    await prefs.setString(_claveUsuarios, jsonEncode(bd));
  }

  @override
  Future<Usuario?> obtenerUsuarioSesion() async {
    final prefs = await _obtenerPrefs();
    final usuarioId = prefs.getString(_claveSesionActiva);
    if (usuarioId == null || usuarioId.isEmpty) return null;

    final bd = await _cargarBaseDatosUsuarios();
    final registro = bd[usuarioId];
    if (registro == null) {
      await prefs.remove(_claveSesionActiva);
      return null;
    }

    return Usuario.fromJson(registro['usuario'] as Map<String, dynamic>);
  }

  @override
  Future<Usuario> iniciarSesion({
    required String identificador,
    required String contrasena,
  }) async {
    final errorId = ValidadorAuth.validarIdentificadorLogin(identificador);
    if (errorId != null) {
      throw FalloAutenticacion('$errorId.');
    }
    final errorPass = ValidadorAuth.validarContrasena(contrasena);
    if (errorPass != null) {
      throw FalloAutenticacion('$errorPass.');
    }

    final idLimpio = identificador.trim().toLowerCase();
    final claveApodo = ValidadorAuth.normalizarApodoClave(identificador);
    final bd = await _cargarBaseDatosUsuarios();
    final hashIngresado = _hashear(contrasena);

    for (final entry in bd.values) {
      final rawUser = entry['usuario'] as Map<String, dynamic>;
      final email = (rawUser['email'] as String? ?? '').trim().toLowerCase();
      final apodoClave =
          ValidadorAuth.normalizarApodoClave(rawUser['apodo'] as String? ?? '');
      final storedHash = entry['passwordHash'] as String? ?? '';

      final coincide =
          idLimpio.contains('@') ? idLimpio == email : claveApodo == apodoClave;
      if (coincide) {
        if (storedHash != hashIngresado) {
          throw const FalloAutenticacion('Contraseña incorrecta.');
        }
        final usuario = Usuario.fromJson(rawUser);
        final prefs = await _obtenerPrefs();
        await prefs.setString(_claveSesionActiva, usuario.id);
        return usuario;
      }
    }

    throw const FalloAutenticacion(
      'No existe ninguna cuenta registrada con esos datos.',
    );
  }

  @override
  Future<Usuario> registrarUsuario({
    required String apodo,
    required String email,
    required String contrasena,
  }) async {
    final errorApodo = ValidadorAuth.validarApodo(apodo);
    if (errorApodo != null) {
      throw FalloAutenticacion('$errorApodo.');
    }
    final errorEmail = ValidadorAuth.validarEmail(email);
    if (errorEmail != null) {
      throw FalloAutenticacion('$errorEmail.');
    }
    final errorPass = ValidadorAuth.validarContrasena(contrasena);
    if (errorPass != null) {
      throw FalloAutenticacion('$errorPass.');
    }

    final apodoLimpio = apodo.trim();
    final apodoClave = ValidadorAuth.normalizarApodoClave(apodoLimpio);
    final emailLimpio = email.trim().toLowerCase();

    final bd = await _cargarBaseDatosUsuarios();

    for (final entry in bd.values) {
      final rawUser = entry['usuario'] as Map<String, dynamic>;
      if ((rawUser['email'] as String? ?? '').trim().toLowerCase() ==
          emailLimpio) {
        throw const FalloAutenticacion(
          'El correo electrónico ya está registrado.',
        );
      }
      if (ValidadorAuth.normalizarApodoClave(
            rawUser['apodo'] as String? ?? '',
          ) ==
          apodoClave) {
        throw FalloAutenticacion(
          'El apodo "$apodoLimpio" ya está en uso.',
        );
      }
    }

    final nuevoId = 'usr_${DateTime.now().microsecondsSinceEpoch}';
    final nuevoUsuario = Usuario(
      id: nuevoId,
      apodo: apodoLimpio,
      email: emailLimpio,
      fechaRegistro: DateTime.now(),
    );

    bd[nuevoId] = {
      'usuario': nuevoUsuario.toJson(),
      'passwordHash': _hashear(contrasena),
    };

    await _guardarBaseDatosUsuarios(bd);

    final prefs = await _obtenerPrefs();
    await prefs.setString(_claveSesionActiva, nuevoId);

    return nuevoUsuario;
  }

  @override
  Future<void> cerrarSesion() async {
    final prefs = await _obtenerPrefs();
    await prefs.remove(_claveSesionActiva);
  }
}
