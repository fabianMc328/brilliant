import 'dart:async';

import '../constantes_multijugador.dart';
import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';
import '../dominio/jugador_multijugador.dart';
import '../dominio/modelos_mapa.dart';
import '../dominio/repositorio_multijugador.dart';

/// Implementación controlada en memoria de [RepositorioMultijugador]
/// diseñada específicamente para pruebas unitarias de BLoC y Widgets.
class RepositorioMultijugadorFake implements RepositorioMultijugador {
  final StreamController<EstadoSalaMultijugador> _salaCtrl =
      StreamController<EstadoSalaMultijugador>.broadcast();
  final StreamController<EstadoConexionCliente> _conexionCtrl =
      StreamController<EstadoConexionCliente>.broadcast();
  final StreamController<FalloMultijugador> _erroresCtrl =
      StreamController<FalloMultijugador>.broadcast();

  EstadoSalaMultijugador? _ultimoEstado;
  EstadoConexionCliente _conexion = const EstadoConexionCliente.desconectado();
  String _url = ConstantesMultijugador.urlServidorLocalPorDefecto;

  FalloMultijugador? proximoFalloSimulado;
  bool concederFueLlamado = false;
  bool salirFueLlamado = false;
  bool reconectarManualFueLlamado = false;
  int? ultimaRondaPasada;
  (int, PosicionMapa, PosicionMapa, int)? ultimaJugadaEnviada;
  Map<PosicionMapa, int>? ultimasEstrellasConfirmadas;

  @override
  Stream<EstadoSalaMultijugador> get flujoSala => _salaCtrl.stream;

  @override
  Stream<EstadoConexionCliente> get flujoConexion => _conexionCtrl.stream;

  @override
  Stream<FalloMultijugador> get flujoErrores => _erroresCtrl.stream;

  @override
  EstadoSalaMultijugador? get ultimoEstadoSala => _ultimoEstado;

  @override
  EstadoConexionCliente get estadoConexionActual => _conexion;

  @override
  String get urlServidorActual => _url;

  @override
  void configurarUrlServidor(String nuevaUrl) {
    _url = nuevaUrl.trim();
  }

  void emitirEstadoSala(EstadoSalaMultijugador estado) {
    _ultimoEstado = estado;
    if (!_salaCtrl.isClosed) _salaCtrl.add(estado);
  }

  void emitirEstadoConexion(EstadoConexionCliente estado) {
    _conexion = estado;
    if (!_conexionCtrl.isClosed) _conexionCtrl.add(estado);
  }

  void emitirErrorAsincrono(FalloMultijugador fallo) {
    if (!_erroresCtrl.isClosed) _erroresCtrl.add(fallo);
  }

  @override
  Future<EstadoSalaMultijugador> crearSala({
    required String apodo,
    String nivelId = 'nivel_1',
  }) async {
    _lanzarSiHayFallo();
    emitirEstadoConexion(const EstadoConexionCliente.conectado());
    final estado = EstadoSalaMultijugador(
      codigoSala: 'ABC234',
      miJugadorId: 'j1',
      fase: FaseSala.enLobby,
      nivelId: nivelId,
      jugadores: [
        ResumenJugador(
          id: 'j1',
          apodo: apodo.trim(),
          esAnfitrion: true,
          estaListo: false,
          participacion: EstadoParticipacion.conectado,
        ),
      ],
    );
    emitirEstadoSala(estado);
    return estado;
  }

  @override
  Future<EstadoSalaMultijugador> unirseASala({
    required String codigoSala,
    required String apodo,
  }) async {
    _lanzarSiHayFallo();
    emitirEstadoConexion(const EstadoConexionCliente.conectado());
    final estado = EstadoSalaMultijugador(
      codigoSala: codigoSala.trim().toUpperCase(),
      miJugadorId: 'j2',
      fase: FaseSala.enLobby,
      nivelId: 'nivel_1',
      jugadores: [
        const ResumenJugador(
          id: 'j1',
          apodo: 'Host',
          esAnfitrion: true,
          estaListo: true,
          participacion: EstadoParticipacion.conectado,
        ),
        ResumenJugador(
          id: 'j2',
          apodo: apodo.trim(),
          esAnfitrion: false,
          estaListo: false,
          participacion: EstadoParticipacion.conectado,
        ),
      ],
    );
    emitirEstadoSala(estado);
    return estado;
  }

