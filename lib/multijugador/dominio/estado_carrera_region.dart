import '../constantes_multijugador.dart';

/// DTO inmutable del estado competitivo de una región recibido desde el servidor.
class EstadoCarreraRegion {
  final String regionId;
  final int completadosPrevios;
  final List<String> idsJugadoresCompletaron;

  const EstadoCarreraRegion({
    required this.regionId,
    this.completadosPrevios = 0,
    this.idsJugadoresCompletaron = const [],
  });

  /// Escalón disponible para el siguiente jugador en completar esta región (1, 2 o 3).
  int get escalonActual {
    if (completadosPrevios <= 0) {
      return ConstantesMultijugador.escalonPrimero;
    }
    if (completadosPrevios == 1) {
      return ConstantesMultijugador.escalonSegundo;
    }
    return ConstantesMultijugador.escalonTerceroOMas;
  }

  int puntosDisponibles(Map<int, int> tablaPuntuaciones) {
    return tablaPuntuaciones[escalonActual] ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'regionId': regionId,
        'completadosPrevios': completadosPrevios,
        'idsJugadoresCompletaron': idsJugadoresCompletaron,
      };

  factory EstadoCarreraRegion.fromJson(Map<String, dynamic> json) {
    return EstadoCarreraRegion(
      regionId: json['regionId'] as String,
      completadosPrevios: (json['completadosPrevios'] as num?)?.toInt() ?? 0,
      idsJugadoresCompletaron:
          (json['idsJugadoresCompletaron'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
    );
  }
}
