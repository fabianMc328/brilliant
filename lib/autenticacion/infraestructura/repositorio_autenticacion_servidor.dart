import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../multijugador/infraestructura/descubridor_servidor_local.dart';
import '../../rankings/infraestructura/servicio_rankings.dart';
import '../dominio/repositorio_autenticacion.dart';
import '../dominio/usuario.dart';
import '../dominio/validador_auth.dart';
import 'cliente_http_auth.dart';

/// Autenticación real contra `servidorBrilliant` (Render o LAN), con bloqueo
/// de doble sesión activa (entre dispositivos y entre pestañas), latido de sesión
/// y apodo único por cuenta.
class RepositorioAutenticacionServidor implements RepositorioAutenticacion {
  static const String _claveUsuarioSesion = 'brilliant_auth_usuario_srv_v1';
  static const String _claveTokenSesion = 'brilliant_auth_token_srv_v1';
  static const String _claveDispositivoId = 'brilliant_dispositivo_id_v1';
  static const String _claveUrlServidor = 'brilliant_url_servidor_multi_v1';

  final SharedPreferences? _prefsInyectadas;
  final Future<String?> Function()? _resolverUrlServidor;
  final ClienteHttpAuth _clienteHttp;
  final Duration? _timeoutPeticion;
  final Duration _intervaloHeartbeat;
  Timer? _timerHeartbeat;
  String? _tokenActivoEnMemoria;
  Usuario? _usuarioActivoEnMemoria;

  RepositorioAutenticacionServidor({
    SharedPreferences? preferences,
    Future<String?> Function()? resolverUrlServidor,
    ClienteHttpAuth clienteHttp = const ClienteHttpAuth(),
    Duration? timeoutPeticion,
    Duration intervaloHeartbeat = const Duration(seconds: 20),
  })  : _prefsInyectadas = preferences,
        _resolverUrlServidor = resolverUrlServidor,
        _clienteHttp = clienteHttp,
        _timeoutPeticion = timeoutPeticion,
        _intervaloHeartbeat = intervaloHeartbeat;

