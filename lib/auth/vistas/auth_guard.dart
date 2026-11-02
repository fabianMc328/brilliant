import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_estado.dart';
import 'pantalla_login.dart';

/// Guarda de autenticación reactiva:
/// Muestra de inmediato PantallaLogin si no hay sesión iniciada,
/// o el contenido del juego ([child]) si el usuario está autenticado.
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthEstado>(
      builder: (context, state) {
        if (state is Autenticado) {
          return child;
        }

        // Abre inmediatamente la pantalla de Login sin demoras ni pantallas trabadas
        return const PantallaLogin();
      },
    );
  }
}
