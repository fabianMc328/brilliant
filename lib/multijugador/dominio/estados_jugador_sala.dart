/// Fase global en la que se encuentra la sala multijugador.
enum FaseSala {
  enLobby,
  configurandoIniciales,
  jugandoRondas,
  finalizada;

  static FaseSala desdeNombre(String nombre) {
    return FaseSala.values.firstWhere(
      (e) => e.name == nombre,
      orElse: () => FaseSala.enLobby,
    );
  }
}

/// Estado de participación y presencia de un jugador en la sala/partida.
enum EstadoParticipacion {
  conectado,
  reconectando,
  concedido,
  abandonado;

  bool get sigueEnCompetencia =>
      this == EstadoParticipacion.conectado ||
      this == EstadoParticipacion.reconectando;

  bool get estaConectadoActivo => this == EstadoParticipacion.conectado;

  static EstadoParticipacion desdeNombre(String nombre) {
    return EstadoParticipacion.values.firstWhere(
      (e) => e.name == nombre,
      orElse: () => EstadoParticipacion.conectado,
    );
  }
}

/// Motivo por el cual concluyó una partida multijugador.
enum MotivoFinPartida {
  metaPuntosAlcanzada,
  concesionRival,
  abandonoRival,
  sinJugadasRestantes;

  static MotivoFinPartida? desdeNombreONull(String? nombre) {
    if (nombre == null) return null;
    for (final m in MotivoFinPartida.values) {
      if (m.name == nombre) return m;
    }
    return null;
  }
}

/// Estado local de la conexión de red del cliente hacia el servidor.
enum TipoEstadoConexionCliente {
  desconectado,
  conectando,
  conectado,
  reconectando,
  perdidaDefinitiva,
}

class EstadoConexionCliente {
  final TipoEstadoConexionCliente tipo;
  final int intentoActual;
  final int maxIntentos;
  final String? detalle;

  const EstadoConexionCliente({
    required this.tipo,
    this.intentoActual = 0,
    this.maxIntentos = 0,
    this.detalle,
  });

  const EstadoConexionCliente.desconectado([String? detalle])
      : this(tipo: TipoEstadoConexionCliente.desconectado, detalle: detalle);

  const EstadoConexionCliente.conectando()
      : this(tipo: TipoEstadoConexionCliente.conectando);

  const EstadoConexionCliente.conectado()
      : this(tipo: TipoEstadoConexionCliente.conectado);

  const EstadoConexionCliente.reconectando({
    required int intentoActual,
    required int maxIntentos,
    String? detalle,
  }) : this(
          tipo: TipoEstadoConexionCliente.reconectando,
          intentoActual: intentoActual,
          maxIntentos: maxIntentos,
          detalle: detalle,
        );

  const EstadoConexionCliente.perdidaDefinitiva([String? detalle])
      : this(
          tipo: TipoEstadoConexionCliente.perdidaDefinitiva,
          detalle: detalle,
        );
}

/// Códigos tipados de error en operaciones de red, lobby y jugabilidad.
enum CodigoFalloMultijugador {
  sinConexionServidor,
  tiempoEsperaAgotado,
  codigoInvalido,
  salaNoEncontrada,
  salaLlena,
  partidaYaIniciada,
  apodoInvalido,
  apodoEnUso,
  permisoDenegado,
  jugadoresInsuficientes,
  noTodosListos,
  mapaInvalido,
  jugadaInvalida,
  sesionExpirada,
  mensajeMalformado,
  desconocido;

  static CodigoFalloMultijugador desdeNombre(String nombre) {
    return CodigoFalloMultijugador.values.firstWhere(
      (e) => e.name == nombre,
      orElse: () => CodigoFalloMultijugador.desconocido,
    );
  }
}

/// Excepción inmutable y descriptiva de fallos multijugador.
class FalloMultijugador implements Exception {
  final CodigoFalloMultijugador codigo;
  final String mensaje;

  const FalloMultijugador({
    required this.codigo,
    required this.mensaje,
  });

  Map<String, dynamic> toJson() => {
        'codigo': codigo.name,
        'mensaje': mensaje,
      };

  factory FalloMultijugador.fromJson(Map<String, dynamic> json) {
    return FalloMultijugador(
      codigo: CodigoFalloMultijugador.desdeNombre(
        (json['codigo'] as String?) ?? '',
      ),
      mensaje: (json['mensaje'] as String?) ?? 'Ocurrió un error inesperado.',
    );
  }

  @override
  String toString() => 'FalloMultijugador(${codigo.name}: $mensaje)';
}
