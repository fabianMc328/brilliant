import 'package:flutter_bloc/flutter_bloc.dart';

import '../dominio/repositorio_autenticacion.dart';
import 'auth_estado.dart';
import 'auth_evento.dart';

/// BLoC que orquesta la autenticación tradicional y sesión persistida.
class AuthBloc extends Bloc<AuthEvento, AuthEstado> {
  final RepositorioAutenticacion _repositorio;

  AuthBloc({required RepositorioAutenticacion repositorio})
      : _repositorio = repositorio,
        super(const AuthInicial()) {
    on<ComprobarSesionInicial>(_onComprobarSesion);
    on<IniciarSesionSolicitado>(_onIniciarSesion);
    on<RegistrarUsuarioSolicitado>(_onRegistrarUsuario);
    on<CerrarSesionSolicitado>(_onCerrarSesion);
    on<LimpiarErrorAuth>(_onLimpiarError);
  }

  Future<void> _onComprobarSesion(
    ComprobarSesionInicial event,
    Emitter<AuthEstado> emit,
  ) async {
    emit(const AuthCargando(mensaje: 'Comprobando sesión...'));
    try {
      final usuario = await _repositorio.obtenerUsuarioSesion();
      if (usuario != null) {
        emit(AuthAutenticado(usuario: usuario));
      } else {
        emit(const AuthNoAutenticado());
      }
    } catch (_) {
      emit(const AuthNoAutenticado());
    }
  }

  Future<void> _onIniciarSesion(
    IniciarSesionSolicitado event,
    Emitter<AuthEstado> emit,
  ) async {
    emit(const AuthCargando(mensaje: 'Iniciando sesión...'));
    try {
      final usuario = await _repositorio.iniciarSesion(
        identificador: event.identificador,
        contrasena: event.contrasena,
      );
      emit(AuthAutenticado(usuario: usuario));
    } on FalloAutenticacion catch (e) {
      emit(AuthNoAutenticado(mensajeError: e.mensaje));
    } catch (e) {
      emit(const AuthNoAutenticado(
        mensajeError: 'Ocurrió un error inesperado al iniciar sesión.',
      ));
    }
  }

  Future<void> _onRegistrarUsuario(
    RegistrarUsuarioSolicitado event,
    Emitter<AuthEstado> emit,
  ) async {
    if (event.contrasena != event.confirmacionContrasena) {
      emit(const AuthNoAutenticado(
        mensajeError: 'Las contraseñas no coinciden.',
      ));
      return;
    }

    emit(const AuthCargando(mensaje: 'Creando tu cuenta...'));
    try {
      final usuario = await _repositorio.registrarUsuario(
        apodo: event.apodo,
        email: event.email,
        contrasena: event.contrasena,
      );
      emit(AuthAutenticado(usuario: usuario));
    } on FalloAutenticacion catch (e) {
      emit(AuthNoAutenticado(mensajeError: e.mensaje));
    } catch (e) {
      emit(const AuthNoAutenticado(
        mensajeError: 'Ocurrió un error inesperado al registrarte.',
      ));
    }
  }

  Future<void> _onCerrarSesion(
    CerrarSesionSolicitado event,
    Emitter<AuthEstado> emit,
  ) async {
    emit(const AuthCargando(mensaje: 'Cerrando sesión...'));
    await _repositorio.cerrarSesion();
    emit(const AuthNoAutenticado(mensajeExito: 'Sesión cerrada correctamente.'));
  }

  void _onLimpiarError(
    LimpiarErrorAuth event,
    Emitter<AuthEstado> emit,
  ) {
    if (state is AuthNoAutenticado) {
      emit((state as AuthNoAutenticado).copiarCon(limpiarError: true));
    }
  }
}
