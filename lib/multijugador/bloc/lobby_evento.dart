import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';

abstract class LobbyEvento {
  const LobbyEvento();
}

class CambiarUrlServidorLobby extends LobbyEvento {
  final String nuevaUrl;
  const CambiarUrlServidorLobby(this.nuevaUrl);
}

class SolicitarCrearSala extends LobbyEvento {
  final String apodo;
  final String nivelId;
  const SolicitarCrearSala({
    required this.apodo,
    this.nivelId = 'nivel_1',
  });
}

class SolicitarUnirseASala extends LobbyEvento {
  final String codigoSala;
  final String apodo;
  const SolicitarUnirseASala({
    required this.codigoSala,
    required this.apodo,
  });
}

class CambiarNivelLobby extends LobbyEvento {
  final String nivelId;
  const CambiarNivelLobby(this.nivelId);
}

class AlternarEstadoListoLobby extends LobbyEvento {
  final bool listo;
  const AlternarEstadoListoLobby(this.listo);
}

class SolicitarIniciarPartidaLobby extends LobbyEvento {
  const SolicitarIniciarPartidaLobby();
}

class ReintentarConexionLobby extends LobbyEvento {
  const ReintentarConexionLobby();
}

class LimpiarErrorLobby extends LobbyEvento {
  const LimpiarErrorLobby();
}

class SalirDelLobby extends LobbyEvento {
  const SalirDelLobby();
}

class SalaLobbyRecibidaInterna extends LobbyEvento {
  final EstadoSalaMultijugador sala;
  const SalaLobbyRecibidaInterna(this.sala);
}

class ConexionLobbyRecibidaInterna extends LobbyEvento {
  final EstadoConexionCliente conexion;
  const ConexionLobbyRecibidaInterna(this.conexion);
}

class ErrorLobbyRecibidoInterno extends LobbyEvento {
  final FalloMultijugador fallo;
  const ErrorLobbyRecibidoInterno(this.fallo);
}
