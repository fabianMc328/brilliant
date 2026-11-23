/// Validaciones y normalizaciones compartidas para autenticación y apodos únicos.
class ValidadorAuth {
  ValidadorAuth._();

  static const int minLongitudApodo = 2;
  static const int maxLongitudApodo = 18;
  static final RegExp _regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _regexProhibidos = RegExp(
    r'[\x00-\x1F\x7F\u200B-\u200D\uFEFF]',
  );
  static final RegExp _regexAlfanumerico = RegExp(
    r'[a-zA-Z0-9áéíóúÁÉÍÓÚüÜñÑ]',
  );

  /// Clave canónica insensible a mayúsculas, espacios extra y acentos equivalentes.
  static String normalizarApodoClave(String apodo) {
    final limpio = apodo.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    const mapaAcentos = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
    };

    final buffer = StringBuffer();
    for (final rune in limpio.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(mapaAcentos[ch] ?? ch);
    }
    return buffer.toString();
  }

  static String? validarApodo(String? value) {
    final limpio = (value ?? '').trim();
    if (limpio.isEmpty) {
      return 'Ingresa un apodo o nombre de jugador';
    }
    if (_regexProhibidos.hasMatch(limpio)) {
      return 'El apodo contiene caracteres no permitidos';
    }
    if (limpio.length < minLongitudApodo || limpio.length > maxLongitudApodo) {
      return 'Debe tener entre 2 y 18 caracteres';
    }
    if (RegExp(r'\s{2,}').hasMatch(limpio)) {
      return 'No uses espacios consecutivos';
    }
    if (limpio.contains('@')) {
      return 'El apodo no puede contener el símbolo @';
    }
    if (!_regexAlfanumerico.hasMatch(limpio)) {
      return 'Debe incluir al menos una letra o número';
    }
    return null;
  }

  static String? validarEmail(String? value) {
    final limpio = (value ?? '').trim();
    if (limpio.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    if (RegExp(r'\s').hasMatch(limpio)) {
      return 'El correo electrónico no puede contener espacios';
    }
    if (!_regexEmail.hasMatch(limpio)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  static String? validarIdentificadorLogin(String? value) {
    final limpio = (value ?? '').trim();
    if (limpio.isEmpty) {
      return 'Ingresa tu usuario o correo electrónico';
    }
    if (limpio.contains('@')) {
      return validarEmail(limpio);
    }
    if (RegExp(r'\s{2,}').hasMatch(limpio)) {
      return 'El usuario no puede tener espacios consecutivos';
    }
    return null;
  }

  static String? validarContrasena(String? value) {
    final texto = value ?? '';
    if (texto.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    if (RegExp(r'\s').hasMatch(texto)) {
      return 'La contraseña no puede contener espacios';
    }
    if (texto.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
}
