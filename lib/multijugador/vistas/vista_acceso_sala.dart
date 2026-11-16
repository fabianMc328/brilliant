import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../niveles/catalogo_niveles.dart';
import '../bloc/lobby_bloc.dart';
import '../bloc/lobby_evento.dart';
import '../constantes_multijugador.dart';
import '../infraestructura/descubridor_servidor_local.dart';
import '../widgets/dialogo_selector_mapa_multijugador.dart';
import '../widgets/miniatura_mapa_multijugador.dart';

/// Formulario responsivo para ingresar apodo, crear sala o unirse mediante código
/// conectándose al servidor externo `servidorBrilliant`.
class VistaAccesoSala extends StatefulWidget {
  final String urlServidorActual;
  final String? mensajeError;
  final String? apodoInicial;
  final Future<String?> Function()? buscadorServidor;
  final bool estaCargando;
  final String? descripcionCarga;

  const VistaAccesoSala({
    super.key,
    required this.urlServidorActual,
    this.mensajeError,
    this.apodoInicial,
    this.buscadorServidor,
    this.estaCargando = false,
    this.descripcionCarga,
  });

  @override
  State<VistaAccesoSala> createState() => _VistaAccesoSalaState();
}

class _VistaAccesoSalaState extends State<VistaAccesoSala> {
  static const String _claveUrlGuardada = 'brilliant_url_servidor_multi_v1';

  late final TextEditingController _apodoCtrl;
  final TextEditingController _codigoCtrl = TextEditingController();
  late String _urlServidor;
  String _nivelInicialSeleccionado = 'nivel_1';
  bool _buscandoServidor = false;
  bool? _servidorDetectadoConExito;

  @override
  void initState() {
    super.initState();
    _apodoCtrl = TextEditingController(text: widget.apodoInicial ?? '');
    _urlServidor = widget.urlServidorActual;
    if (widget.buscadorServidor != null || !_enPruebasWidget) {
      _buscandoServidor = true;
    }
    _inicializarConexion();
  }

  bool get _enPruebasWidget =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  Future<void> _inicializarConexion() async {
    final urlVerificada = await _cargarYVerificarUrlGuardada();
    if (!mounted) return;
    if (urlVerificada != null) {
      setState(() {
        _urlServidor = urlVerificada;
        _buscandoServidor = false;
        _servidorDetectadoConExito = true;
      });
      context.read<LobbyBloc>().add(CambiarUrlServidorLobby(urlVerificada));
      return;
    }
    if (widget.buscadorServidor != null || !_enPruebasWidget) {
      await _buscarServidorAutomaticamente(silencioso: true, forzar: true);
    }
  }

