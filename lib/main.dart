import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pantalla_seleccion_nivel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AplicacionBrilliant());
}

class AplicacionBrilliant extends StatelessWidget {
  final Widget? pantallaInicial;

  const AplicacionBrilliant({super.key, this.pantallaInicial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brilliant',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: pantallaInicial ?? const PantallaSeleccionNivel(),
    );
  }
}
