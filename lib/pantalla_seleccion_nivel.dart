import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'juego_bloc.dart';
import 'niveles/catalogo_niveles.dart';
import 'niveles/nivel_definicion.dart';
import 'pantalla_juego.dart';
import 'region.dart';

// Pantalla para elegir el nivel antes de jugar.
class PantallaSeleccionNivel extends StatelessWidget {
  const PantallaSeleccionNivel({super.key});

  @override
  Widget build(BuildContext context) {
    final niveles = CatalogoNiveles.todos;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Brilliant',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  const Text(
                    'Selecciona tu Tablero',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cada tablero ofrece un mapa y restricciones únicas de colocación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                itemCount: niveles.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final nivel = niveles[index];
                  return _TarjetaNivel(
                    nivel: nivel,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => JuegoBloc(),
                            child: PantallaJuego(nivel: nivel),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tarjeta de cada nivel en la lista.
class _TarjetaNivel extends StatelessWidget {
  final NivelDefinicion nivel;
  final VoidCallback onTap;

  const _TarjetaNivel({
    required this.nivel,
    required this.onTap,
  });

  Color _obtenerColorDificultad(String dif) {
    switch (dif.toLowerCase()) {
      case 'fácil':
        return const Color(0xFF10B981);
      case 'intermedio':
        return const Color(0xFFF59E0B);
      case 'avanzado':
        return const Color(0xFFEC4899);
      case 'experto':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorDif = _obtenerColorDificultad(nivel.dificultad);

    return InkWell(
      key: ValueKey('tarjeta_nivel_${nivel.numero}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueGrey.shade100, width: 1.5),
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
            // Mini mapa
            _MiniaturaTablero(nivel: nivel),
            const SizedBox(width: 12),

            // Info del nivel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nivel.nombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorDif.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorDif, width: 1),
                          ),
                          child: Text(
                            nivel.dificultad,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: colorDif,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    nivel.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey.shade700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.layers_outlined,
                          size: 14, color: Colors.blueGrey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${nivel.regiones.length} regiones • 6 estrellas',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Botón para entrar al nivel
            ElevatedButton(
              key: Key('boton_jugar_nivel_${nivel.numero}'),
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
                elevation: 1,
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// Dibuja el mini mapa de 7x7 en chiquito.
class _MiniaturaTablero extends StatelessWidget {
  final NivelDefinicion nivel;

  const _MiniaturaTablero({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final tablero = nivel.crearTablero();

    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200, width: 1.2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 1.0,
          mainAxisSpacing: 1.0,
        ),
        itemCount: 49,
        itemBuilder: (context, index) {
          final fila = index ~/ 7;
          final columna = index % 7;
          final coord = Coordenada(fila, columna);
          final celda = tablero.celdas[coord];
          final color = celda?.region.tipo.color ?? Colors.grey;

          return Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        },
      ),
    );
  }
}
