import 'package:flutter/material.dart';

import 'casilla_juego.dart';

void main() {
  runApp(const AplicacionBrilliant());
}

class AplicacionBrilliant extends StatelessWidget {
  const AplicacionBrilliant({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Boceto de Casilla - Brilliant',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const PantallaPruebaCasilla(),
    );
  }
}

class PantallaPruebaCasilla extends StatelessWidget {
  const PantallaPruebaCasilla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boceto de Casilla - Brilliant'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Estados: Ligero (sin usar), Medio (usado), Fuerte (puntuado)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  SizedBox(
                    width: 80,
                    child: CasillaJuego(
                      colorBase: Color(0xFF29B6F6),
                      estado: EstadoCasilla.sinUsar,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: CasillaJuego(
                      colorBase: Color(0xFF29B6F6),
                      estado: EstadoCasilla.usado,
                      valor: 5,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: CasillaJuego(
                      colorBase: Color(0xFF29B6F6),
                      estado: EstadoCasilla.puntuado,
                      valor: 5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 130,
                child: CasillaJuego(
                  colorBase: Color(0xFFAB47BC),
                  estado: EstadoCasilla.usado,
                  valor: 7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
