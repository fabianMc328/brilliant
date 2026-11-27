import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../autenticacion/dominio/validador_auth.dart';
import '../../autenticacion/infraestructura/cliente_http_auth.dart';
import '../../multijugador/constantes_multijugador.dart';
import '../../multijugador/infraestructura/descubridor_servidor_local.dart';
import '../dominio/entrada_ranking.dart';

/// Servicio híbrido (Servidor + SharedPreferences) para consultar, registrar y
/// respaldar automáticamente las cuentas y tablas de Rankings ante reinicios de Render.
class ServicioRankings {
  static const String claveRespaldoCuentas =
      'brilliant_respaldo_cuentas_hibrido_v1';
  static const String claveCacheRankings = 'brilliant_cache_tabla_rankings_v1';
  static const String _claveUrlServidor = 'brilliant_url_servidor_multi_v1';
  static const String _claveTokenSesion = 'brilliant_auth_token_srv_v1';

  final SharedPreferences? _prefsInyectadas;
  final Future<String?> Function()? _resolverUrlServidor;
  final ClienteHttpAuth _clienteHttp;

  const ServicioRankings({
    SharedPreferences? preferences,
    Future<String?> Function()? resolverUrlServidor,
    ClienteHttpAuth clienteHttp = const ClienteHttpAuth(),
  })  : _prefsInyectadas = preferences,
        _resolverUrlServidor = resolverUrlServidor,
        _clienteHttp = clienteHttp;

  Future<SharedPreferences> _obtenerPrefs() async {
    final p = _prefsInyectadas;
    if (p != null) return p;
    return SharedPreferences.getInstance();
  }

  /// Guarda o fusiona en `SharedPreferences` el respaldo cifrado (con sal + SHA-256 y puntos)
  /// de una cuenta individual para sobrevivir reinicios del servidor gratuito.
  static Future<void> guardarRespaldoCuentaIndividual(
    Map<String, dynamic> cuentaJson, {
    SharedPreferences? preferences,
  }) async {
    final apodo = (cuentaJson['apodo'] as String?)?.trim() ?? '';
    if (apodo.isEmpty) return;

    final prefs = preferences ?? await SharedPreferences.getInstance();
    final actuales = _leerMapaCuentasRespaldo(prefs);
    final clave = ValidadorAuth.normalizarApodoClave(apodo);
    final previa = actuales[clave];

    if (previa == null) {
      actuales[clave] = Map<String, dynamic>.from(cuentaJson);
    } else {
      actuales[clave] = _fusionarCuentaRespaldo(previa, cuentaJson);
    }
    await prefs.setString(
      claveRespaldoCuentas,
      jsonEncode(actuales.values.toList()),
    );
  }

