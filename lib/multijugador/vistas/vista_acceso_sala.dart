import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../niveles/catalogo_niveles.dart';
import '../bloc/lobby_bloc.dart';
import '../bloc/lobby_evento.dart';
import '../constantes_multijugador.dart';

/// Formulario responsivo para ingresar apodo, crear sala o unirse mediante código
/// conectándose al servidor externo `servidorBrilliant`.
class VistaAccesoSala extends StatefulWidget {
  final String urlServidorActual;
  final String? mensajeError;
  final String? apodoInicial;

  const VistaAccesoSala({
    super.key,
    required this.urlServidorActual,
    this.mensajeError,
    this.apodoInicial,
  });

  @override
  State<VistaAccesoSala> createState() => _VistaAccesoSalaState();
}

class _VistaAccesoSalaState extends State<VistaAccesoSala> {
  late final TextEditingController _apodoCtrl;
  final TextEditingController _codigoCtrl = TextEditingController();
  late final TextEditingController _urlCtrl;
  String _nivelInicialSeleccionado = 'nivel_1';
  bool _mostrarConfigRed = false;

  @override
  void initState() {
    super.initState();
    _apodoCtrl = TextEditingController(text: widget.apodoInicial ?? '');
    _urlCtrl = TextEditingController(text: widget.urlServidorActual);
  }

  @override
  void dispose() {
    _apodoCtrl.dispose();
    _codigoCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _seleccionarPresetUrl(String url) {
    setState(() => _urlCtrl.text = url);
    context.read<LobbyBloc>().add(CambiarUrlServidorLobby(url));
  }

  void _aplicarUrlYEjecutar(VoidCallback accion) {
    final nuevaUrl = _urlCtrl.text.trim();
    if (nuevaUrl.isNotEmpty) {
      context.read<LobbyBloc>().add(CambiarUrlServidorLobby(nuevaUrl));
    }
    accion();
  }

  @override
  Widget build(BuildContext context) {
    final niveles = CatalogoNiveles.todos;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: niveles.map((n) {
                        final activo = _nivelInicialSeleccionado == n.id;
                        return ChoiceChip(
                          key: Key('chip_crear_${n.id}'),
                          label: Text(n.nombre),
                          selected: activo,
                          onSelected: (_) {
                            setState(() => _nivelInicialSeleccionado = n.id);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      key: const Key('boton_crear_sala'),
                      onPressed: () => _aplicarUrlYEjecutar(() {
                        context.read<LobbyBloc>().add(
                              SolicitarCrearSala(
                                apodo: _apodoCtrl.text,
                                nivelId: _nivelInicialSeleccionado,
                              ),
                            );
                      }),
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
                      onPressed: () => _aplicarUrlYEjecutar(() {
                        context.read<LobbyBloc>().add(
                              SolicitarUnirseASala(
                                codigoSala: _codigoCtrl.text,
                                apodo: _apodoCtrl.text,
                              ),
                            );
                      }),
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

              // 4. Ajustes de Conexión a servidorBrilliant
              TextButton.icon(
                key: const Key('boton_mostrar_config_red'),
                onPressed: () =>
                    setState(() => _mostrarConfigRed = !_mostrarConfigRed),
                icon: Icon(
                  _mostrarConfigRed
                      ? Icons.expand_less_rounded
                      : Icons.settings_ethernet_rounded,
                  size: 18,
                ),
                label: Text(
                  _mostrarConfigRed
                      ? 'Ocultar ajustes de conexión'
                      : 'Servidor (${_urlCtrl.text})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (_mostrarConfigRed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blueGrey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const Key('campo_url_servidor'),
                        controller: _urlCtrl,
                        decoration: InputDecoration(
                          labelText: 'URL WebSocket de servidorBrilliant',
                          hintText: ConstantesMultijugador.urlServidorLocalPorDefecto,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            key: const Key('chip_preset_localhost'),
                            label: const Text(
                              'Local / Web (localhost)',
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () => _seleccionarPresetUrl(
                              ConstantesMultijugador.urlServidorLocalPorDefecto,
                            ),
                          ),
                          ActionChip(
                            key: const Key('chip_preset_emulador'),
                            label: const Text(
                              'Emulador Android (10.0.2.2)',
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () => _seleccionarPresetUrl(
                              ConstantesMultijugador.urlServidorAndroidEmulador,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
