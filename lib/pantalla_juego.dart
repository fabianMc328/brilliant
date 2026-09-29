import 'package:flutter/material.dart';
import 'casilla_juego.dart';
import 'tipo.dart';
import 'region.dart';

class PantallaJuego extends StatefulWidget {
  const PantallaJuego({super.key});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  late List<List<Color>> coloresTablero;
  
  // Coordenadas (fila, columna) de las 6 estrellas iniciales
  final List<Coordenada> casillasIniciales = [
    const Coordenada(1, 2), // Azul
    const Coordenada(1, 5), // Morado
    const Coordenada(3, 1), // Rojo
    const Coordenada(3, 4), // Verde
    const Coordenada(5, 2), // Morado
    const Coordenada(6, 4), // Rojo
  ];

  // Mapa temporal para guardar los números que pongamos en la UI
  Map<Coordenada, int> valores = {};

  @override
  void initState() {
    super.initState();
    final colorAmarillo = TipoAmarillo().color;
    final colorVerde = TipoVerde().color;
    final colorAzul = TipoAzul().color;
    final colorMorado = TipoMorado().color;
    final colorRojo = TipoRojo().color;

    // Mapa de colores basado en el Nivel 1 del juego físico
    coloresTablero = [
      [colorAmarillo, colorVerde, colorAzul, colorMorado, colorMorado, colorMorado, colorAmarillo],
      [colorVerde, colorVerde, colorAzul, colorAzul, colorMorado, colorMorado, colorVerde],
      [colorVerde, colorRojo, colorRojo, colorAzul, colorMorado, colorVerde, colorVerde],
      [colorVerde, colorRojo, colorMorado, colorAmarillo, colorVerde, colorVerde, colorVerde],
      [colorVerde, colorRojo, colorMorado, colorMorado, colorRojo, colorRojo, colorAzul],
      [colorRojo, colorRojo, colorMorado, colorRojo, colorRojo, colorAzul, colorAzul],
      [colorAmarillo, colorMorado, colorMorado, colorRojo, colorRojo, colorAzul, colorAmarillo],
    ];
  }

  void _alTocarCasilla(Coordenada coord) {
    if (casillasIniciales.contains(coord)) {
      setState(() {
        // Simulamos la inserción de números ciclando del 1 al 6 para probar la UI
        int valorActual = valores[coord] ?? 0;
        if (valorActual >= 6) {
          valores.remove(coord);
        } else {
          valores[coord] = valorActual + 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brilliant - Nivel 1'),
        centerTitle: true,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, // 7 columnas
                crossAxisSpacing: 6.0,
                mainAxisSpacing: 6.0,
              ),
              itemCount: 49, // 7x7 casillas
              itemBuilder: (context, index) {
                final fila = index ~/ 7;
                final columna = index % 7;
                final coord = Coordenada(fila, columna);
                final esInicial = casillasIniciales.contains(coord);
                final valor = valores[coord];

                // Dibujar una estrella si es casilla inicial y no tiene valor aún
                Widget? contenido;
                if (esInicial && valor == null) {
                  contenido = const Icon(
                    Icons.star_rounded, 
                    color: Colors.white70, 
                    size: 28
                  );
                }

                return GestureDetector(
                  onTap: esInicial ? () => _alTocarCasilla(coord) : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CasillaJuego(
                          colorBase: coloresTablero[fila][columna],
                          estado: valor != null 
                              ? EstadoCasilla.usado 
                              : EstadoCasilla.sinUsar,
                          valor: valor,
                        ),
                      ),
                      if (contenido != null) contenido,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
