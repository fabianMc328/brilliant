import '../../region.dart';
import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';
import '../dominio/mensajes_protocolo.dart';

abstract class PartidaMultijugadorEvento {
  const PartidaMultijugadorEvento();
}

class EnviarMensajeChatPartida extends PartidaMultijugadorEvento {
  final String texto;
  const EnviarMensajeChatPartida(this.texto);
}

class MensajeChatRecibidoPartidaInterno extends PartidaMultijugadorEvento {
  final MensajeChat mensaje;
  const MensajeChatRecibidoPartidaInterno(this.mensaje);
}

// --- Fase 1: Estrellas iniciales en el mapa compartido ---
class ColocarEstrellaLocal extends PartidaMultijugadorEvento {
  final Coordenada coordenada;
  final int valor;
  const ColocarEstrellaLocal(this.coordenada, this.valor);
}

class LimpiarEstrellasLocales extends PartidaMultijugadorEvento {
  const LimpiarEstrellasLocales();
}

class LlenarEstrellasAleatoriasLocales extends PartidaMultijugadorEvento {
  const LlenarEstrellasAleatoriasLocales();
}

class ConfirmarEstrellasMultijugador extends PartidaMultijugadorEvento {
  const ConfirmarEstrellasMultijugador();
}

// --- Fase 2: Rondas simultáneas de dados y anclas ---
class SeleccionarDadoMultijugador extends PartidaMultijugadorEvento {
  final int indiceDado; // 1 o 2
  final int valor;
  const SeleccionarDadoMultijugador({required this.indiceDado, required this.valor});
}

class SeleccionarAnclaMultijugador extends PartidaMultijugadorEvento {
  final Coordenada coordenada;
  const SeleccionarAnclaMultijugador(this.coordenada);
}

class DeseleccionarAnclaMultijugador extends PartidaMultijugadorEvento {
  const DeseleccionarAnclaMultijugador();
}

class ColocarNumeroMultijugador extends PartidaMultijugadorEvento {
  final Coordenada destino;
  const ColocarNumeroMultijugador(this.destino);
}

class PasarTurnoMultijugador extends PartidaMultijugadorEvento {
  const PasarTurnoMultijugador();
}

// --- Control de partida, concesión y tolerancia a desconexión ---
class SolicitarConcederPartida extends PartidaMultijugadorEvento {
  const SolicitarConcederPartida();
}

class ReintentarReconexionPartida extends PartidaMultijugadorEvento {
  const ReintentarReconexionPartida();
}

class LimpiarAvisoPartida extends PartidaMultijugadorEvento {
  const LimpiarAvisoPartida();
}

class AbandonarSalaMultijugador extends PartidaMultijugadorEvento {
  const AbandonarSalaMultijugador();
}

// --- Eventos internos del flujo de red ---
class EstadoSalaPartidaRecibidoInterno extends PartidaMultijugadorEvento {
  final EstadoSalaMultijugador sala;
  const EstadoSalaPartidaRecibidoInterno(this.sala);
}

class ConexionPartidaRecibidaInterna extends PartidaMultijugadorEvento {
  final EstadoConexionCliente conexion;
  const ConexionPartidaRecibidaInterna(this.conexion);
}

class ErrorPartidaRecibidoInterno extends PartidaMultijugadorEvento {
  final FalloMultijugador fallo;
  const ErrorPartidaRecibidoInterno(this.fallo);
}
