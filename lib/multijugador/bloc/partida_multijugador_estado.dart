import '../../niveles/nivel_definicion.dart';
import '../../region.dart';
import '../../tablero.dart';
import '../constantes_multijugador.dart';
import '../dominio/estado_sala_multijugador.dart';
import '../dominio/estados_jugador_sala.dart';

abstract class PartidaMultijugadorEstado {
  const PartidaMultijugadorEstado();
}

/// Estado principal inmutable durante Fase 1 (Estrellas), Fase 2 (Rondas) y Podio Final.
class PartidaMultijugadorActiva extends PartidaMultijugadorEstado {
  final EstadoSalaMultijugador sala;
  final NivelDefinicion nivel;
  final Tablero tableroLocal;
  final EstadoConexionCliente conexion;
  final Map<Coordenada, int> estrellasBorrador;
  final Coordenada? anclaSeleccionada;
  final int? numeroAColocar;
  final Set<Coordenada> casillasValidas;
  final bool hayJugadasDisponibles;
  final String? mensajeAviso;

  const PartidaMultijugadorActiva({
    required this.sala,
    required this.nivel,
    required this.tableroLocal,
    required this.conexion,
    this.estrellasBorrador = const {},
    this.anclaSeleccionada,
    this.numeroAColocar,
    this.casillasValidas = const {},
    this.hayJugadasDisponibles = true,
    this.mensajeAviso,
  });

  bool get estrellasCompletasParaConfirmar =>
      estrellasBorrador.length ==
      ConstantesMultijugador.cantidadEstrellasIniciales;

  bool get puedeInteractuarConTablero =>
      conexion.tipo == TipoEstadoConexionCliente.conectado &&
      !sala.yaConcedi &&
      !sala.yaConfirmeEnRonda &&
      sala.fase == FaseSala.jugandoRondas;

  Set<Coordenada> get anclasElegibles {
    if (!puedeInteractuarConTablero) return const {};
    final d1 = sala.dado1;
    final d2 = sala.dado2;
    if (d1 == null || d2 == null) return const {};

    final elegibles = <Coordenada>{};
    for (final entry in tableroLocal.celdas.entries) {
      final v = entry.value.valor;
      if (v != null && (v == d1 || v == d2)) {
        elegibles.add(entry.key);
      }
    }
    return elegibles;
  }

  PartidaMultijugadorActiva copiarCon({
    EstadoSalaMultijugador? sala,
    NivelDefinicion? nivel,
    Tablero? tableroLocal,
    EstadoConexionCliente? conexion,
    Map<Coordenada, int>? estrellasBorrador,
    Coordenada? anclaSeleccionada,
    bool limpiarAncla = false,
    int? numeroAColocar,
    bool limpiarNumero = false,
    Set<Coordenada>? casillasValidas,
    bool? hayJugadasDisponibles,
    String? mensajeAviso,
    bool limpiarAviso = false,
  }) {
    return PartidaMultijugadorActiva(
      sala: sala ?? this.sala,
      nivel: nivel ?? this.nivel,
      tableroLocal: tableroLocal ?? this.tableroLocal,
      conexion: conexion ?? this.conexion,
      estrellasBorrador: estrellasBorrador ?? this.estrellasBorrador,
      anclaSeleccionada:
          limpiarAncla ? null : (anclaSeleccionada ?? this.anclaSeleccionada),
      numeroAColocar:
          limpiarNumero ? null : (numeroAColocar ?? this.numeroAColocar),
      casillasValidas: casillasValidas ?? this.casillasValidas,
      hayJugadasDisponibles:
          hayJugadasDisponibles ?? this.hayJugadasDisponibles,
      mensajeAviso: limpiarAviso ? null : (mensajeAviso ?? this.mensajeAviso),
    );
  }
}

/// Emitido cuando el jugador sale voluntariamente al menú principal.
class PartidaMultijugadorCerrada extends PartidaMultijugadorEstado {
  final String? motivo;
  const PartidaMultijugadorCerrada({this.motivo});
}
