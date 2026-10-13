import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/main.dart';

// Prueba la pantalla del juego completa, los botones y el paso de fase 1 a fase 2.
void main() {
  group('Pantalla Principal del Juego', () {
    testWidgets('Carga la pantalla con sus botones y las 49 casillas', (tester) async {
      await tester.pumpWidget(const AplicacionBrilliant());
      await tester.pumpAndSettle();

      expect(find.text('Brilliant - Nivel 1'), findsOneWidget);
      expect(find.byKey(const Key('boton_limpiar')), findsOneWidget);
      expect(find.byKey(const Key('boton_aleatorio')), findsOneWidget);
      expect(find.byKey(const Key('boton_comenzar_nivel')), findsOneWidget);
      expect(find.byKey(const ValueKey('casilla_0_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('casilla_6_6')), findsOneWidget);
    });

    testWidgets('Llenar aleatorio y comenzar nivel pasa a la fase de dados', (tester) async {
      await tester.pumpWidget(const AplicacionBrilliant());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_aleatorio')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_comenzar_nivel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dado_1')), findsOneWidget);
      expect(find.byKey(const Key('dado_2')), findsOneWidget);
      expect(find.byKey(const Key('texto_puntuacion_total')), findsOneWidget);
      expect(find.byKey(const Key('texto_turno')), findsOneWidget);
    });
  });
}
