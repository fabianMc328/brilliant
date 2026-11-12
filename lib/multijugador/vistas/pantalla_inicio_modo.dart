import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../autenticacion/bloc/auth_bloc.dart';
import '../../autenticacion/bloc/auth_evento.dart';
import '../../autenticacion/dominio/usuario.dart';
import '../../pantalla_seleccion_nivel.dart';
import '../../widgets/dialogo_como_jugar.dart';
import '../dominio/repositorio_multijugador.dart';
import 'pantalla_lobby_multijugador.dart';

/// Menú de bienvenida para elegir entre Modo Solitario o Multijugador (2 a 6 jugadores).
class PantallaInicioModo extends StatelessWidget {
  final RepositorioMultijugador? repositorioMultijugador;
  final Usuario? usuarioAutenticado;

  const PantallaInicioModo({
    super.key,
    this.repositorioMultijugador,
    this.usuarioAutenticado,
  });

  void _mostrarDialogoPerfil(BuildContext context, Usuario usuario) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                usuario.apodo.isNotEmpty ? usuario.apodo[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              usuario.apodo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              usuario.email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              key: const Key('boton_cerrar_sesion_modal'),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(const CerrarSesionSolicitado());
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta superior de bienvenida y usuario
                  if (usuarioAutenticado != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.blue.shade50.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _mostrarDialogoPerfil(context, usuarioAutenticado!),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF2563EB),
                              child: Text(
                                usuarioAutenticado!.apodo.isNotEmpty
                                    ? usuarioAutenticado!.apodo[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _mostrarDialogoPerfil(context, usuarioAutenticado!),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '¡Bienvenido de vuelta!',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey.shade600,
                                    ),
                                  ),
                                  Text(
                                    usuarioAutenticado!.apodo,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            key: const Key('boton_cerrar_sesion'),
                            onPressed: () {
                              context.read<AuthBloc>().add(const CerrarSesionSolicitado());
                            },
                            icon: const Icon(Icons.logout_rounded, size: 15, color: Color(0xFFDC2626)),
                            label: const Text(
                              'Salir',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Logo e identidad de marca
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.diamond_rounded,
                      size: 36,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Brilliant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Juego de tablero y lógica de dados en regiones',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Botón "¿Cómo Jugar?"
                  InkWell(
                    key: const Key('boton_como_jugar_inicio'),
                    onTap: () => DialogoComoJugar.mostrar(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade400, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.help_outline_rounded,
                              color: Colors.amber.shade900, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Cómo Jugar?',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                Text(
                                  'Reglas detalladas de los 8 colores, dados y puntos',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.amber.shade800, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tarjeta Modo Solitario
                  _TarjetaModoJuego(
                    keyBoton: const Key('boton_modo_solitario'),
                    icono: Icons.person_rounded,
                    colorAcento: const Color(0xFF2563EB),
                    etiquetaBadge: '1 Jugador',
                    titulo: 'Modo Solitario',
                    subtitulo:
                        'Elige entre los 4 tableros oficiales, coloca tus dados con estrategia y maximiza tu puntuación.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PantallaSeleccionNivel(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Tarjeta Multijugador
                  _TarjetaModoJuego(
                    keyBoton: const Key('boton_modo_multijugador'),
                    icono: Icons.groups_rounded,
                    colorAcento: const Color(0xFF059669),
                    etiquetaBadge: 'En Vivo',
                    titulo: 'Multijugador (2 a 6 Jugadores)',
                    subtitulo:
                        'Crea o únete a salas con código de invitación, compite en tiempo real, usa el chat y gana la carrera de regiones.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PantallaLobbyMultijugador(
                            repositorioExterno: repositorioMultijugador,
                            apodoInicial: usuarioAutenticado?.apodo,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaModoJuego extends StatelessWidget {
  final Key keyBoton;
  final IconData icono;
  final Color colorAcento;
  final String etiquetaBadge;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _TarjetaModoJuego({
    required this.keyBoton,
    required this.icono,
    required this.colorAcento,
    required this.etiquetaBadge,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: keyBoton,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorAcento.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorAcento.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icono, color: colorAcento, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorAcento.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          etiquetaBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: colorAcento,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: colorAcento, size: 24),
          ],
        ),
      ),
    );
  }
}
