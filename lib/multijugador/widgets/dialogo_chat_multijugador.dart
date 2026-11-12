import 'dart:async';
import 'package:flutter/material.dart';

import '../bloc/lobby_bloc.dart';
import '../bloc/lobby_estado.dart';
import '../bloc/lobby_evento.dart';
import '../bloc/partida_multijugador_bloc.dart';
import '../bloc/partida_multijugador_estado.dart';
import '../bloc/partida_multijugador_evento.dart';
import '../dominio/mensajes_protocolo.dart';

/// Diálogo modal / bottom sheet para el chat en tiempo real del lobby y de la partida.
/// Totalmente reactivo a nuevos mensajes mediante stream en vivo sin requerir reabrir el diálogo.
class DialogoChatMultijugador extends StatefulWidget {
  final List<MensajeChat> mensajesIniciales;
  final Stream<List<MensajeChat>>? flujoHistorial;
  final String miJugadorId;
  final void Function(String texto) onEnviarMensaje;

  const DialogoChatMultijugador({
    super.key,
    required this.mensajesIniciales,
    this.flujoHistorial,
    required this.miJugadorId,
    required this.onEnviarMensaje,
  });

  /// Abre el chat reactivo dentro de la sala de espera (Lobby).
  static Future<void> mostrarParaLobby({
    required BuildContext context,
    required LobbyBloc lobbyBloc,
  }) {
    final estado = lobbyBloc.state;
    final miId = estado is LobbyEnSalaEspera ? estado.sala.miJugadorId : '';
    final iniciales = estado is LobbyEnSalaEspera ? estado.historialChat : const <MensajeChat>[];

    final flujo = lobbyBloc.stream
        .where((s) => s is LobbyEnSalaEspera)
        .map((s) => (s as LobbyEnSalaEspera).historialChat);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DialogoChatMultijugador(
        mensajesIniciales: iniciales,
        flujoHistorial: flujo,
        miJugadorId: miId,
        onEnviarMensaje: (texto) => lobbyBloc.add(EnviarMensajeChatLobby(texto)),
      ),
    );
  }

  /// Abre el chat reactivo durante la partida en curso.
  static Future<void> mostrarParaPartida({
    required BuildContext context,
    required PartidaMultijugadorBloc partidaBloc,
  }) {
    final estado = partidaBloc.state;
    final miId = estado is PartidaMultijugadorActiva ? estado.sala.miJugadorId : '';
    final iniciales = estado is PartidaMultijugadorActiva ? estado.historialChat : const <MensajeChat>[];

    final flujo = partidaBloc.stream
        .where((s) => s is PartidaMultijugadorActiva)
        .map((s) => (s as PartidaMultijugadorActiva).historialChat);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DialogoChatMultijugador(
        mensajesIniciales: iniciales,
        flujoHistorial: flujo,
        miJugadorId: miId,
        onEnviarMensaje: (texto) =>
            partidaBloc.add(EnviarMensajeChatPartida(texto)),
      ),
    );
  }

  /// Método genérico mantenido por compatibilidad.
  static Future<void> mostrar({
    required BuildContext context,
    required List<MensajeChat> mensajes,
    Stream<List<MensajeChat>>? flujoHistorial,
    required String miJugadorId,
    required void Function(String texto) onEnviarMensaje,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DialogoChatMultijugador(
        mensajesIniciales: mensajes,
        flujoHistorial: flujoHistorial,
        miJugadorId: miJugadorId,
        onEnviarMensaje: onEnviarMensaje,
      ),
    );
  }

  @override
  State<DialogoChatMultijugador> createState() =>
      _DialogoChatMultijugadorState();
}

class _DialogoChatMultijugadorState extends State<DialogoChatMultijugador> {
  final TextEditingController _controladorTexto = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<MensajeChat> _mensajes;
  StreamSubscription<List<MensajeChat>>? _sub;

  @override
  void initState() {
    super.initState();
    _mensajes = List<MensajeChat>.from(widget.mensajesIniciales);

    _sub = widget.flujoHistorial?.listen((nuevos) {
      if (mounted) {
        setState(() {
          _mensajes = nuevos;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _desplazarAlFinal());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _desplazarAlFinal());
  }

  @override
  void didUpdateWidget(covariant DialogoChatMultijugador oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mensajesIniciales.length != oldWidget.mensajesIniciales.length) {
      _mensajes = List<MensajeChat>.from(widget.mensajesIniciales);
      WidgetsBinding.instance.addPostFrameCallback((_) => _desplazarAlFinal());
    }
  }

  void _desplazarAlFinal() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _enviar() {
    final texto = _controladorTexto.text.trim();
    if (texto.isEmpty) return;
    widget.onEnviarMensaje(texto);
    _controladorTexto.clear();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controladorTexto.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final alturaDisponible = mediaQuery.size.height * 0.72;

    return Container(
      height: alturaDisponible,
      margin: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de título con tirador y botón de cierre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chat de la Sala',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${_mensajes.length} mensajes en esta partida',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar chat',
                ),
              ],
            ),
          ),

          // Lista de mensajes reactiva
          Expanded(
            child: _mensajes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 48,
                          color: Colors.blueGrey.shade200,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay mensajes aún.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¡Envía un saludo a los demás jugadores!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final m = _mensajes[index];
                      if (m.esSistema) {
                        return _BurbujaMensajeSistema(mensaje: m);
                      }
                      final esMio = m.remitenteId == widget.miJugadorId;
                      return _BurbujaMensajeJugador(
                        mensaje: m,
                        esMio: esMio,
                      );
                    },
                  ),
          ),

          // Barra inferior de envío
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('input_texto_chat'),
                      controller: _controladorTexto,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.blueGrey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.blueGrey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.blue.shade700,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('boton_enviar_chat'),
                    onPressed: _enviar,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BurbujaMensajeSistema extends StatelessWidget {
  final MensajeChat mensaje;

  const _BurbujaMensajeSistema({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: Colors.amber.shade900),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                mensaje.texto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurbujaMensajeJugador extends StatelessWidget {
  final MensajeChat mensaje;
  final bool esMio;

  const _BurbujaMensajeJugador({
    required this.mensaje,
    required this.esMio,
  });

  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: esMio ? Colors.blue.shade700 : Colors.blueGrey.shade50,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(esMio ? 14 : 2),
            bottomRight: Radius.circular(esMio ? 2 : 14),
          ),
          border: Border.all(
            color: esMio ? Colors.blue.shade800 : Colors.blueGrey.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!esMio)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  mensaje.remitenteApodo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            Text(
              mensaje.texto,
              style: TextStyle(
                fontSize: 13,
                color: esMio ? Colors.white : Colors.blueGrey.shade900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatearHora(mensaje.fecha),
              style: TextStyle(
                fontSize: 9.5,
                color: esMio ? Colors.white70 : Colors.blueGrey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
