import 'package:flutter/material.dart';

import '../dominio/entrada_ranking.dart';
import '../infraestructura/servicio_rankings.dart';

/// Diálogo interactivo de Rankings (Multijugador y Solitario) con sincronización en vivo.
class DialogoRankings extends StatefulWidget {
  final String? miApodo;
  final ServicioRankings servicio;

  const DialogoRankings({
    super.key,
    this.miApodo,
    this.servicio = const ServicioRankings(),
  });

  static Future<void> mostrar(
    BuildContext context, {
    String? miApodo,
    ServicioRankings? servicio,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogoRankings(
        miApodo: miApodo,
        servicio: servicio ?? const ServicioRankings(),
      ),
    );
  }

  @override
  State<DialogoRankings> createState() => _DialogoRankingsState();
}

class _DialogoRankingsState extends State<DialogoRankings>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  TablaRankings _tabla = TablaRankings.vacia();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarRankings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarRankings() async {
    setState(() => _cargando = true);
    final tabla = await widget.servicio.obtenerRankings();
    if (!mounted) return;
    setState(() {
      _tabla = tabla;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('dialogo_rankings'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber.shade900,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tabla de Rankings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Clasificación global de jugadores',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('boton_refrescar_rankings'),
                    tooltip: 'Actualizar',
                    onPressed: _cargando ? null : _cargarRankings,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    key: const Key('boton_cerrar_rankings'),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.blueGrey.shade700,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Multijugador'),
                    Tab(text: 'Solitario'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _construirLista(
                            entradas: _tabla.multijugador,
                            esMultijugador: true,
                          ),
                          _construirLista(
                            entradas: _tabla.solitario,
                            esMultijugador: false,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirLista({
    required List<EntradaRanking> entradas,
    required bool esMultijugador,
  }) {
    if (entradas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Aún no hay jugadores registrados en el ranking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade600,
            ),
          ),
        ),
      );
    }

    final miApodoLower = widget.miApodo?.trim().toLowerCase();

    return ListView.separated(
      itemCount: entradas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = entradas[index];
        final posicion = index + 1;
        final esYo = miApodoLower != null &&
            miApodoLower.isNotEmpty &&
            item.apodo.trim().toLowerCase() == miApodoLower;

        return _FilaRanking(
          posicion: posicion,
          entrada: item,
          esYo: esYo,
          esMultijugador: esMultijugador,
        );
      },
    );
  }
}

class _FilaRanking extends StatelessWidget {
  final int posicion;
  final EntradaRanking entrada;
  final bool esYo;
  final bool esMultijugador;

  const _FilaRanking({
    required this.posicion,
    required this.entrada,
    required this.esYo,
    required this.esMultijugador,
  });

  Color _colorMedalla() {
    if (posicion == 1) return const Color(0xFFF59E0B);
    if (posicion == 2) return const Color(0xFF94A3B8);
    if (posicion == 3) return const Color(0xFFD97706);
    return const Color(0xFFE2E8F0);
  }

  @override
  Widget build(BuildContext context) {
    final esPodio = posicion <= 3;
    final badgeColor = _colorMedalla();

    final String valorPrincipal = esMultijugador
        ? '${entrada.victoriasMulti} ${entrada.victoriasMulti == 1 ? 'victoria' : 'victorias'}'
        : '${entrada.mejorPuntajeSolitario} pts';

    final String subtitulo = esMultijugador
        ? 'Mejor: ${entrada.mejorPuntajeMulti} pts • Total: ${entrada.puntosTotalesMulti} pts • ${entrada.partidasMulti} jugadas'
        : 'Mejor récord personal • ${entrada.partidasSolitario} ${entrada.partidasSolitario == 1 ? 'partida' : 'partidas'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: esYo
            ? const Color(0xFFEFF6FF)
            : (posicion == 1 ? const Color(0xFFFFFBEB) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esYo
              ? const Color(0xFF3B82F6)
              : (posicion == 1
                  ? Colors.amber.shade300
                  : Colors.blueGrey.shade100),
          width: esYo || posicion == 1 ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$posicion',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: esPodio ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entrada.apodo}${esYo ? ' (Tú)' : ''}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: esMultijugador
                  ? const Color(0xFF059669).withValues(alpha: 0.12)
                  : const Color(0xFF2563EB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              valorPrincipal,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: esMultijugador
                    ? const Color(0xFF047857)
                    : const Color(0xFF1D4ED8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
