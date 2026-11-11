/// Coordenada pura e inmutable serializable en JSON para el protocolo Cliente-Servidor.
class PosicionMapa {
  final int fila;
  final int columna;

  const PosicionMapa(this.fila, this.columna);

  String get clave => '$fila,$columna';

  factory PosicionMapa.desdeClave(String clave) {
    final partes = clave.split(',');
    if (partes.length != 2) {
      throw FormatException('Clave de posición inválida: $clave');
    }
    return PosicionMapa(int.parse(partes[0]), int.parse(partes[1]));
  }

  Map<String, dynamic> toJson() => {'fila': fila, 'columna': columna};

  factory PosicionMapa.fromJson(Map<String, dynamic> json) {
    return PosicionMapa(
      (json['fila'] as num).toInt(),
      (json['columna'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosicionMapa && fila == other.fila && columna == other.columna;

  @override
  int get hashCode => Object.hash(fila, columna);

  @override
  String toString() => '($fila, $columna)';
}
