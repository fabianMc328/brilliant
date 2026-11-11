import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../niveles/catalogo_niveles.dart';
import '../../niveles/nivel_definicion.dart';
import '../../region.dart';
import '../../tablero.dart';
import '../constantes_multijugador.dart';
import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';
import '../dominio/modelos_mapa.dart';
import '../dominio/repositorio_multijugador.dart';
import 'partida_multijugador_estado.dart';
import 'partida_multijugador_evento.dart';

/// BLoC enfocado en la partida multijugador activa (estrellas, dados sincronizados,
/// concesión y recuperación ante desconexiones) reutilizando [Tablero] y [NivelDefinicion].
class PartidaMultijugadorBloc
    extends Bloc<PartidaMultijugadorEvento, PartidaMultijugadorEstado> {
  final RepositorioMultijugador _repositorio;
  final Random _random;
  StreamSubscription<EstadoSalaMultijugador>? _subSala;
  StreamSubscription<EstadoConexionCliente>? _subConexion;
  StreamSubscription<FalloMultijugador>? _subErrores;

  PartidaMultijugadorBloc({
    required RepositorioMultijugador repositorio,
    required EstadoSalaMultijugador salaInicial,
    Random? random,
  })  : _repositorio = repositorio,
        _random = random ?? Random(),
        super(
          _construirEstadoDesdeSala(
            sala: salaInicial,
            conexion: repositorio.estadoConexionActual,
          ),
        ) {
    on<ColocarEstrellaLocal>(_onColocarEstrellaLocal);
    on<LimpiarEstrellasLocales>(_onLimpiarEstrellasLocales);
    on<LlenarEstrellasAleatoriasLocales>(_onLlenarAleatorias);
    on<ConfirmarEstrellasMultijugador>(_onConfirmarEstrellas);
    on<SeleccionarAnclaMultijugador>(_onSeleccionarAncla);
    on<DeseleccionarAnclaMultijugador>(_onDeseleccionarAncla);
    on<ColocarNumeroMultijugador>(_onColocarNumero);
    on<PasarTurnoMultijugador>(_onPasarTurno);
    on<SolicitarConcederPartida>(_onConcederPartida);
    on<ReintentarReconexionPartida>(_onReintentarReconexion);
    on<LimpiarAvisoPartida>(_onLimpiarAviso);
    on<AbandonarSalaMultijugador>(_onAbandonarSala);
    on<EstadoSalaPartidaRecibidoInterno>(_onSalaRecibida);
    on<ConexionPartidaRecibidaInterna>(_onConexionRecibida);
    on<ErrorPartidaRecibidoInterno>(_onErrorRecibido);

    _subSala = _repositorio.flujoSala.listen(
      (sala) => add(EstadoSalaPartidaRecibidoInterno(sala)),
    );
    _subConexion = _repositorio.flujoConexion.listen(
      (con) => add(ConexionPartidaRecibidaInterna(con)),
    );
    _subErrores = _repositorio.flujoErrores.listen(
      (err) => add(ErrorPartidaRecibidoInterno(err)),
    );
  }

  void _onColocarEstrellaLocal(
    ColocarEstrellaLocal event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    if (actual.sala.fase != FaseSala.configurandoIniciales ||
        actual.sala.yaConfirmeEnRonda ||
        actual.sala.yaConcedi) {
      return;
    }

    if (!actual.nivel.casillasIniciales.contains(event.coordenada)) {
      emit(
        actual.copiarCon(
          mensajeAviso: 'Solo puedes colocar valores iniciales en las estrellas.',
        ),
      );
      return;
    }

    if (event.valor < ConstantesMultijugador.valorMinimoDado ||
        event.valor > ConstantesMultijugador.valorMaximoDado) {
      return;
    }

    final nuevas = Map<Coordenada, int>.from(actual.estrellasBorrador);
    if (nuevas.containsValue(event.valor)) {
      final anterior =
          nuevas.entries.firstWhere((e) => e.value == event.valor).key;
      nuevas.remove(anterior);
    }
    nuevas[event.coordenada] = event.valor;

    emit(actual.copiarCon(estrellasBorrador: nuevas, limpiarAviso: true));
  }

  void _onLimpiarEstrellasLocales(
    LimpiarEstrellasLocales event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    if (actual.sala.yaConfirmeEnRonda) return;
    emit(actual.copiarCon(estrellasBorrador: const {}, limpiarAviso: true));
  }

  void _onLlenarAleatorias(
    LlenarEstrellasAleatoriasLocales event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    if (actual.sala.fase != FaseSala.configurandoIniciales ||
        actual.sala.yaConfirmeEnRonda) {
      return;
    }

    final numeros = [1, 2, 3, 4, 5, 6]..shuffle(_random);
    final generadas = <Coordenada, int>{};
    for (int i = 0; i < actual.nivel.casillasIniciales.length; i++) {
      generadas[actual.nivel.casillasIniciales[i]] = numeros[i];
    }

    emit(actual.copiarCon(estrellasBorrador: generadas, limpiarAviso: true));
  }

  Future<void> _onConfirmarEstrellas(
    ConfirmarEstrellasMultijugador event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) async {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    if (!actual.estrellasCompletasParaConfirmar) {
      final faltantes = ConstantesMultijugador.cantidadEstrellasIniciales -
          actual.estrellasBorrador.length;
      emit(
        actual.copiarCon(
          mensajeAviso: 'Faltan $faltantes estrella(s) por llenar.',
        ),
      );
      return;
    }

    final mapaRed = <PosicionMapa, int>{
      for (final e in actual.estrellasBorrador.entries)
        PosicionMapa(e.key.x, e.key.y): e.value,
    };

    try {
      await _repositorio.confirmarValoresIniciales(mapaRed);
    } on FalloMultijugador catch (f) {
      emit(actual.copiarCon(mensajeAviso: f.mensaje));
    }
  }

  void _onSeleccionarAncla(
    SeleccionarAnclaMultijugador event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    if (!actual.puedeInteractuarConTablero) return;

    final celda = actual.tableroLocal.celdas[event.coordenada];
    if (celda == null || celda.estaVacia) {
      emit(
        actual.copiarCon(
          mensajeAviso: 'Selecciona una casilla ocupada como ancla.',
        ),
      );
      return;
    }

    final d1 = actual.sala.dado1;
    final d2 = actual.sala.dado2;
    if (d1 == null || d2 == null) return;

    final valorAncla = celda.valor!;
    if (valorAncla != d1 && valorAncla != d2) {
      emit(
        actual.copiarCon(
          mensajeAviso:
              'El ancla ($valorAncla) debe coincidir con uno de los dados ($d1 o $d2).',
        ),
      );
      return;
    }

    final numeroAColocar = (valorAncla == d1) ? d2 : d1;
    final validas = actual.tableroLocal.obtenerPosiblesLugaresParaAncla(
      event.coordenada,
      numeroAColocar,
    );

    emit(
      actual.copiarCon(
        anclaSeleccionada: event.coordenada,
        numeroAColocar: numeroAColocar,
        casillasValidas: validas,
        limpiarAviso: true,
      ),
    );
  }

  void _onDeseleccionarAncla(
    DeseleccionarAnclaMultijugador event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    emit(
      actual.copiarCon(
        limpiarAncla: true,
        limpiarNumero: true,
        casillasValidas: const {},
        limpiarAviso: true,
      ),
    );
  }

  Future<void> _onColocarNumero(
    ColocarNumeroMultijugador event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) async {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    if (!actual.puedeInteractuarConTablero) return;

    final ancla = actual.anclaSeleccionada;
    final numero = actual.numeroAColocar;
    if (ancla == null ||
        numero == null ||
        !actual.casillasValidas.contains(event.destino)) {
      emit(
        actual.copiarCon(
          mensajeAviso: 'Toca una casilla iluminada en verde válida.',
        ),
      );
      return;
    }

    try {
      await _repositorio.colocarNumeroEnRonda(
        ronda: actual.sala.rondaActual,
        ancla: PosicionMapa(ancla.x, ancla.y),
        destino: PosicionMapa(event.destino.x, event.destino.y),
        valorColocado: numero,
      );
      emit(
        actual.copiarCon(
          limpiarAncla: true,
          limpiarNumero: true,
          casillasValidas: const {},
          limpiarAviso: true,
        ),
      );
    } on FalloMultijugador catch (f) {
      emit(actual.copiarCon(mensajeAviso: f.mensaje));
    }
  }

  Future<void> _onPasarTurno(
    PasarTurnoMultijugador event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) async {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    if (!actual.puedeInteractuarConTablero) return;

    try {
      await _repositorio.pasarTurnoEnRonda(ronda: actual.sala.rondaActual);
      emit(
        actual.copiarCon(
          limpiarAncla: true,
          limpiarNumero: true,
          casillasValidas: const {},
          limpiarAviso: true,
        ),
      );
    } on FalloMultijugador catch (f) {
      emit(actual.copiarCon(mensajeAviso: f.mensaje));
    }
  }

  Future<void> _onConcederPartida(
    SolicitarConcederPartida event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) async {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    try {
      await _repositorio.concederPartida();
      emit(
        actual.copiarCon(
          limpiarAncla: true,
          limpiarNumero: true,
          casillasValidas: const {},
          limpiarAviso: true,
        ),
      );
    } on FalloMultijugador catch (f) {
      emit(actual.copiarCon(mensajeAviso: f.mensaje));
    }
  }

  Future<void> _onReintentarReconexion(
    ReintentarReconexionPartida event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) async {
    if (state is! PartidaMultijugadorActiva) return;
    final actual = state as PartidaMultijugadorActiva;
    try {
      await _repositorio.reintentarReconexionManual();
    } on FalloMultijugador catch (f) {
      emit(actual.copiarCon(mensajeAviso: f.mensaje));
    }
  }

  void _onLimpiarAviso(
    LimpiarAvisoPartida event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) {
    if (state is PartidaMultijugadorActiva) {
      emit((state as PartidaMultijugadorActiva).copiarCon(limpiarAviso: true));
    }
  }

  Future<void> _onAbandonarSala(
    AbandonarSalaMultijugador event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) async {
    await _repositorio.salirDeSala();
    emit(const PartidaMultijugadorCerrada());
  }

  void _onSalaRecibida(
    EstadoSalaPartidaRecibidoInterno event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) {
    if (state is PartidaMultijugadorCerrada) return;
    final previo = state is PartidaMultijugadorActiva
        ? state as PartidaMultijugadorActiva
        : null;

    final nuevaRondaOFase = previo == null ||
        previo.sala.fase != event.sala.fase ||
        previo.sala.rondaActual != event.sala.rondaActual ||
        event.sala.yaConfirmeEnRonda ||
        event.sala.yaConcedi;

    final base = _construirEstadoDesdeSala(
      sala: event.sala,
      conexion: _repositorio.estadoConexionActual,
      borradorPrevio: previo?.estrellasBorrador,
    );

    // Preservar selección activa de ancla durante ticks del reloj en la misma ronda
    if (!nuevaRondaOFase && previo.anclaSeleccionada != null) {
      emit(
        base.copiarCon(
          anclaSeleccionada: previo.anclaSeleccionada,
          numeroAColocar: previo.numeroAColocar,
          casillasValidas: previo.casillasValidas,
        ),
      );
      return;
    }

    emit(base);
  }

  void _onConexionRecibida(
    ConexionPartidaRecibidaInterna event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) {
    if (state is PartidaMultijugadorActiva) {
      emit(
        (state as PartidaMultijugadorActiva).copiarCon(conexion: event.conexion),
      );
    }
  }

  void _onErrorRecibido(
    ErrorPartidaRecibidoInterno event,
    Emitter<PartidaMultijugadorEstado> emit,
  ) {
    if (state is PartidaMultijugadorActiva) {
      emit(
        (state as PartidaMultijugadorActiva)
            .copiarCon(mensajeAviso: event.fallo.mensaje),
      );
    }
  }

  static PartidaMultijugadorActiva _construirEstadoDesdeSala({
    required EstadoSalaMultijugador sala,
    required EstadoConexionCliente conexion,
    Map<Coordenada, int>? borradorPrevio,
  }) {
    final nivel = CatalogoNiveles.porId(sala.nivelId);
    final tablero = nivel.crearTablero();

    for (final entry in sala.misValoresTablero.entries) {
      final coord = Coordenada(entry.key.fila, entry.key.columna);
      tablero.celdas[coord]?.valor = entry.value;
    }

    Map<Coordenada, int> borrador = borradorPrevio ?? const {};
    if (sala.fase == FaseSala.configurandoIniciales &&
        sala.misValoresTablero.isNotEmpty) {
      borrador = {
        for (final e in sala.misValoresTablero.entries)
          Coordenada(e.key.fila, e.key.columna): e.value,
      };
    }

    bool hayJugadas = true;
    if (sala.fase == FaseSala.jugandoRondas &&
        sala.dado1 != null &&
        sala.dado2 != null) {
      hayJugadas = _calcularSiHayJugadas(tablero, sala.dado1!, sala.dado2!);
    }

    return PartidaMultijugadorActiva(
      sala: sala,
      nivel: nivel,
      tableroLocal: tablero,
      conexion: conexion,
      estrellasBorrador: borrador,
      hayJugadasDisponibles: hayJugadas,
    );
  }

  static bool _calcularSiHayJugadas(Tablero tablero, int d1, int d2) {
    for (final entry in tablero.celdas.entries) {
      final v = entry.value.valor;
      if (v == null) continue;
      if (v == d1 &&
          tablero.obtenerPosiblesLugaresParaAncla(entry.key, d2).isNotEmpty) {
        return true;
      }
      if (v == d2 &&
          tablero.obtenerPosiblesLugaresParaAncla(entry.key, d1).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> close() async {
    await _subSala?.cancel();
    await _subConexion?.cancel();
    await _subErrores?.cancel();
    return super.close();
  }
}
