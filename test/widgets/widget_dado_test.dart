import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/widget_dado.dart';

// Prueba que el dado dibuje bien sus puntos del 1 al 6 y responda al toque.
void main() {
  group('Widget Dado', () {
    testWidgets('Dibuja los puntos del 1 al 6 sin romperse', (tester) async {
      for (int valor = 1; valor <= 6; valor++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: WidgetDado(valor: valor),
              ),
            ),
          ),
        );

        expect(find.byType(WidgetDado), findsOneWidget);
      }
    });

    testWidgets('Detecta cuando lo tocas', (tester) async {
      bool tocado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WidgetDado(
                valor: 3,
                esNumeroAColocar: true,
                onTap: () => tocado = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(WidgetDado));
      expect(tocado, isTrue);
    });
  });
}
