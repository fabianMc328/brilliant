import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/casilla_juego.dart';

// Prueba que la casilla cuadrada pinte su número o el preview verde.
void main() {
  group('Widget Casilla', () {
    testWidgets('Muestra el número centrado', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CasillaJuego(
                  colorBase: Colors.blue,
                  valor: 4,
                  estado: EstadoCasilla.usado,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('Ilumina casilla válida sin mostrar número flotante', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CasillaJuego(
                  colorBase: Colors.green,
                  esLugarValido: true,
                  valorPreview: 2,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('2'), findsNothing);
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('Muestra puntito indicador de ancla elegible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CasillaJuego(
                  colorBase: Colors.purple,
                  esAnclaElegible: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('La casilla vacía se mantiene limpia sin texto de reglas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: CasillaJuego(
                  colorBase: Colors.orange,
                  estado: EstadoCasilla.sinUsar,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);
    });
  });
}