  @override
  void didUpdateWidget(covariant VistaAccesoSala oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.urlServidorActual != oldWidget.urlServidorActual &&
        widget.urlServidorActual.isNotEmpty) {
      _urlServidor = widget.urlServidorActual;
    }
  }

  Future<String?> _cargarYVerificarUrlGuardada() async {
    if (_enPruebasWidget) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardada = prefs.getString(_claveUrlGuardada)?.trim();
      if (guardada != null && guardada.isNotEmpty) {
        final activa =
            await DescubridorServidorLocal.verificarServidorActivo(guardada);
        if (activa) return guardada;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _guardarUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveUrlGuardada, url);
    } catch (_) {}
  }

  Future<void> _buscarServidorAutomaticamente({
    bool silencioso = false,
    bool forzar = false,
  }) async {
    if (_buscandoServidor && !forzar) return;
    setState(() {
      _buscandoServidor = true;
      _servidorDetectadoConExito = null;
    });

    final buscador =
        widget.buscadorServidor ?? DescubridorServidorLocal.buscarServidorEnRed;
    final encontrada = await buscador();

    if (!mounted) return;
    if (encontrada != null && encontrada.isNotEmpty) {
      setState(() {
        _buscandoServidor = false;
        _urlServidor = encontrada;
        _servidorDetectadoConExito = true;
      });
      context.read<LobbyBloc>().add(CambiarUrlServidorLobby(encontrada));
      _guardarUrl(encontrada);
    } else {
      setState(() {
        _buscandoServidor = false;
        _servidorDetectadoConExito = false;
      });
    }
  }

  @override
  void dispose() {
    _apodoCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _aplicarUrlYEjecutar(VoidCallback accion) async {
    if (widget.estaCargando) return;
    final esDispositivoIo = !kIsWeb && !_enPruebasWidget;

    if (esDispositivoIo &&
        (_urlServidor.isEmpty ||
            _urlServidor.contains('localhost') ||
            _servidorDetectadoConExito != true)) {
      await _buscarServidorAutomaticamente(silencioso: true, forzar: true);
      if (!mounted) return;
    }

    if (_urlServidor.isNotEmpty) {
      context.read<LobbyBloc>().add(CambiarUrlServidorLobby(_urlServidor));
      _guardarUrl(_urlServidor);
    }
    accion();
  }

  void _enviarCrearSala() {
    _aplicarUrlYEjecutar(() {
      context.read<LobbyBloc>().add(
            SolicitarCrearSala(
              apodo: _apodoCtrl.text,
              nivelId: _nivelInicialSeleccionado,
            ),
          );
    });
  }

  void _enviarUnirseASala() {
    _aplicarUrlYEjecutar(() {
      context.read<LobbyBloc>().add(
            SolicitarUnirseASala(
              codigoSala: _codigoCtrl.text.trim().toUpperCase(),
              apodo: _apodoCtrl.text,
            ),
          );
    });
  }

  String _extraerIpServidor(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host;
    }
    return url
        .replaceFirst(RegExp(r'^wss?://'), '')
        .split(':')
        .first;
  }

  Future<void> _abrirSelectorMapa() async {
    final elegido = await DialogoSelectorMapaMultijugador.mostrar(
      context,
      nivelActualId: _nivelInicialSeleccionado,
    );
    if (elegido != null && mounted) {
      setState(() => _nivelInicialSeleccionado = elegido);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nivelSeleccionado = CatalogoNiveles.porId(_nivelInicialSeleccionado);
    final ipVisible = _extraerIpServidor(_urlServidor);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.estaCargando) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.descripcionCarga ??
                                  'Conectando con el servidor...',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.mensajeError != null) ...[
                Container(
                  key: const Key('alerta_error_lobby'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.mensajeError!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 1. Apodo del jugador
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu Nombre de Jugador',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('campo_apodo_multijugador'),
                      controller: _apodoCtrl,
                      maxLength: ConstantesMultijugador.maxLongitudApodo,
                      decoration: InputDecoration(
                        hintText: 'Ej. Fabian',
                        counterText: '',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Crear Sala
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Crear Sala (2 a 6 Jugadores)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elige el mapa inicial que jugarán todos y comparte el código.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      key: const Key('boton_seleccionar_mapa_crear'),
                      onTap: _abrirSelectorMapa,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1.3,
                          ),
                        ),
                        child: Row(
                          children: [
                            MiniaturaMapaMultijugador(
                              nivel: nivelSeleccionado,
                              tamano: 50,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Seleccionar mapa',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${nivelSeleccionado.nombre} • ${nivelSeleccionado.dificultad}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.grid_view_rounded,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      key: const Key('boton_crear_sala'),
                      onPressed: widget.estaCargando ? null : _enviarCrearSala,
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Crear Sala Nueva'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Unirse con Código
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Unirse con Código de Invitación',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('campo_codigo_invitacion'),
                      controller: _codigoCtrl,
                      maxLength: ConstantesMultijugador.longitudCodigoSala,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      onSubmitted: (_) => _enviarUnirseASala(),
                      decoration: InputDecoration(
                        hintText: 'Código de 6 letras (ej. K7M4P9)',
                        counterText: '',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      key: const Key('boton_unirse_sala'),
                      onPressed:
                          widget.estaCargando ? null : _enviarUnirseASala,
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Entrar a la Sala'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 4. Estado automático de conexión al servidor
              InkWell(
                key: const Key('estado_busqueda_servidor'),
                onTap: _buscandoServidor
                    ? null
                    : () => _buscarServidorAutomaticamente(silencioso: false),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _buscandoServidor
                        ? Colors.blue.shade50
                        : (_servidorDetectadoConExito == false
                            ? Colors.amber.shade50
                            : const Color(0xFFD1FAE5)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _buscandoServidor
                          ? Colors.blue.shade200
                          : (_servidorDetectadoConExito == false
                              ? Colors.amber.shade300
                              : const Color(0xFF34D399)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_buscandoServidor)
                        const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _servidorDetectadoConExito == false
                              ? Icons.wifi_find_rounded
                              : Icons.wifi_tethering_rounded,
                          size: 18,
                          color: _servidorDetectadoConExito == false
                              ? Colors.amber.shade900
                              : const Color(0xFF065F46),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _buscandoServidor
                              ? 'Buscando servidor en la red...'
                              : (_servidorDetectadoConExito == false
                                  ? 'No se encontró servidor en la red • Toca para reintentar'
                                  : 'Conectado al servidor: $ipVisible'),
                          key: const Key('texto_conectado_servidor'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _buscandoServidor
                                ? Colors.blue.shade900
                                : (_servidorDetectadoConExito == false
                                    ? Colors.amber.shade900
                                    : const Color(0xFF065F46)),
                          ),
                        ),
                      ),
                      if (!_buscandoServidor)
                        Icon(
                          Icons.refresh_rounded,
                          size: 17,
                          color: _servidorDetectadoConExito == false
                              ? Colors.amber.shade900
                              : const Color(0xFF065F46),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
