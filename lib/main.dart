import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth/bloc/auth_bloc.dart';
import 'auth/bloc/auth_evento.dart';
import 'auth/repositorio/auth_repositorio.dart';
import 'auth/repositorio/http_auth_repositorio.dart';
import 'auth/vistas/auth_guard.dart';
import 'pantalla_seleccion_nivel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AplicacionBrilliant(requerirAutenticacion: true));
}

class AplicacionBrilliant extends StatelessWidget {
  final Widget? pantallaInicial;
  final AuthRepositorio? authRepositorio;
  final bool requerirAutenticacion;

  const AplicacionBrilliant({
    super.key,
    this.pantallaInicial,
    this.authRepositorio,
    this.requerirAutenticacion = false,
  });

  @override
  Widget build(BuildContext context) {
    final repo = authRepositorio ?? HttpAuthRepositorio();

    return BlocProvider(
      create: (context) => AuthBloc(authRepositorio: repo)
        ..add(const VerificarSesionInicial()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Brilliant',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        ),
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // En pantallas de escritorio o tablets anchas (laptops/monitores),
              // enmarcamos el juego en un contenedor centrado con proporción móvil
              // para que no se deforme ni se estire a los extremos.
              if (constraints.maxWidth > 520) {
                final mediaQuery = MediaQuery.of(context);
                const double anchoMaximo = 460.0;

                return Scaffold(
                  backgroundColor: const Color(0xFF0F172A), // Fondo dark slate profesional
                  body: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: anchoMaximo),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: MediaQuery(
                        data: mediaQuery.copyWith(
                          size: Size(anchoMaximo, mediaQuery.size.height),
                        ),
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              }

              // En celulares, ocupa el 100% de la pantalla de forma nativa
              return child ?? const SizedBox.shrink();
            },
          );
        },
        home: pantallaInicial ??
            (requerirAutenticacion
                ? const AuthGuard(child: PantallaSeleccionNivel())
                : const PantallaSeleccionNivel()),
      ),
    );
  }
}
