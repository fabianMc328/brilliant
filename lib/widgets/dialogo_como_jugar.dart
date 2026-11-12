import 'package:flutter/material.dart';

import '../tipo.dart';

/// Modal interactivo y visual que explica detalladamente las reglas de cada color,
/// la mecánica de anclas y dados, y el sistema oficial de puntuación de Brilliant.
class DialogoComoJugar extends StatelessWidget {
  const DialogoComoJugar({super.key});

  static Future<void> mostrar(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DialogoComoJugar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final altura = mediaQuery.size.height * 0.82;

    return Container(
      height: altura,
      margin: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Cabecera estilizada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Cómo Jugar a Brilliant?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Reglas oficiales de colores, dados y puntos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),

            // Selector de pestañas
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.blueGrey.shade700,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
                tabs: const [
                  Tab(text: 'Colores y Reglas'),
                  Tab(text: 'Dados y Turnos'),
                  Tab(text: 'Puntos y Carrera'),
                ],
              ),
            ),

            // Contenido de las pestañas
            Expanded(
              child: TabBarView(
                children: [
                  _SeccionReglasColores(),
                  _SeccionMecanicaDados(),
                  _SeccionPuntuacion(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeccionReglasColores extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tipos = [
      _InfoTipo(
        nombre: 'Azul',
        tipo: TipoAzul(),
        ejemplo: 'Ejemplo: 4 - 4 - 4 (todos idénticos)',
      ),
      _InfoTipo(
        nombre: 'Gris',
        tipo: TipoGris(),
        ejemplo: 'Ejemplo: 2 - 2 (todos idénticos)',
      ),
      _InfoTipo(
        nombre: 'Morado',
        tipo: TipoMorado(),
        ejemplo: 'Ejemplo: 3 - 3 - 6 - 6 (máximo 2 números distintos)',
      ),
      _InfoTipo(
        nombre: 'Verde',
        tipo: TipoVerde(),
        ejemplo: 'Ejemplo: 1 - 5 - 2 - 6 (cualquier número sin restricción)',
      ),
      _InfoTipo(
        nombre: 'Amarillo',
        tipo: TipoAmarillo(),
        ejemplo: 'Ejemplo: 1 - 2 - 4 - 6 (todos diferentes)',
      ),
      _InfoTipo(
        nombre: 'Rojo',
        tipo: TipoRojo(),
        ejemplo: 'Ejemplo: 2 - 3 - 5 (todos diferentes)',
      ),
      _InfoTipo(
        nombre: 'Naranja (1 a 3)',
        tipo: TipoNaranja1a3(),
        ejemplo: 'Solo números 1, 2 o 3',
      ),
      _InfoTipo(
        nombre: 'Naranja (4 a 6)',
        tipo: TipoNaranja4a6(),
        ejemplo: 'Solo números 4, 5 o 6',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: tipos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = tipos[index];
        final pts = item.tipo.puntuaciones;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.tipo.color.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.tipo.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.tipo.reglaCorta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.nombre,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: item.tipo.color,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '1.º: +${pts[1]} | 2.º: +${pts[2]} | 3.º: +${pts[3]} pts',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.tipo.descripcion,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.ejemplo,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTipo {
  final String nombre;
  final Tipo tipo;
  final String ejemplo;

  const _InfoTipo({
    required this.nombre,
    required this.tipo,
    required this.ejemplo,
  });
}

class _SeccionMecanicaDados extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _TarjetaPaso(
          numero: '1',
          titulo: 'Estrellas Iniciales (Fase 1)',
          descripcion:
              'Al iniciar la partida, debes colocar obligatoriamente los números del 1 al 6 en las 6 casillas con estrella del mapa sin repetir ninguno. Puedes usar el botón "Llenar al azar" para colocarlos rápidamente.',
          icono: Icons.star_rounded,
          colorIcono: Colors.amber.shade700,
        ),
        const SizedBox(height: 12),
        _TarjetaPaso(
          numero: '2',
          titulo: 'Anclas y Colocación de Números (Fase 2)',
          descripcion:
              'En cada turno se tiran dos dados (por ejemplo 3 y 5). Para colocar un número, debes usar el otro dado como ancla:\n'
              '• Si colocas el 5, necesitas una casilla con 3 como ancla en tu tablero.\n'
              '• El número debe colocarse en una casilla adyacente (arriba, abajo, izquierda o derecha) que esté vacía y cumpla la regla del color de esa región.',
          icono: Icons.casino_rounded,
          colorIcono: const Color(0xFF2563EB),
        ),
        const SizedBox(height: 12),
        _TarjetaPaso(
          numero: '3',
          titulo: 'Selección Directa Tocando el Dado',
          descripcion:
              '¡Es muy fácil! Puedes tocar directamente el dado con el número que deseas colocar en la parte inferior. El tablero automáticamente iluminará en verde todas las casillas legales donde puedes ponerlo.',
          icono: Icons.touch_app_rounded,
          colorIcono: const Color(0xFF059669),
        ),
        const SizedBox(height: 12),
        _TarjetaPaso(
          numero: '4',
          titulo: 'Tirada de Dados y Turnos',
          descripcion:
              '• En Modo Solitario: una vez colocado tu número, debes presionar obligatoriamente el botón "Tirar Dados" para avanzar a la siguiente ronda.\n'
              '• En Multijugador: las rondas duran 60 segundos simultáneos. Si no tienes jugadas válidas, presiona "Pasar Turno".',
          icono: Icons.timer_rounded,
          colorIcono: const Color(0xFFD97706),
        ),
      ],
    );
  }
}

class _TarjetaPaso extends StatelessWidget {
  final String numero;
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color colorIcono;

  const _TarjetaPaso({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorIcono.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: colorIcono, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionPuntuacion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  size: 28, color: Colors.amber.shade900),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Empates simultáneos premiados!\nSi dos o más jugadores completan la misma región en el mismo turno, TODOS se llevan los puntos máximos del 1.º lugar.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Escalones de Carrera por Región',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Cada región del mapa ofrece tres niveles de puntos según quién la complete primero:',
          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
        ),
        const SizedBox(height: 10),
        _FilaEscalon(
          posicion: '1.º Lugar',
          descripcion: 'El primer jugador en completar la región se lleva la máxima puntuación.',
          color: Colors.amber.shade700,
        ),
        const SizedBox(height: 6),
        _FilaEscalon(
          posicion: '2.º Lugar',
          descripcion: 'El segundo jugador se lleva la puntuación intermedia.',
          color: Colors.blueGrey.shade600,
        ),
        const SizedBox(height: 6),
        _FilaEscalon(
          posicion: '3.º Lugar o más',
          descripcion: 'El tercer jugador y todos los siguientes se llevan la puntuación menor (nunca se agota).',
          color: const Color(0xFFB45309),
        ),
        const SizedBox(height: 16),
        const Text(
          'Metas de Victoria en Multijugador',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: const [
              _FilaMeta(jugadores: '2 Jugadores', meta: '26 Puntos'),
              Divider(height: 14),
              _FilaMeta(jugadores: '3 Jugadores', meta: '24 Puntos'),
              Divider(height: 14),
              _FilaMeta(jugadores: '4 Jugadores', meta: '22 Puntos'),
              Divider(height: 14),
              _FilaMeta(jugadores: '5 a 6 Jugadores', meta: '20 Puntos'),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaEscalon extends StatelessWidget {
  final String posicion;
  final String descripcion;
  final Color color;

  const _FilaEscalon({
    required this.posicion,
    required this.descripcion,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            posicion,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            descripcion,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.blueGrey.shade800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaMeta extends StatelessWidget {
  final String jugadores;
  final String meta;

  const _FilaMeta({required this.jugadores, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          jugadores,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        Text(
          meta,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }
}
