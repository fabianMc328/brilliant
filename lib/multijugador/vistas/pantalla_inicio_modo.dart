import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../autenticacion/bloc/auth_bloc.dart';
import '../../autenticacion/bloc/auth_evento.dart';
import '../../autenticacion/dominio/usuario.dart';
import '../../pantalla_seleccion_nivel.dart';
import '../../rankings/infraestructura/servicio_rankings.dart';
import '../../rankings/vistas/dialogo_rankings.dart';
import '../../widgets/dialogo_como_jugar.dart';
import '../dominio/repositorio_multijugador.dart';
import 'pantalla_lobby_multijugador.dart';

/// Menú de bienvenida para elegir entre Modo Solitario o Multijugador (2 a 6 jugadores).
class PantallaInicioModo extends StatelessWidget {
  final RepositorioMultijugador? repositorioMultijugador;
  final Usuario? usuarioAutenticado;
  final ServicioRankings? servicioRankings;

  const PantallaInicioModo({
    super.key,
    this.repositorioMultijugador,
    this.usuarioAutenticado,
    this.servicioRankings,
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
        child: Column(
          children: [
            // Botones en las esquinas superiores: Cómo jugar (izq) y Salir (der)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    key: const Key('boton_como_jugar_inicio'),
                    onPressed: () => DialogoComoJugar.mostrar(context),
                    icon: Icon(
                      Icons.help_outline_rounded,
                      size: 16,
                      color: Colors.amber.shade900,
                    ),
                    label: Text(
                      'Cómo jugar',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.amber.shade50,
                      side: BorderSide(color: Colors.amber.shade400),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (usuarioAutenticado != null)
                    OutlinedButton.icon(
                      key: const Key('boton_cerrar_sesion'),
                      onPressed: () {
                        context
                            .read<AuthBloc>()
                            .add(const CerrarSesionSolicitado());
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                      label: const Text(
                        'Salir',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Texto centrado arriba del logo
                        if (usuarioAutenticado != null) ...[
                          GestureDetector(
                            onTap: () => _mostrarDialogoPerfil(
                              context,
                              usuarioAutenticado!,
                            ),
                            child: Text(
                              'Bienvenido, ${usuarioAutenticado!.apodo}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Logo igual al del login
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.casino,
                              color: Colors.amber,
                              size: 44,
                            ),
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
                        const SizedBox(height: 24),

                        // Apartado Modos de juego
                        const Text(
                          'Modos de juego',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),

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
                              'Crea o únete a salas con el código para competir con tus amigos.',
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
                        const SizedBox(height: 14),

                        // Tarjeta Tabla de Rankings
                        _TarjetaModoJuego(
                          keyBoton: const Key('boton_abrir_rankings'),
                          icono: Icons.emoji_events_rounded,
                          colorAcento: const Color(0xFFD97706),
                          etiquetaBadge: 'Top Global',
                          titulo: 'Tabla de Rankings',
                          subtitulo:
                              'Consulta los líderes por victorias en Multijugador y los mejores récords en Solitario.',
                          onTap: () {
                            DialogoRankings.mostrar(
                              context,
                              miApodo: usuarioAutenticado?.apodo,
                              servicio: servicioRankings,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
