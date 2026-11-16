import 'package:flutter/material.dart';

import '../../niveles/catalogo_niveles.dart';
import '../../niveles/nivel_definicion.dart';
import 'miniatura_mapa_multijugador.dart';

/// Ventana emergente para visualizar todos los tableros con su imagen y seleccionar uno.
class DialogoSelectorMapaMultijugador extends StatelessWidget {
  final String nivelActualId;

  const DialogoSelectorMapaMultijugador({
    super.key,
    required this.nivelActualId,
  });

  static Future<String?> mostrar(
    BuildContext context, {
    required String nivelActualId,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => DialogoSelectorMapaMultijugador(
        nivelActualId: nivelActualId,
      ),
    );
  }

  Color _colorDificultad(String dificultad) {
    switch (dificultad.toLowerCase()) {
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
    final niveles = CatalogoNiveles.todos;

    return Dialog(
      key: const Key('dialogo_selector_mapa'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Seleccionar mapa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Lista visual de los 4 mapas con su vista previa 7x7
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(14),
                itemCount: niveles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final nivel = niveles[index];
                  final seleccionado = nivel.id == nivelActualId;
                  return _TarjetaOpcionMapa(
                    nivel: nivel,
                    seleccionado: seleccionado,
                    colorDificultad: _colorDificultad(nivel.dificultad),
                    onTap: () => Navigator.of(context).pop(nivel.id),
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

class _TarjetaOpcionMapa extends StatelessWidget {
  final NivelDefinicion nivel;
  final bool seleccionado;
  final Color colorDificultad;
  final VoidCallback onTap;

  const _TarjetaOpcionMapa({
    required this.nivel,
    required this.seleccionado,
    required this.colorDificultad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('opcion_mapa_${nivel.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: seleccionado
              ? Colors.blue.shade50.withValues(alpha: 0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? Colors.blue.shade600 : Colors.blueGrey.shade100,
            width: seleccionado ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            MiniaturaMapaMultijugador(
              nivel: nivel,
              tamano: 76,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nivel.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorDificultad.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colorDificultad, width: 0.8),
                        ),
                        child: Text(
                          nivel.dificultad,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: colorDificultad,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nivel.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.blueGrey.shade700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${nivel.regiones.length} regiones • ${nivel.casillasIniciales.length} estrellas',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              seleccionado
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: seleccionado ? Colors.blue.shade700 : Colors.blueGrey.shade300,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
