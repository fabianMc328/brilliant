import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'autenticacion/bloc/auth_bloc.dart';
import 'autenticacion/bloc/auth_estado.dart';
import 'autenticacion/bloc/auth_evento.dart';
import 'autenticacion/dominio/repositorio_autenticacion.dart';
import 'autenticacion/infraestructura/repositorio_autenticacion_local.dart';
import 'autenticacion/vistas/pantalla_login.dart';
import 'multijugador/vistas/pantalla_inicio_modo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AplicacionBrilliant());
}

class AplicacionBrilliant extends StatelessWidget {
  final Widget? pantallaInicial;
  final RepositorioAutenticacion? repositorioAuth;

  const AplicacionBrilliant({
    super.key,
    this.pantallaInicial,
    this.repositorioAuth,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<RepositorioAutenticacion>(
      create: (_) => repositorioAuth ?? RepositorioAutenticacionLocal(),
      child: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(
          repositorio: context.read<RepositorioAutenticacion>(),
        )..add(const ComprobarSesionInicial()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Brilliant',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
          ),
          home: pantallaInicial ?? const _EnrutadorRaizAuth(),
        ),
      ),
    );
  }
}

class _EnrutadorRaizAuth extends StatelessWidget {
  const _EnrutadorRaizAuth();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthEstado>(
      builder: (context, state) {
        if (state is AuthAutenticado) {
          return PantallaInicioModo(usuarioAutenticado: state.usuario);
        }
        if (state is AuthCargando && state.mensaje != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2563EB)),
                  const SizedBox(height: 16),
                  Text(
                    state.mensaje!,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const PantallaLogin();
      },
    );
  }
}
