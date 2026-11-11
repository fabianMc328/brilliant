import 'package:flutter/material.dart';

import '../../pantalla_seleccion_nivel.dart';
import '../dominio/repositorio_multijugador.dart';
import 'pantalla_lobby_multijugador.dart';

/// Menú de bienvenida para elegir entre Modo Solitario o Multijugador (2 a 6 jugadores).
class PantallaInicioModo extends StatelessWidget {
  final RepositorioMultijugador? repositorioMultijugador;

  const PantallaInicioModo({
    super.key,
    this.repositorioMultijugador,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const Icon(
                    Icons.diamond_rounded,
                    size: 56,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Brilliant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Estrategia numérica en tableros de regiones.\nJuega a tu ritmo o compite en vivo con tus amigos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TarjetaModoJuego(
                    keyBoton: const Key('boton_modo_solitario'),
                    icono: Icons.person_rounded,
                    colorAcento: const Color(0xFF2563EB),
                    titulo: 'Modo Solitario',
                    subtitulo:
                        'Practica en cualquiera de los 4 tableros oficiales y supera tu récord.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PantallaSeleccionNivel(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _TarjetaModoJuego(
                    keyBoton: const Key('boton_modo_multijugador'),
                    icono: Icons.groups_rounded,
                    colorAcento: const Color(0xFF059669),
                    titulo: 'Multijugador (2 a 6 Jugadores)',
                    subtitulo:
                        'Lobby con código de invitación, mismo mapa, dados simultáneos y carrera por regiones.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PantallaLobbyMultijugador(
                            repositorioExterno: repositorioMultijugador,
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
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _TarjetaModoJuego({
    required this.keyBoton,
    required this.icono,
    required this.colorAcento,
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorAcento.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icono, color: colorAcento, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
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
            Icon(Icons.chevron_right_rounded, color: colorAcento),
          ],
        ),
      ),
    );
  }
}
