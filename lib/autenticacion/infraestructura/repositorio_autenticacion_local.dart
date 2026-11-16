import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/repositorio_autenticacion.dart';
import '../dominio/usuario.dart';

/// Implementación persistente de autenticación tradicional usando SharedPreferences y SHA-256.
class RepositorioAutenticacionLocal implements RepositorioAutenticacion {
  static const String _claveUsuarios = 'brilliant_usuarios_registrados_v1';
  static const String _claveSesionActiva = 'brilliant_sesion_activa_usuario_v1';

  final SharedPreferences? _prefsInyectadas;

  RepositorioAutenticacionLocal({SharedPreferences? preferences})
      : _prefsInyectadas = preferences;

  Future<SharedPreferences> _obtenerPrefs() async {
    final prefs = _prefsInyectadas;
    if (prefs != null) return prefs;
    return await SharedPreferences.getInstance();
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
      // Sembrar usuario demo por defecto para pruebas o acceso rápido
      final demoHash = _hashear('contraseña123');
      final baseInicial = <String, Map<String, dynamic>>{
        'usr_fabian': {
          'usuario': Usuario(
            id: 'usr_fabian',
            apodo: 'Fabian',
            email: 'fabian@brilliant.com',
            fechaRegistro: DateTime(2026, 1, 1),
          ).toJson(),
          'passwordHash': demoHash,
        },
      };
      await prefs.setString(_claveUsuarios, jsonEncode(baseInicial));
      return baseInicial;
    }

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final bd = decoded.map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );

      // Migrar contraseña demo anterior si estaba persistida en el dispositivo
      final demoUser = bd['usr_fabian'];
      if (demoUser != null &&
          demoUser['passwordHash'] == _hashear('password123')) {
        demoUser['passwordHash'] = _hashear('contraseña123');
        await prefs.setString(_claveUsuarios, jsonEncode(bd));
      }

      return bd;
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
    final idLimpio = identificador.trim().toLowerCase();

    if (idLimpio.isEmpty) {
      throw const FalloAutenticacion(
        'Ingresa tu usuario o correo electrónico.',
      );
    }

    if (idLimpio.contains('@')) {
      if (RegExp(r'\s').hasMatch(idLimpio)) {
        throw const FalloAutenticacion(
          'El correo electrónico no puede contener espacios.',
        );
      }
      final regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
      if (!regexEmail.hasMatch(idLimpio)) {
        throw const FalloAutenticacion(
          'Ingresa un correo electrónico válido.',
        );
      }
    } else if (RegExp(r'\s{2,}').hasMatch(idLimpio)) {
      throw const FalloAutenticacion(
        'El usuario no puede contener espacios consecutivos.',
      );
    }

    if (contrasena.isEmpty) {
      throw const FalloAutenticacion('Ingresa tu contraseña.');
    }

    if (RegExp(r'\s').hasMatch(contrasena)) {
      throw const FalloAutenticacion(
        'La contraseña no puede contener espacios.',
      );
    }

    if (contrasena.length < 6) {
      throw const FalloAutenticacion(
        'La contraseña debe tener al menos 6 caracteres.',
      );
    }

    final bd = await _cargarBaseDatosUsuarios();
    final hashIngresado = _hashear(contrasena);

    for (final entry in bd.values) {
      final rawUser = entry['usuario'] as Map<String, dynamic>;
      final email = (rawUser['email'] as String? ?? '').trim().toLowerCase();
      final apodo = (rawUser['apodo'] as String? ?? '').trim().toLowerCase();
      final storedHash = entry['passwordHash'] as String? ?? '';

      if (idLimpio == email || idLimpio == apodo) {
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
    final apodoLimpio = apodo.trim();
    final emailLimpio = email.trim().toLowerCase();

    if (apodoLimpio.isEmpty) {
      throw const FalloAutenticacion('Ingresa un apodo o nombre de jugador.');
    }

    if (apodoLimpio.length < 2 || apodoLimpio.length > 18) {
      throw const FalloAutenticacion(
        'El apodo debe contener entre 2 y 18 caracteres.',
      );
    }

    if (RegExp(r'\s{2,}').hasMatch(apodoLimpio)) {
      throw const FalloAutenticacion(
        'El apodo no puede contener espacios consecutivos.',
      );
    }

    if (apodoLimpio.contains('@')) {
      throw const FalloAutenticacion(
        'El apodo no puede contener el símbolo @.',
      );
    }

    if (emailLimpio.isEmpty) {
      throw const FalloAutenticacion('Ingresa un correo electrónico.');
    }

    if (RegExp(r'\s').hasMatch(emailLimpio)) {
      throw const FalloAutenticacion(
        'El correo electrónico no puede contener espacios.',
      );
    }

    final regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    if (!regexEmail.hasMatch(emailLimpio)) {
      throw const FalloAutenticacion('Ingresa un correo electrónico válido.');
    }

    if (contrasena.isEmpty) {
      throw const FalloAutenticacion('Ingresa una contraseña.');
    }

    if (RegExp(r'\s').hasMatch(contrasena)) {
      throw const FalloAutenticacion(
        'La contraseña no puede contener espacios.',
      );
    }

    if (contrasena.length < 6) {
      throw const FalloAutenticacion(
        'La contraseña debe tener al menos 6 caracteres.',
      );
    }

    final bd = await _cargarBaseDatosUsuarios();

    for (final entry in bd.values) {
      final rawUser = entry['usuario'] as Map<String, dynamic>;
      if ((rawUser['email'] as String? ?? '').trim().toLowerCase() ==
          emailLimpio) {
        throw const FalloAutenticacion(
          'El correo electrónico ya está registrado.',
        );
      }
      if ((rawUser['apodo'] as String? ?? '').trim().toLowerCase() ==
          apodoLimpio.toLowerCase()) {
        throw FalloAutenticacion(
          'El apodo "$apodoLimpio" ya está en uso.',
        );
      }
    }

    final nuevoId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
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
