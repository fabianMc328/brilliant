import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositorio/auth_repositorio.dart';
import 'auth_estado.dart';
import 'auth_evento.dart';

class AuthBloc extends Bloc<AuthEvento, AuthEstado> {
  final AuthRepositorio authRepositorio;

  // Inicia inmediatamente en NoAutenticado para que la pantalla de Login esté lista y activa
  AuthBloc({required this.authRepositorio}) : super(const NoAutenticado()) {
    on<VerificarSesionInicial>(_onVerificarSesionInicial);
    on<IniciarSesionSolicitado>(_onIniciarSesionSolicitado);
    on<RegistrarSolicitado>(_onRegistrarSolicitado);
    on<CerrarSesionSolicitado>(_onCerrarSesionSolicitado);
    on<EliminarCuentaSolicitada>(_onEliminarCuentaSolicitada);
  }

  Future<void> _onVerificarSesionInicial(
    VerificarSesionInicial event,
    Emitter<AuthEstado> emit,
  ) async {
    // Verificación silenciosa en segundo plano sin bloquear ni congelar los botones
    try {
      final sesion = await authRepositorio
          .obtenerSesionActual()
          .timeout(const Duration(seconds: 1));

      if (sesion != null) {
        emit(Autenticado(usuario: sesion));
      } else {
        emit(const NoAutenticado());
      }
    } catch (_) {
      emit(const NoAutenticado());
    }
  }

  Future<void> _onIniciarSesionSolicitado(
    IniciarSesionSolicitado event,
    Emitter<AuthEstado> emit,
  ) async {
    final identificador = event.email.trim();
    final password = event.password;

    if (identificador.isEmpty || password.isEmpty) {
      emit(AuthError(
        mensaje: 'Por favor, ingresa tu usuario y contraseña.',
        estadoPrevio: state,
      ));
      return;
    }

    emit(const AuthCargando(mensaje: 'Iniciando sesión...'));
    try {
      final sesion = await authRepositorio.iniciarSesion(
        email: identificador,
        password: password,
      );
      emit(Autenticado(usuario: sesion));
    } on AuthClienteException catch (e) {
      emit(AuthError(mensaje: e.mensaje, estadoPrevio: const NoAutenticado()));
    } catch (e) {
      emit(AuthError(
        mensaje: 'Error inesperado al iniciar sesión.',
        estadoPrevio: const NoAutenticado(),
      ));
    }
  }

  Future<void> _onRegistrarSolicitado(
    RegistrarSolicitado event,
    Emitter<AuthEstado> emit,
  ) async {
    final identificador = event.email.trim();
    final password = event.password;
    final confirm = event.confirmacionPassword;

    if (identificador.isEmpty || password.isEmpty || confirm.isEmpty) {
      emit(AuthError(
        mensaje: 'Todos los campos son obligatorios.',
        estadoPrevio: state,
      ));
      return;
    }

    if (password != confirm) {
      emit(AuthError(
        mensaje: 'Las contraseñas no coinciden.',
        estadoPrevio: state,
      ));
      return;
    }

    if (password.length < 6) {
      emit(AuthError(
        mensaje: 'La contraseña debe tener al menos 6 caracteres.',
        estadoPrevio: state,
      ));
      return;
    }

    emit(const AuthCargando(mensaje: 'Creando tu cuenta...'));
    try {
      final sesion = await authRepositorio.registrar(
        email: identificador,
        password: password,
      );
      emit(Autenticado(usuario: sesion));
    } on AuthClienteException catch (e) {
      emit(AuthError(mensaje: e.mensaje, estadoPrevio: const NoAutenticado()));
    } catch (e) {
      emit(AuthError(
        mensaje: 'Error inesperado al registrar cuenta.',
        estadoPrevio: const NoAutenticado(),
      ));
    }
  }

  Future<void> _onCerrarSesionSolicitado(
    CerrarSesionSolicitado event,
    Emitter<AuthEstado> emit,
  ) async {
    emit(const AuthCargando(mensaje: 'Cerrando sesión...'));
    await authRepositorio.cerrarSesion();
    emit(const NoAutenticado(mensajeInformativo: 'Sesión cerrada exitosamente.'));
  }

  Future<void> _onEliminarCuentaSolicitada(
    EliminarCuentaSolicitada event,
    Emitter<AuthEstado> emit,
  ) async {
    final password = event.passwordConfirmacion;
    if (password.isEmpty) {
      emit(AuthError(
        mensaje: 'Debes confirmar con tu contraseña para eliminar la cuenta.',
        estadoPrevio: state,
      ));
      return;
    }

    final estadoAnterior = state;
    emit(const AuthCargando(mensaje: 'Eliminando cuenta...'));
    try {
      await authRepositorio.eliminarCuenta(passwordConfirmacion: password);
      emit(const NoAutenticado(
        mensajeInformativo: 'Tu cuenta ha sido eliminada definitivamente.',
      ));
    } on AuthClienteException catch (e) {
      emit(AuthError(mensaje: e.mensaje, estadoPrevio: estadoAnterior));
    } catch (e) {
      emit(AuthError(
        mensaje: 'Error inesperado al intentar eliminar la cuenta.',
        estadoPrevio: estadoAnterior,
      ));
    }
  }
}
