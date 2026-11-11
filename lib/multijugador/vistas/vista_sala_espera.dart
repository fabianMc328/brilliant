import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../niveles/catalogo_niveles.dart';
import '../bloc/lobby_bloc.dart';
import '../bloc/lobby_evento.dart';
import '../constantes_multijugador.dart';
import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';
import '../dominio/jugador_multijugador.dart';
import '../widgets/banner_conexion_red.dart';
import '../widgets/miniatura_mapa_multijugador.dart';

/// Vista en vivo del Lobby (hasta 6 jugadores), código copiable, mapa compartido y botón Listo.
class VistaSalaEspera extends StatelessWidget {
  final EstadoSalaMultijugador sala;
  final EstadoConexionCliente conexion;
  final String? avisoError;

  const VistaSalaEspera({
    super.key,
    required this.sala,
    required this.conexion,
    this.avisoError,
  });

  void _copiarCodigo(BuildContext context) {
    Clipboard.setData(ClipboardData(text: sala.codigoSala));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código ${sala.codigoSala} copiado al portapapeles'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _textoEstadoInicio() {
    if (sala.jugadores.length < ConstantesMultijugador.minJugadoresPartida) {
      return 'Esperando al menos 2 jugadores (${sala.jugadores.length}/6)...';
    }
    if (!sala.todosListosParaIniciar) {
      return 'Todos deben pulsar "Listo" (${sala.cantidadListos}/${sala.jugadores.length})';
    }
    return sala.soyAnfitrion
        ? '¡Todos listos! Ya puedes iniciar la partida.'
        : '¡Todos listos! Esperando que el anfitrión inicie.';
  }

  @override
  Widget build(BuildContext context) {
    final nivelSeleccionado = CatalogoNiveles.porId(sala.nivelId);
    final niveles = CatalogoNiveles.todos;

    return Column(
      children: [
        BannerConexionRed(
          conexion: conexion,
          avisoTemporal: avisoError ?? sala.mensajeEventoReciente,
          onReintentar: () =>
              context.read<LobbyBloc>().add(const ReintentarConexionLobby()),
          onSalirMenu: () =>
              context.read<LobbyBloc>().add(const SalirDelLobby()),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta de código de invitación
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.blue.shade200, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CÓDIGO DE INVITACIÓN',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: Colors.blueGrey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    sala.codigoSala,
                                    key: const Key('texto_codigo_sala'),
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3.5,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            key: const Key('boton_copiar_codigo'),
                            onPressed: () => _copiarCodigo(context),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copiar'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Mapa compartido por todos
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MiniaturaMapaMultijugador(
                                nivel: nivelSeleccionado,
                                tamano: 52,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mapa Compartido: ${nivelSeleccionado.nombre}',
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Dificultad ${nivelSeleccionado.dificultad} • Todos juegan el mismo tablero',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.blueGrey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (sala.soyAnfitrion) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: niveles.map((n) {
                                final seleccionado = n.id == sala.nivelId;
                                return ChoiceChip(
                                  key: Key('lobby_mapa_${n.id}'),
                                  label: Text(
                                    n.nombre,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  selected: seleccionado,
                                  onSelected: (_) {
                                    context
                                        .read<LobbyBloc>()
                                        .add(CambiarNivelLobby(n.id));
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lista de los 6 lugares de jugadores
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Jugadores (${sala.jugadores.length}/${ConstantesMultijugador.maxJugadoresSala})',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Listos: ${sala.cantidadListos}/${sala.jugadores.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: sala.todosListosParaIniciar
                                        ? const Color(0xFF059669)
                                        : Colors.blueGrey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(
                            ConstantesMultijugador.maxJugadoresSala,
                            (index) {
                              if (index < sala.jugadores.length) {
                                final j = sala.jugadores[index];
                                return _FilaJugadorLobby(
                                  jugador: j,
                                  esYo: j.id == sala.miJugadorId,
                                );
                              }
                              return _FilaSlotVacio(numeroSlot: index + 1);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Barra inferior: Botón Listo (todos) + Iniciar Partida (anfitrión cuando 100% listos)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _textoEstadoInicio(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      key: const Key('boton_alternar_listo'),
                      onPressed: conexion.tipo == TipoEstadoConexionCliente.conectado
                          ? () => context
                              .read<LobbyBloc>()
                              .add(AlternarEstadoListoLobby(!sala.estoyListo))
                          : null,
                      icon: Icon(
                        sala.estoyListo
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                      ),
                      label: Text(
                        sala.estoyListo ? '¡Estoy Listo!' : 'Marcar Listo',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sala.estoyListo
                            ? const Color(0xFF059669)
                            : Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (sala.soyAnfitrion)
                      ElevatedButton.icon(
                        key: const Key('boton_iniciar_partida_multi'),
                        onPressed: sala.todosListosParaIniciar
                            ? () => context
                                .read<LobbyBloc>()
                                .add(const SolicitarIniciarPartidaLobby())
                            : null,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Comenzar Partida'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaJugadorLobby extends StatelessWidget {
  final ResumenJugador jugador;
  final bool esYo;

  const _FilaJugadorLobby({
    required this.jugador,
    required this.esYo,
  });

  @override
  Widget build(BuildContext context) {
    final reconectando =
        jugador.participacion == EstadoParticipacion.reconectando;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: esYo ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esYo ? Colors.blue.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            jugador.esAnfitrion ? Icons.workspace_premium_rounded : Icons.person,
            size: 18,
            color: jugador.esAnfitrion
                ? Colors.amber.shade700
                : Colors.blueGrey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${jugador.apodo}${esYo ? ' (Tú)' : ''}${jugador.esAnfitrion ? ' • Anfitrión' : ''}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (reconectando)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reconectando...',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber.shade900,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: jugador.estaListo
                    ? const Color(0xFFD1FAE5)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                jugador.estaListo ? 'LISTO' : 'ESPERANDO',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: jugador.estaListo
                      ? const Color(0xFF065F46)
                      : Colors.blueGrey.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaSlotVacio extends StatelessWidget {
  final int numeroSlot;

  const _FilaSlotVacio({required this.numeroSlot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueGrey.shade100,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person_add_disabled_outlined,
              size: 16, color: Colors.blueGrey.shade300),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Espacio $numeroSlot disponible',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