  bool get _enPruebasWidget {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  Future<SharedPreferences> _obtenerPrefs() async {
    final inyectadas = _prefsInyectadas;
    if (inyectadas != null) return inyectadas;
    return SharedPreferences.getInstance();
  }

  Future<String> _obtenerOCrearDispositivoId() async {
    final idPestanaWeb = ClienteHttpAuth.obtenerIdInstanciaNavegador();
    if (idPestanaWeb != null && idPestanaWeb.isNotEmpty) {
      return idPestanaWeb;
    }

    final prefs = await _obtenerPrefs();
    final existente = prefs.getString(_claveDispositivoId)?.trim();
    if (existente != null && existente.isNotEmpty) {
      return existente;
    }
    final random = Random();
    final buffer = StringBuffer('disp_');
    for (int i = 0; i < 16; i++) {
      buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    final nuevo = buffer.toString();
    await prefs.setString(_claveDispositivoId, nuevo);
    return nuevo;
  }

  Future<String> _obtenerUrlServidorActiva() async {
    if (_resolverUrlServidor != null) {
      final personalizada = await _resolverUrlServidor!();
      if (personalizada != null && personalizada.trim().isNotEmpty) {
        return personalizada.trim();
      }
      throw const FalloAutenticacion(
        'No se pudo conectar con el servidor de cuentas.',
      );
    }

    final prefs = await _obtenerPrefs();
    final guardada = prefs.getString(_claveUrlServidor)?.trim();
    if (guardada != null && guardada.isNotEmpty) {
      final permitida = !kIsWeb || guardada.startsWith('wss://');
      if (permitida) {
        final activa =
            await DescubridorServidorLocal.verificarServidorActivo(guardada);
        if (activa) {
          return guardada;
        }
      }
    }

    final descubierta =
        await DescubridorServidorLocal.buscarServidorEnRed(incluirNube: true);
    if (descubierta != null && descubierta.trim().isNotEmpty) {
      final urlLimpia = descubierta.trim();
      await prefs.setString(_claveUrlServidor, urlLimpia);
      return urlLimpia;
    }

    throw const FalloAutenticacion(
      'No se pudo conectar con el servidor. Verifica tu internet e inténtalo de nuevo.',
    );
  }

  Future<void> _guardarSesion(
    Usuario usuario,
    String token, {
    Map<String, dynamic>? respaldoCuenta,
  }) async {
    _usuarioActivoEnMemoria = usuario;
    _tokenActivoEnMemoria = token;
    final prefs = await _obtenerPrefs();
    await prefs.setString(_claveUsuarioSesion, jsonEncode(usuario.toJson()));
    await prefs.setString(_claveTokenSesion, token);
    if (respaldoCuenta != null) {
      await ServicioRankings.guardarRespaldoCuentaIndividual(
        respaldoCuenta,
        preferences: prefs,
      );
    }
    _iniciarHeartbeat(token);
  }

  void _iniciarHeartbeat(String token) {
    _timerHeartbeat?.cancel();
    if (_enPruebasWidget) return;

    _timerHeartbeat = Timer.periodic(_intervaloHeartbeat, (_) async {
      try {
        final tokenActual = _tokenActivoEnMemoria;
        if (tokenActual == null || tokenActual != token) {
          _timerHeartbeat?.cancel();
          return;
        }
        final prefs = await _obtenerPrefs();
        final urlServidor = _resolverUrlServidor != null
            ? await _resolverUrlServidor!()
            : prefs.getString(_claveUrlServidor);
        if (urlServidor == null || urlServidor.trim().isEmpty) return;

        final dispId = await _obtenerOCrearDispositivoId();
        final res = await _clienteHttp.enviar(
          metodo: 'GET',
          urlWsOBaseHttp: urlServidor,
          ruta:
              '/auth/sesion?dispositivoId=${Uri.encodeQueryComponent(dispId)}',
          bearerToken: tokenActual,
          timeout: const Duration(seconds: 6),
        );
        if (res.statusCode == 401 || res.statusCode == 403) {
          _timerHeartbeat?.cancel();
          _tokenActivoEnMemoria = null;
          _usuarioActivoEnMemoria = null;
          if (prefs.getString(_claveTokenSesion) == tokenActual) {
            await prefs.remove(_claveUsuarioSesion);
            await prefs.remove(_claveTokenSesion);
          }
        }
      } catch (_) {}
    });
  }

  @override
  Future<Usuario?> obtenerUsuarioSesion() async {
    final prefs = await _obtenerPrefs();
    final rawJson = prefs.getString(_claveUsuarioSesion);
    final token = _tokenActivoEnMemoria ?? prefs.getString(_claveTokenSesion);
    if (rawJson == null ||
        rawJson.trim().isEmpty ||
        token == null ||
        token.trim().isEmpty) {
      return null;
    }

    Usuario usuarioLocal;
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      usuarioLocal = _usuarioActivoEnMemoria ?? Usuario.fromJson(decoded);
    } catch (_) {
      await prefs.remove(_claveUsuarioSesion);
      await prefs.remove(_claveTokenSesion);
      return null;
    }

    RespuestaHttpAuth respuesta;
    String urlServidor;
    String dispId;
    try {
      urlServidor = await _obtenerUrlServidorActiva();
      dispId = await _obtenerOCrearDispositivoId();
      respuesta = await _clienteHttp.enviar(
        metodo: 'GET',
        urlWsOBaseHttp: urlServidor,
        ruta: '/auth/sesion?dispositivoId=${Uri.encodeQueryComponent(dispId)}',
        bearerToken: token,
        timeout: _timeoutPeticion,
      );
    } catch (_) {
      return null;
    }

    // Si el contenedor gratuito de Render despertó de inactividad en 0, re-hidratar
    // las cuentas respaldadas en SharedPreferences y restaurar la sesión activa.
    if (respuesta.statusCode == 401) {
      final respaldadas = ServicioRankings.obtenerCuentasRespaldadasSync(prefs);
      if (respaldadas.isNotEmpty) {
        try {
          final syncRes = await _clienteHttp.enviar(
            metodo: 'POST',
            urlWsOBaseHttp: urlServidor,
            ruta: '/rankings/sincronizar',
            cuerpoJson: {
              'cuentas': respaldadas,
              'sesionActiva': {
                'token': token,
                'apodo': usuarioLocal.apodo,
                'dispositivoId': dispId,
              },
            },
            timeout: _timeoutPeticion,
          );
          if (syncRes.statusCode == 200) {
            respuesta = await _clienteHttp.enviar(
              metodo: 'GET',
              urlWsOBaseHttp: urlServidor,
              ruta:
                  '/auth/sesion?dispositivoId=${Uri.encodeQueryComponent(dispId)}',
              bearerToken: token,
              timeout: _timeoutPeticion,
            );
          }
        } catch (_) {}
      }
    }

    if (respuesta.statusCode == 200) {
      final rawRemoto = respuesta.datos['usuario'];
      final rawRespaldo = respuesta.datos['respaldoCuenta'];
      if (rawRespaldo is Map<String, dynamic>) {
        await ServicioRankings.guardarRespaldoCuentaIndividual(
          rawRespaldo,
          preferences: prefs,
        );
      }
      final verificado = rawRemoto is Map<String, dynamic>
          ? Usuario.fromJson(rawRemoto)
          : usuarioLocal;
      _usuarioActivoEnMemoria = verificado;
      _tokenActivoEnMemoria = token;
      await prefs.setString(
        _claveUsuarioSesion,
        jsonEncode(verificado.toJson()),
      );
      _iniciarHeartbeat(token);
      return verificado;
    }

    if (respuesta.statusCode == 409) {
      // La sesión pertenece a otra pestaña o dispositivo activo: no borrar el token de la otra pestaña,
      // pero impedir que esta nueva pestaña entre automáticamente y avisar al usuario.
      _timerHeartbeat?.cancel();
      _tokenActivoEnMemoria = null;
      _usuarioActivoEnMemoria = null;
      final mensaje = (respuesta.datos['error'] as String?)?.trim();
      throw FalloAutenticacion(
        (mensaje != null && mensaje.isNotEmpty)
            ? mensaje
            : 'Ya hay una cuenta conectada en otra pestaña o dispositivo. Inicia sesión con otra cuenta.',
      );
    }

    _timerHeartbeat?.cancel();
    _tokenActivoEnMemoria = null;
    _usuarioActivoEnMemoria = null;
    await prefs.remove(_claveUsuarioSesion);
    await prefs.remove(_claveTokenSesion);
    return null;
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

    final dispositivoId = await _obtenerOCrearDispositivoId();
    return _ejecutarAuth(
      ruta: '/auth/login',
      cuerpo: {
        'identificador': identificador.trim(),
        'contrasena': contrasena,
        'dispositivoId': dispositivoId,
      },
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

    final dispositivoId = await _obtenerOCrearDispositivoId();
    return _ejecutarAuth(
      ruta: '/auth/registro',
      cuerpo: {
        'apodo': apodo.trim(),
        'email': email.trim().toLowerCase(),
        'contrasena': contrasena,
        'dispositivoId': dispositivoId,
      },
    );
  }

  Future<Usuario> _ejecutarAuth({
    required String ruta,
    required Map<String, dynamic> cuerpo,
  }) async {
    final urlServidor = await _obtenerUrlServidorActiva();

    RespuestaHttpAuth respuesta;
    try {
      respuesta = await _clienteHttp.enviar(
        metodo: 'POST',
        urlWsOBaseHttp: urlServidor,
        ruta: ruta,
        cuerpoJson: cuerpo,
        timeout: _timeoutPeticion,
      );
    } on FalloAutenticacion {
      rethrow;
    } catch (_) {
      throw const FalloAutenticacion(
        'No se pudo comunicar con el servidor. Inténtalo de nuevo en unos segundos.',
      );
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      final rawUsuario = respuesta.datos['usuario'];
      final token = respuesta.datos['token'];
      final rawRespaldo = respuesta.datos['respaldoCuenta'];
      if (rawUsuario is Map<String, dynamic> &&
          token is String &&
          token.isNotEmpty) {
        final usuario = Usuario.fromJson(rawUsuario);
        await _guardarSesion(
          usuario,
          token,
          respaldoCuenta:
              rawRespaldo is Map<String, dynamic> ? rawRespaldo : null,
        );
        return usuario;
      }
      throw const FalloAutenticacion(
        'Respuesta inesperada del servidor de cuentas.',
      );
    }

    final mensaje = respuesta.datos['error'] as String?;
    throw FalloAutenticacion(
      (mensaje != null && mensaje.trim().isNotEmpty)
          ? mensaje.trim()
          : 'No se pudo completar la autenticación (${respuesta.statusCode}).',
    );
  }

  @override
  Future<void> cerrarSesion() async {
    _timerHeartbeat?.cancel();
    _timerHeartbeat = null;

    final prefs = await _obtenerPrefs();
    final token = _tokenActivoEnMemoria ?? prefs.getString(_claveTokenSesion);
    _tokenActivoEnMemoria = null;
    _usuarioActivoEnMemoria = null;

    if (token != null && token.isNotEmpty) {
      try {
        final urlServidor = _resolverUrlServidor != null
            ? await _resolverUrlServidor!()
            : prefs.getString(_claveUrlServidor);
        if (urlServidor != null && urlServidor.trim().isNotEmpty) {
          await _clienteHttp.enviar(
            metodo: 'POST',
            urlWsOBaseHttp: urlServidor,
            ruta: '/auth/logout',
            bearerToken: token,
            timeout: const Duration(seconds: 3),
          );
        }
      } catch (_) {}
    }

    if (prefs.getString(_claveTokenSesion) == token) {
      await prefs.remove(_claveUsuarioSesion);
      await prefs.remove(_claveTokenSesion);
    }
  }
}
