import 'dart:io';
import 'package:servidor_auth/servidor_app.dart';

void main(List<String> args) async {
  final puertoEnv = Platform.environment['PORT'];
  final puerto = puertoEnv != null ? int.tryParse(puertoEnv) ?? 8080 : 8080;

  final rutaArchivo = Platform.environment['USERS_DB_PATH'] ?? 'datos/usuarios.json';
  final archivoUsuarios = File(rutaArchivo);

  final config = ServidorConfig(
    puerto: puerto,
    host: '0.0.0.0',
    archivoUsuarios: archivoUsuarios,
    directorioWeb: '../build/web',
  );

  final app = ServidorApp(config: config);
  final servidor = await app.iniciar();

  print('=====================================================');
  print(' Servidor y Juego Brilliant Activos');
  print('=====================================================');
  print(' Puedes jugar directamente abriendo en Microsoft Edge:');
  print('   -> http://localhost:${servidor.port}');
  print('');
  print(' Credenciales preconfiguradas:');
  print('   Usuario: admin');
  print('   Contrasena: admin123');
  print('=====================================================');
}
