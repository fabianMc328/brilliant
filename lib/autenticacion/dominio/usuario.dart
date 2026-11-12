/// Entidad de usuario autenticado en Brilliant.
class Usuario {
  final String id;
  final String apodo;
  final String email;
  final DateTime fechaRegistro;

  const Usuario({
    required this.id,
    required this.apodo,
    required this.email,
    required this.fechaRegistro,
  });

  Usuario copiarCon({
    String? id,
    String? apodo,
    String? email,
    DateTime? fechaRegistro,
  }) {
    return Usuario(
      id: id ?? this.id,
      apodo: apodo ?? this.apodo,
      email: email ?? this.email,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'apodo': apodo,
        'email': email,
        'fechaRegistro': fechaRegistro.toIso8601String(),
      };

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      apodo: json['apodo'] as String,
      email: json['email'] as String,
      fechaRegistro: DateTime.tryParse(json['fechaRegistro'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Usuario &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, email);

  @override
  String toString() => 'Usuario($apodo <$email>)';
}
