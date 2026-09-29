import 'package:flutter/material.dart';
import 'pantalla_juego.dart';

void main() {
  runApp(const AplicacionBrilliant());
}

class AplicacionBrilliant extends StatelessWidget {
  const AplicacionBrilliant({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brilliant',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const PantallaJuego(),
    );
  }
}
