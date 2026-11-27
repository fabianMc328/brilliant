/// Entrada inmutable de un jugador en la tabla de Rankings de Brilliant.
class EntradaRanking {
  final String apodo;
  final int victoriasMulti;
  final int partidasMulti;
  final int puntosTotalesMulti;
  final int mejorPuntajeMulti;
  final int mejorPuntajeSolitario;
  final int partidasSolitario;

  const EntradaRanking({
    required this.apodo,
    this.victoriasMulti = 0,
    this.partidasMulti = 0,
    this.puntosTotalesMulti = 0,
    this.mejorPuntajeMulti = 0,
    this.mejorPuntajeSolitario = 0,
    this.partidasSolitario = 0,
  });

  factory EntradaRanking.fromJson(Map<String, dynamic> json) {
    return EntradaRanking(
      apodo: (json['apodo'] as String?) ?? 'Jugador',
      victoriasMulti: (json['victoriasMulti'] as num?)?.toInt() ?? 0,
      partidasMulti: (json['partidasMulti'] as num?)?.toInt() ?? 0,
      puntosTotalesMulti: (json['puntosTotalesMulti'] as num?)?.toInt() ?? 0,
      mejorPuntajeMulti: (json['mejorPuntajeMulti'] as num?)?.toInt() ?? 0,
      mejorPuntajeSolitario:
          (json['mejorPuntajeSolitario'] as num?)?.toInt() ?? 0,
      partidasSolitario: (json['partidasSolitario'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'apodo': apodo,
        'victoriasMulti': victoriasMulti,
        'partidasMulti': partidasMulti,
        'puntosTotalesMulti': puntosTotalesMulti,
        'mejorPuntajeMulti': mejorPuntajeMulti,
        'mejorPuntajeSolitario': mejorPuntajeSolitario,
        'partidasSolitario': partidasSolitario,
      };
}

/// Tabla dual de Rankings (Multijugador competitivo y Récords en Solitario).
class TablaRankings {
  final List<EntradaRanking> multijugador;
  final List<EntradaRanking> solitario;

  const TablaRankings({
    required this.multijugador,
    required this.solitario,
  });

  factory TablaRankings.vacia() => const TablaRankings(
        multijugador: [],
        solitario: [],
      );

  factory TablaRankings.fromJson(Map<String, dynamic> json) {
    final rawMulti = json['multijugador'];
    final rawSol = json['solitario'];
    return TablaRankings(
      multijugador: rawMulti is List
          ? rawMulti
              .whereType<Map<String, dynamic>>()
              .map(EntradaRanking.fromJson)
              .toList()
          : const [],
      solitario: rawSol is List
          ? rawSol
              .whereType<Map<String, dynamic>>()
              .map(EntradaRanking.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'multijugador': multijugador.map((e) => e.toJson()).toList(),
        'solitario': solitario.map((e) => e.toJson()).toList(),
      };
}
