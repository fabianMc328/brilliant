/// Contrato abstracto para la persistencia del token de autenticación (ISP/DIP).
abstract class TokenAlmacenamiento {
  Future<void> guardarToken(String token);
  Future<String?> obtenerToken();
  Future<void> borrarToken();
}

/// Implementación en memoria (útil para pruebas y entornos sin persistencia nativa).
class TokenAlmacenamientoMemoria implements TokenAlmacenamiento {
  String? _token;

  TokenAlmacenamientoMemoria([this._token]);

  @override
  Future<void> guardarToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> obtenerToken() async {
    return _token;
  }

  @override
  Future<void> borrarToken() async {
    _token = null;
  }
}
