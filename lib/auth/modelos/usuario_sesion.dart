/// Modelo inmutable de la sesión del usuario en el cliente Flutter.
class UsuarioSesion {
  final String id;
  final String email;
  final String token;

  const UsuarioSesion({
    required this.id,
    required this.email,
    required this.token,
  });

  factory UsuarioSesion.fromJson(Map<String, dynamic> json, {String? fallbackToken}) {
    final datosUsuario = json['usuario'] as Map<String, dynamic>? ?? json;
    final token = json['token'] as String? ?? fallbackToken ?? '';

    return UsuarioSesion(
      id: datosUsuario['id'] as String? ?? '',
      email: datosUsuario['email'] as String? ?? '',
      token: token,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'token': token,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioSesion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          token == other.token;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ token.hashCode;
}
