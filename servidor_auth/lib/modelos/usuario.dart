class Usuario {
  final String id;
  final String email;
  final String passwordHash;
  final DateTime fechaCreacion;

  const Usuario({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toJsonPublico() => {
    'id': id,
    'email': email,
    'fecha_creacion': fechaCreacion.toIso8601String(),
  };

  Map<String, dynamic> toMapInterno() => {
    'id': id,
    'email': email,
    'password_hash': passwordHash,
    'fecha_creacion': fechaCreacion.toIso8601String(),
  };

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
    );
  }
}
