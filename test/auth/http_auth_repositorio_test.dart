import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:brilliant/auth/repositorio/auth_repositorio.dart';
import 'package:brilliant/auth/repositorio/http_auth_repositorio.dart';
import 'package:brilliant/auth/repositorio/token_almacenamiento.dart';

void main() {
  group('HttpAuthRepositorio', () {
    late TokenAlmacenamientoMemoria tokenStorage;

    setUp(() {
      tokenStorage = TokenAlmacenamientoMemoria();
    });

    test('registrar() envía datos y guarda token en almacenamiento', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/auth/registro');
        final body = jsonDecode(request.body);
        expect(body['email'], 'test@brilliant.com');
        expect(body['password'], 'Password123');

        return http.Response(
          jsonEncode({
            'exito': true,
            'datos': {
              'token': 'jwt_registro_123',
              'usuario': {
                'id': 'usr_1',
                'email': 'test@brilliant.com',
              },
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HttpAuthRepositorio(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      final sesion = await repo.registrar(
        email: 'test@brilliant.com',
        password: 'Password123',
      );

      expect(sesion.token, 'jwt_registro_123');
      expect(sesion.email, 'test@brilliant.com');
      expect(await tokenStorage.obtenerToken(), 'jwt_registro_123');
    });

    test('iniciarSesion() maneja error 401 del servidor con excepción legible', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Credenciales incorrectas.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HttpAuthRepositorio(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      expect(
        () => repo.iniciarSesion(email: 'err@brilliant.com', password: 'mal'),
        throwsA(predicate<AuthClienteException>(
          (e) => e.mensaje.contains('Credenciales incorrectas'),
        )),
      );
    });

    test('eliminarCuenta() envía token en Authorization y borra almacenamiento al terminar', () async {
      await tokenStorage.guardarToken('token_a_borrar');

      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/auth/cuenta');
        expect(request.headers['Authorization'], 'Bearer token_a_borrar');

        final body = jsonDecode(request.body);
        expect(body['password'], 'PasswordValida123');

        return http.Response(
          jsonEncode({'exito': true, 'mensaje': 'Cuenta eliminada'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HttpAuthRepositorio(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      await repo.eliminarCuenta(passwordConfirmacion: 'PasswordValida123');
      expect(await tokenStorage.obtenerToken(), isNull);
    });
  });
}