  /// Guarda o fusiona una lista completa de cuentas devuelta por el servidor.
  static Future<void> guardarListaRespaldoCuentas(
    List<dynamic> listaRaw, {
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final actuales = _leerMapaCuentasRespaldo(prefs);

    for (final item in listaRaw) {
      if (item is! Map<String, dynamic>) continue;
      final apodo = (item['apodo'] as String?)?.trim() ?? '';
      if (apodo.isEmpty) continue;
      final clave = ValidadorAuth.normalizarApodoClave(apodo);
      final previa = actuales[clave];
      actuales[clave] = previa == null
          ? Map<String, dynamic>.from(item)
          : _fusionarCuentaRespaldo(previa, item);
    }

    await prefs.setString(
      claveRespaldoCuentas,
      jsonEncode(actuales.values.toList()),
    );
  }

  static List<Map<String, dynamic>> obtenerCuentasRespaldadasSync(
    SharedPreferences prefs,
  ) {
    return _leerMapaCuentasRespaldo(prefs).values.toList();
  }

  static Map<String, Map<String, dynamic>> _leerMapaCuentasRespaldo(
    SharedPreferences prefs,
  ) {
    final raw = prefs.getString(claveRespaldoCuentas);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      final mapa = <String, Map<String, dynamic>>{};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final apodo = (item['apodo'] as String?)?.trim() ?? '';
          if (apodo.isNotEmpty) {
            mapa[ValidadorAuth.normalizarApodoClave(apodo)] = item;
          }
        }
      }
      return mapa;
    } catch (_) {
      return {};
    }
  }

  static Map<String, dynamic> _fusionarCuentaRespaldo(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    int maxCampo(String campo) {
      final va = (a[campo] as num?)?.toInt() ?? 0;
      final vb = (b[campo] as num?)?.toInt() ?? 0;
      return max(va, vb);
    }

    return {
      ...a,
      ...b,
      'victoriasMulti': maxCampo('victoriasMulti'),
      'partidasMulti': maxCampo('partidasMulti'),
      'puntosTotalesMulti': maxCampo('puntosTotalesMulti'),
      'mejorPuntajeMulti': maxCampo('mejorPuntajeMulti'),
      'mejorPuntajeSolitario': maxCampo('mejorPuntajeSolitario'),
      'partidasSolitario': maxCampo('partidasSolitario'),
    };
  }

  bool get _enPruebasWidget {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  Future<String?> _obtenerUrlServidor() async {
    if (_resolverUrlServidor != null) {
      final url = await _resolverUrlServidor!();
      if (url != null && url.trim().isNotEmpty) return url.trim();
      return null;
    }
    if (_enPruebasWidget) {
      return null;
    }
    final prefs = await _obtenerPrefs();
    final guardada = prefs.getString(_claveUrlServidor)?.trim();
    if (guardada != null && guardada.isNotEmpty) {
      if (!kIsWeb || guardada.startsWith('wss://')) {
        return guardada;
      }
    }
    final descubierta =
        await DescubridorServidorLocal.buscarServidorEnRed(incluirNube: true);
    if (descubierta != null && descubierta.trim().isNotEmpty) {
      await prefs.setString(_claveUrlServidor, descubierta.trim());
      return descubierta.trim();
    }
    return ConstantesMultijugador.urlServidorNubePorDefecto;
  }

  /// Obtiene la tabla de Rankings sincronizando primero el respaldo local con el servidor.
  Future<TablaRankings> obtenerRankings() async {
    final prefs = await _obtenerPrefs();
    final respaldadas = obtenerCuentasRespaldadasSync(prefs);

    try {
      final urlServidor = await _obtenerUrlServidor();
      if (urlServidor == null) {
        return _construirDesdeCacheORespaldoLocal(prefs);
      }
      final RespuestaHttpAuth respuesta;
      if (respaldadas.isNotEmpty) {
        respuesta = await _clienteHttp.enviar(
          metodo: 'POST',
          urlWsOBaseHttp: urlServidor,
          ruta: '/rankings/sincronizar',
          cuerpoJson: {'cuentas': respaldadas},
        );
      } else {
        respuesta = await _clienteHttp.enviar(
          metodo: 'GET',
          urlWsOBaseHttp: urlServidor,
          ruta: '/rankings',
        );
      }

      if (respuesta.statusCode == 200) {
        await _procesarYGuardarRespuestaRankings(respuesta.datos, prefs);
        return TablaRankings.fromJson(respuesta.datos);
      }
    } catch (_) {}

    return _construirDesdeCacheORespaldoLocal(prefs);
  }

  /// Registra el puntaje de una partida completada en Modo Solitario tanto en el
  /// respaldo local de `SharedPreferences` como en el servidor.
  Future<TablaRankings> registrarPuntajeSolitario({
    required String apodo,
    required int puntaje,
  }) async {
    final prefs = await _obtenerPrefs();
    final apodoLimpio = apodo.trim();
    final pts = max(0, puntaje);

    // 1. Actualizar inmediatamente en el respaldo local de SharedPreferences
    final mapaRespaldo = _leerMapaCuentasRespaldo(prefs);
    final clave = ValidadorAuth.normalizarApodoClave(apodoLimpio);
    final cuentaLocal = mapaRespaldo[clave];
    if (cuentaLocal != null) {
      final mejorPrevio =
          (cuentaLocal['mejorPuntajeSolitario'] as num?)?.toInt() ?? 0;
      final partidasPrevias =
          (cuentaLocal['partidasSolitario'] as num?)?.toInt() ?? 0;
      cuentaLocal['mejorPuntajeSolitario'] = max(mejorPrevio, pts);
      cuentaLocal['partidasSolitario'] = partidasPrevias + 1;
      await prefs.setString(
        claveRespaldoCuentas,
        jsonEncode(mapaRespaldo.values.toList()),
      );
    }

    // 2. Sincronizar y registrar en el servidor
    try {
      final urlServidor = await _obtenerUrlServidor();
      if (urlServidor == null) {
        return _construirDesdeCacheORespaldoLocal(prefs);
      }
      final token = prefs.getString(_claveTokenSesion);
      final respaldadas = mapaRespaldo.values.toList();
      if (respaldadas.isNotEmpty) {
        await _clienteHttp.enviar(
          metodo: 'POST',
          urlWsOBaseHttp: urlServidor,
          ruta: '/rankings/sincronizar',
          cuerpoJson: {'cuentas': respaldadas},
        );
      }
      final respuesta = await _clienteHttp.enviar(
        metodo: 'POST',
        urlWsOBaseHttp: urlServidor,
        ruta: '/rankings/solitario',
        bearerToken: token,
        cuerpoJson: {
          'apodo': apodoLimpio,
          'puntaje': pts,
        },
      );
      if (respuesta.statusCode == 200) {
        final rawRankings = respuesta.datos['rankings'];
        if (rawRankings is Map<String, dynamic>) {
          await _procesarYGuardarRespuestaRankings(rawRankings, prefs);
          return TablaRankings.fromJson(rawRankings);
        }
      }
    } catch (_) {}

    return _construirDesdeCacheORespaldoLocal(prefs);
  }

  Future<void> _procesarYGuardarRespuestaRankings(
    Map<String, dynamic> datos,
    SharedPreferences prefs,
  ) async {
    final respaldoServidor = datos['respaldoCuentas'];
    if (respaldoServidor is List) {
      await guardarListaRespaldoCuentas(
        respaldoServidor,
        preferences: prefs,
      );
    }
    final tabla = TablaRankings.fromJson(datos);
    await prefs.setString(claveCacheRankings, jsonEncode(tabla.toJson()));
  }

  TablaRankings _construirDesdeCacheORespaldoLocal(SharedPreferences prefs) {
    final rawCache = prefs.getString(claveCacheRankings);
    if (rawCache != null && rawCache.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCache) as Map<String, dynamic>;
        return TablaRankings.fromJson(decoded);
      } catch (_) {}
    }

    final cuentas = obtenerCuentasRespaldadasSync(prefs)
        .map(EntradaRanking.fromJson)
        .toList();
    if (cuentas.isEmpty) return TablaRankings.vacia();

    final multi = List<EntradaRanking>.from(cuentas)
      ..sort((a, b) {
        final c1 = b.victoriasMulti.compareTo(a.victoriasMulti);
        if (c1 != 0) return c1;
        final c2 = b.mejorPuntajeMulti.compareTo(a.mejorPuntajeMulti);
        if (c2 != 0) return c2;
        return b.puntosTotalesMulti.compareTo(a.puntosTotalesMulti);
      });
    final sol = List<EntradaRanking>.from(cuentas)
      ..sort(
        (a, b) => b.mejorPuntajeSolitario.compareTo(a.mejorPuntajeSolitario),
      );
    return TablaRankings(multijugador: multi, solitario: sol);
  }
}
