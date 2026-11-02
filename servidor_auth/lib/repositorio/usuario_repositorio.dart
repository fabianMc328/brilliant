import 'dart:convert';
import 'dart:io';
import '../modelos/usuario.dart';
import '../seguridad/hasher.dart';

abstract class UsuarioRepositorio {
  Future<Usuario?> buscarPorEmail(String email);
  Future<Usuario?> buscarPorId(String id);
  Future<void> guardar(Usuario usuario);
  Future<bool> eliminarPorId(String id);
  Future<List<Usuario>> listarTodos();
}

/// Implementación en memoria (útil para pruebas unitarias).
class UsuarioRepositorioMemoria implements UsuarioRepositorio {
  final Map<String, Usuario> _usuariosPorId = {};

  UsuarioRepositorioMemoria() {
    _precargarUsuarioAdmin();
  }

  void _precargarUsuarioAdmin() {
    const hasher = HasherContrasena();
    final adminUser = Usuario(
      id: 'usr_admin',
      email: 'admin',
      passwordHash: hasher.hashear('admin123'),
      fechaCreacion: DateTime.now().toUtc(),
    );
    _usuariosPorId[adminUser.id] = adminUser;
  }

  @override
  Future<Usuario?> buscarPorEmail(String email) async {
    final emailNormalizado = email.trim().toLowerCase();
    return _usuariosPorId.values
        .where((u) => u.email.toLowerCase() == emailNormalizado)
        .firstOrNull;
  }

  @override
  Future<Usuario?> buscarPorId(String id) async {
    return _usuariosPorId[id];
  }

  @override
  Future<void> guardar(Usuario usuario) async {
    _usuariosPorId[usuario.id] = usuario;
  }

  @override
  Future<bool> eliminarPorId(String id) async {
    return _usuariosPorId.remove(id) != null;
  }

  @override
  Future<List<Usuario>> listarTodos() async {
    return _usuariosPorId.values.toList();
  }
}

/// Implementación persistente en archivo JSON local con usuario admin precargado.
class UsuarioRepositorioJson implements UsuarioRepositorio {
  final File archivo;
  final Map<String, Usuario> _cache = {};
  bool _cargado = false;

  UsuarioRepositorioJson({required this.archivo});

  Future<void> _asegurarCargado() async {
    if (_cargado) return;
    if (await archivo.exists()) {
      try {
        final contenido = await archivo.readAsString();
        if (contenido.trim().isNotEmpty) {
          final lista = jsonDecode(contenido) as List<dynamic>;
          for (final item in lista) {
            final u = Usuario.fromMap(item as Map<String, dynamic>);
            _cache[u.id] = u;
          }
        }
      } catch (e) {
        _cache.clear();
      }
    } else {
      await archivo.parent.create(recursive: true);
    }

    // Si no existe el usuario admin, lo precargamos por defecto: admin / admin123
    final existeAdmin = _cache.values.any((u) => u.email.toLowerCase() == 'admin');
    if (!existeAdmin) {
      const hasher = HasherContrasena();
      final adminUser = Usuario(
        id: 'usr_admin',
        email: 'admin',
        passwordHash: hasher.hashear('admin123'),
        fechaCreacion: DateTime.now().toUtc(),
      );
      _cache[adminUser.id] = adminUser;
      await _persistir();
    }

    _cargado = true;
  }

  Future<void> _persistir() async {
    final datos = _cache.values.map((u) => u.toMapInterno()).toList();
    await archivo.writeAsString(jsonEncode(datos));
  }

  @override
  Future<Usuario?> buscarPorEmail(String email) async {
    await _asegurarCargado();
    final emailNormalizado = email.trim().toLowerCase();
    return _cache.values
        .where((u) => u.email.toLowerCase() == emailNormalizado)
        .firstOrNull;
  }

  @override
  Future<Usuario?> buscarPorId(String id) async {
    await _asegurarCargado();
    return _cache[id];
  }

  @override
  Future<void> guardar(Usuario usuario) async {
    await _asegurarCargado();
    _cache[usuario.id] = usuario;
    await _persistir();
  }

  @override
  Future<bool> eliminarPorId(String id) async {
    await _asegurarCargado();
    final eliminado = _cache.remove(id) != null;
    if (eliminado) {
      await _persistir();
    }
    return eliminado;
  }

  @override
  Future<List<Usuario>> listarTodos() async {
    await _asegurarCargado();
    return _cache.values.toList();
  }
}
