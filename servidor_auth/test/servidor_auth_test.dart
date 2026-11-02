import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:servidor_auth/repositorio/usuario_repositorio.dart';
import 'package:servidor_auth/seguridad/hasher.dart';
import 'package:servidor_auth/seguridad/jwt_servicio.dart';
import 'package:servidor_auth/servidor_app.dart';
import 'package:servidor_auth/servicios/auth_servicio.dart';
import 'package:test/test.dart';

void main() {
  group('Seguridad Criptográfica', () {
    test('Hasher genera hashes únicos con sal y verifica contraseñas correctamente', () {
      const hasher = HasherContrasena(iteraciones: 100);
      final hash1 = hasher.hashear('secreto123');
      final hash2 = hasher.hashear('secreto123');

      // Las sales deben ser distintas, por ende los hashes distintos
      expect(hash1, isNot(equals(hash2)));
      expect(hasher.verificar('secreto123', hash1), isTrue);
      expect(hasher.verificar('secreto123', hash2), isTrue);
      expect(hasher.verificar('passwordErroneo', hash1), isFalse);
    });

    test('JwtServicio emite y verifica tokens válidos', () {
      const jwt = JwtServicio(claveSecreta: 'clave_de_prueba');
      final token = jwt.generarToken(usuarioId: 'u1', email: 'test@example.com');

      final claims = jwt.verificarToken(token);
      expect(claims['sub'], 'u1');
      expect(claims['email'], 'test@example.com');
    });

    test('JwtServicio rechaza tokens adulterados', () {
      const jwt = JwtServicio(claveSecreta: 'clave_de_prueba');
      final token = jwt.generarToken(usuarioId: 'u1', email: 'test@example.com');
      final adulterado = '${token.substring(0, token.length - 4)}xxxx';

      expect(() => jwt.verificarToken(adulterado), throwsA(isA<TokenInvalidoException>()));
    });
  });

  group('Flujo Completo de Endpoints HTTP de ServidorApp', () {
    late ServidorApp app;
    late String baseUrl;
    final repoMemoria = UsuarioRepositorioMemoria();

    setUpAll(() async {
      app = ServidorApp(
        config: const ServidorConfig(
          puerto: 0, // Puerto efímero libre
          host: '127.0.0.1',
          claveJwt: 'jwt_test_key_xyz',
        ),
        customRepositorio: repoMemoria,
      );
      final server = await app.iniciar();
      baseUrl = 'http://127.0.0.1:${server.port}';
    });

    tearDownAll(() async {
      await app.detener();
    });

    test('Healthcheck responde OK', () async {
      final res = await http.get(Uri.parse('$baseUrl/health'));
      expect(res.statusCode, 200);
      expect(res.body, contains('Servidor Auth Brilliant'));
    });

    test('POST /api/auth/registro registra usuario correctamente', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/registro'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'jugador1@brilliant.com',
          'password': 'Password123',
        }),
      );

      expect(res.statusCode, 201);
      final json = jsonDecode(res.body);
      expect(json['exito'], isTrue);
      expect(json['datos']['token'], isNotEmpty);
      expect(json['datos']['usuario']['email'], 'jugador1@brilliant.com');
    });

    test('POST /api/auth/registro rechaza correo duplicado', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/registro'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'jugador1@brilliant.com',
          'password': 'Password123',
        }),
      );

      expect(res.statusCode, 409);
      final json = jsonDecode(res.body);
      expect(json['error'], contains('ya se encuentra registrado'));
    });

    test('POST /api/auth/registro rechaza contraseñas débiles', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/registro'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'nuevo@brilliant.com',
          'password': '123', // Muy corta y sin letras
        }),
      );

      expect(res.statusCode, 400);
      final json = jsonDecode(res.body);
      expect(json['error'], contains('al menos 6 caracteres'));
    });

    test('POST /api/auth/login inicia sesión y emite token válido', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'jugador1@brilliant.com',
          'password': 'Password123',
        }),
      );

      expect(res.statusCode, 200);
      final json = jsonDecode(res.body);
      expect(json['exito'], isTrue);
      expect(json['datos']['token'], isNotEmpty);
    });

    test('POST /api/auth/login rechaza credenciales erróneas', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'jugador1@brilliant.com',
          'password': 'ContrasenaIncorrecta99',
        }),
      );

      expect(res.statusCode, 401);
      final json = jsonDecode(res.body);
      expect(json['error'], contains('Credenciales incorrectas'));
    });

    test('GET /api/auth/perfil requiere token y devuelve datos', () async {
      // 1. Sin token
      final sinToken = await http.get(Uri.parse('$baseUrl/api/auth/perfil'));
      expect(sinToken.statusCode, 401);

      // 2. Con token obtenido del login
      final loginRes = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'jugador1@brilliant.com',
          'password': 'Password123',
        }),
      );
      final token = jsonDecode(loginRes.body)['datos']['token'] as String;

      final perfilRes = await http.get(
        Uri.parse('$baseUrl/api/auth/perfil'),
        headers: {'Authorization': 'Bearer $token'},
      );

      expect(perfilRes.statusCode, 200);
      final perfilJson = jsonDecode(perfilRes.body);
      expect(perfilJson['datos']['email'], 'jugador1@brilliant.com');
    });

    test('DELETE /api/auth/cuenta elimina la cuenta con confirmación de clave', () async {
      // 1. Iniciar sesión para obtener token
      final loginRes = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'jugador1@brilliant.com',
          'password': 'Password123',
        }),
      );
      final token = jsonDecode(loginRes.body)['datos']['token'] as String;

      // 2. Intentar borrar con contraseña incorrecta
      final intentoFallido = await http.delete(
        Uri.parse('$baseUrl/api/auth/cuenta'),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': 'claveErronea'}),
      );
      expect(intentoFallido.statusCode, 400);

      // 3. Borrar con contraseña correcta
      final borradoExitoso = await http.delete(
        Uri.parse('$baseUrl/api/auth/cuenta'),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': 'Password123'}),
      );
      expect(borradoExitoso.statusCode, 200);

      // 4. Verificar que ya no se puede iniciar sesión
      final loginPostBorrado = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'jugador1@brilliant.com',
          'password': 'Password123',
        }),
      );
      expect(loginPostBorrado.statusCode, 401);
    });
  });
}
