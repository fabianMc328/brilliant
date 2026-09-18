import 'tipo.dart';

class Coordenada {
  final int x;
  final int y;

  const Coordenada(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordenada &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '($x, $y)';
}

class Region {
  final String id;
  final Tipo tipo;
  final Set<Coordenada> coordenadas;

  Region({
    required this.id,
    required this.tipo,
    required this.coordenadas,
  });

  bool contiene(Coordenada c) => coordenadas.contains(c);
}
