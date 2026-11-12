import 'estado_sala_multijugador.dart';
import 'estados_jugador_sala.dart';
import 'mensajes_protocolo.dart';
import 'modelos_mapa.dart';

/// Contrato abstracto de comunicación multijugador (Principio de Inversión de Dependencias).
/// Los BLoCs dependen exclusivamente de esta abstracción y nunca de WebSockets concretos.
abstract class RepositorioMultijugador {
  /// Flujo continuo con las actualizaciones del estado de la sala/partida.
  Stream<EstadoSalaMultijugador> get flujoSala;

  /// Flujo continuo con el estado de la conexión de red local (conectado, reconectando, caída).
  Stream<EstadoConexionCliente> get flujoConexion;

  /// Flujo de errores asíncronos enviados por el servidor o capa de red.
  Stream<FalloMultijugador> get flujoErrores;

  /// Flujo de mensajes de chat en tiempo real.
  Stream<MensajeChat> get flujoChat;

  /// Último snapshot recibido de la sala actual, si existe.
  EstadoSalaMultijugador? get ultimoEstadoSala;

  /// Estado actual de la conexión del cliente.
  EstadoConexionCliente get estadoConexionActual;

  /// URL del servidor configurada actualmente.
  String get urlServidorActual;

  /// Actualiza la URL destino del servidor WebSocket antes de crear o unirse a una sala.
  void configurarUrlServidor(String nuevaUrl);

  /// Crea una nueva sala como anfitrión y retorna su estado inicial.
  Future<EstadoSalaMultijugador> crearSala({
    required String apodo,
    String nivelId = 'nivel_1',
  });

  /// Se une a una sala existente mediante código de invitación de 6 caracteres.
  Future<EstadoSalaMultijugador> unirseASala({
    required String codigoSala,
    required String apodo,
  });

  /// Fuerza un intento manual inmediato de reconexión si la sesión sigue vigente.
  Future<void> reintentarReconexionManual();

  /// Cambia el tablero compartido en el lobby (exclusivo del anfitrión).
  Future<void> seleccionarNivel(String nivelId);

  /// Marca o desmarca el botón "Estoy Listo" del jugador actual en el lobby.
  Future<void> alternarListo(bool listo);

  /// Inicia la partida cuando hay de 2 a 6 jugadores y todos dieron "Listo".
  Future<void> iniciarPartida();

  /// Confirma las 6 estrellas iniciales colocadas por el jugador en la Fase 1.
  Future<void> confirmarValoresIniciales(Map<PosicionMapa, int> valoresEstrellas);

  /// Envía la colocación de un número en la ronda actual de dados.
  Future<void> colocarNumeroEnRonda({
    required int ronda,
    required PosicionMapa ancla,
    required PosicionMapa destino,
    required int valorColocado,
  });

  /// Pasa el turno en la ronda actual de dados.
  Future<void> pasarTurnoEnRonda({required int ronda});

  /// Concede (se rinde en) la partida actual de forma voluntaria.
  Future<void> concederPartida();

  /// Envía un mensaje de chat a todos los miembros de la sala.
  Future<void> enviarMensajeChat(String texto);

  /// Abandona limpiamente la sala actual y cierra la sesión activa.
  Future<void> salirDeSala();

  /// Libera flujos y conexiones abiertas.
  Future<void> cerrar();
}
