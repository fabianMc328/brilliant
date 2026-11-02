import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'api/auth_controlador.dart';
import 'api/cors_middleware.dart';
import 'repositorio/usuario_repositorio.dart';
import 'seguridad/hasher.dart';
import 'seguridad/jwt_servicio.dart';
import 'servicios/auth_servicio.dart';

class ServidorConfig {
  final int puerto;
  final String host;
  final String claveJwt;
  final File? archivoUsuarios;
  final String? directorioWeb;

  const ServidorConfig({
    this.puerto = 8080,
    this.host = '0.0.0.0',
    this.claveJwt = 'brilliant_super_secret_jwt_key_2026_xyz!',
    this.archivoUsuarios,
    this.directorioWeb = '../build/web',
  });
}

class ServidorApp {
  final ServidorConfig config;
  late final UsuarioRepositorio repositorio;
  late final HasherContrasena hasher;
  late final JwtServicio jwtServicio;
  late final AuthServicio authServicio;
  late final AuthControlador controlador;
  HttpServer? _servidor;

  ServidorApp({ServidorConfig? config, UsuarioRepositorio? customRepositorio})
      : config = config ?? const ServidorConfig() {
    repositorio = customRepositorio ??
        (this.config.archivoUsuarios != null
            ? UsuarioRepositorioJson(archivo: this.config.archivoUsuarios!)
            : UsuarioRepositorioMemoria());

    hasher = const HasherContrasena();
    jwtServicio = JwtServicio(claveSecreta: this.config.claveJwt);
    authServicio = AuthServicio(
      usuarioRepositorio: repositorio,
      hasher: hasher,
      jwtServicio: jwtServicio,
    );
    controlador = AuthControlador(
      authServicio: authServicio,
      jwtServicio: jwtServicio,
    );
  }

  Handler crearHandler() {
    final routerPrincipal = Router();

    // Healthcheck
    routerPrincipal.get('/health', (Request request) {
      return Response.ok('{"status": "ok", "app": "Servidor Auth Brilliant"}',
          headers: {'content-type': 'application/json'});
    });

    // Rutas de auth montadas bajo /api/auth/
    routerPrincipal.mount('/api/auth/', controlador.router.call);

    // Servir cliente Web (build/web) si existe
    Handler? staticHandler;
    if (config.directorioWeb != null) {
      var dir = Directory(config.directorioWeb!);
      if (!dir.existsSync()) {
        // Si se ejecutó desde la raíz del proyecto en vez de servidor_auth/
        final altPath = config.directorioWeb!.startsWith('../')
            ? config.directorioWeb!.substring(3)
            : '../${config.directorioWeb!}';
        final altDir = Directory(altPath);
        if (altDir.existsSync()) {
          dir = altDir;
        }
      }
      if (dir.existsSync()) {
        staticHandler = createStaticHandler(
          dir.path,
          defaultDocument: 'index.html',
        );
      }
    }

    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsMiddleware())
        .addHandler((Request request) async {
          final response = await routerPrincipal.call(request);
          // Si no es endpoint de API ni health, y existe el bundle web, servir archivo estático
          if (response.statusCode == 404 && staticHandler != null) {
            return await staticHandler(request);
          }
          return response;
        });

    return pipeline;
  }

  Future<HttpServer> iniciar() async {
    final handler = crearHandler();
    _servidor = await shelf_io.serve(handler, config.host, config.puerto);
    return _servidor!;
  }

  Future<void> detener() async {
    await _servidor?.close(force: true);
    _servidor = null;
  }
}