  @override
  Future<void> reintentarReconexionManual() async {
    reconectarManualFueLlamado = true;
    _lanzarSiHayFallo();
    emitirEstadoConexion(const EstadoConexionCliente.conectado());
  }

  @override
  Future<void> seleccionarNivel(String nivelId) async {
    _lanzarSiHayFallo();
    final actual = _ultimoEstado;
    if (actual == null) return;
    final actualizados = actual.jugadores
        .map((j) => j.esAnfitrion ? j : j.copiarCon(estaListo: false))
        .toList();
    emitirEstadoSala(
      EstadoSalaMultijugador(
        codigoSala: actual.codigoSala,
        miJugadorId: actual.miJugadorId,
        fase: actual.fase,
        nivelId: nivelId,
        jugadores: actualizados,
      ),
    );
  }

  @override
  Future<void> alternarListo(bool listo) async {
    _lanzarSiHayFallo();
    final actual = _ultimoEstado;
    if (actual == null) return;
    final actualizados = actual.jugadores
        .map((j) => j.id == actual.miJugadorId ? j.copiarCon(estaListo: listo) : j)
        .toList();
    emitirEstadoSala(
      EstadoSalaMultijugador(
        codigoSala: actual.codigoSala,
        miJugadorId: actual.miJugadorId,
        fase: actual.fase,
        nivelId: actual.nivelId,
        jugadores: actualizados,
      ),
    );
  }

  @override
  Future<void> iniciarPartida() async {
    _lanzarSiHayFallo();
    final actual = _ultimoEstado;
    if (actual == null) return;
    emitirEstadoSala(
      EstadoSalaMultijugador(
        codigoSala: actual.codigoSala,
        miJugadorId: actual.miJugadorId,
        fase: FaseSala.configurandoIniciales,
        nivelId: actual.nivelId,
        jugadores: actual.jugadores,
        segundosRestantes: 60,
        metaPuntos: ConstantesMultijugador.obtenerMetaPuntos(actual.jugadores.length),
      ),
    );
  }

  @override
  Future<void> confirmarValoresIniciales(
    Map<PosicionMapa, int> valoresEstrellas,
  ) async {
    _lanzarSiHayFallo();
    ultimasEstrellasConfirmadas = Map<PosicionMapa, int>.from(valoresEstrellas);
  }

  @override
  Future<void> colocarNumeroEnRonda({
    required int ronda,
    required PosicionMapa ancla,
    required PosicionMapa destino,
    required int valorColocado,
  }) async {
    _lanzarSiHayFallo();
    ultimaJugadaEnviada = (ronda, ancla, destino, valorColocado);
  }

  @override
  Future<void> pasarTurnoEnRonda({required int ronda}) async {
    _lanzarSiHayFallo();
    ultimaRondaPasada = ronda;
  }

  @override
  Future<void> concederPartida() async {
    _lanzarSiHayFallo();
    concederFueLlamado = true;
  }

  @override
  Future<void> salirDeSala() async {
    salirFueLlamado = true;
    _ultimoEstado = null;
    emitirEstadoConexion(const EstadoConexionCliente.desconectado());
  }

  @override
  Future<void> cerrar() async {
    await _salaCtrl.close();
    await _conexionCtrl.close();
    await _erroresCtrl.close();
  }

  void _lanzarSiHayFallo() {
    final fallo = proximoFalloSimulado;
    if (fallo != null) {
      proximoFalloSimulado = null;
      throw fallo;
    }
  }
}
