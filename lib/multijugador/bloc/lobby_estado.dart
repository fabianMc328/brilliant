import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';
import '../dominio/mensajes_protocolo.dart';

abstract class LobbyEstado {
  final String urlServidor;
  const LobbyEstado({required this.urlServidor});
}

/// Pantalla previa de acceso (crear sala o ingresar código de invitación).
class LobbyAccesoInicial extends LobbyEstado {
  final String? mensajeError;

  const LobbyAccesoInicial({
    required super.urlServidor,
    this.mensajeError,
  });

  LobbyAccesoInicial copiarCon({
    String? urlServidor,
    String? mensajeError,
    bool limpiarError = false,
  }) {
    return LobbyAccesoInicial(
      urlServidor: urlServidor ?? this.urlServidor,
      mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
    );
  }
}

/// Estado transitorio mientras se establece conexión y se crea/une a la sala.
class LobbyCargando extends LobbyEstado {
  final String descripcion;

  const LobbyCargando({
    required super.urlServidor,
    required this.descripcion,
  });
}

/// Dentro del lobby de 2 a 6 jugadores esperando confirmación del botón "Listo".
class LobbyEnSalaEspera extends LobbyEstado {
  final EstadoSalaMultijugador sala;
  final EstadoConexionCliente conexion;
  final List<MensajeChat> historialChat;
  final String? avisoError;

  const LobbyEnSalaEspera({
    required super.urlServidor,
    required this.sala,
    required this.conexion,
    this.historialChat = const [],
    this.avisoError,
  });

  LobbyEnSalaEspera copiarCon({
    EstadoSalaMultijugador? sala,
    EstadoConexionCliente? conexion,
    List<MensajeChat>? historialChat,
    String? avisoError,
    bool limpiarAviso = false,
  }) {
    return LobbyEnSalaEspera(
      urlServidor: urlServidor,
      sala: sala ?? this.sala,
      conexion: conexion ?? this.conexion,
      historialChat: historialChat ?? this.historialChat,
      avisoError: limpiarAviso ? null : (avisoError ?? this.avisoError),
    );
  }
}

/// Emitido cuando la sala pasa a la fase de juego para disparar la navegación.
class LobbyTransicionAPartida extends LobbyEstado {
  final EstadoSalaMultijugador salaInicial;
  final EstadoConexionCliente conexion;

  const LobbyTransicionAPartida({
    required super.urlServidor,
    required this.salaInicial,
    required this.conexion,
  });
}
