import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/pantalla_seleccion_nivel.dart';

void main() {
  group('Pantalla de Selección de Nivel', () {
    testWidgets('Muestra los 4 niveles con sus títulos y dificultades',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PantallaSeleccionNivel(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selecciona tu Tablero'), findsOneWidget);
      expect(find.text('Nivel 1'), findsOneWidget);
      expect(find.text('Nivel 2'), findsOneWidget);
      expect(find.text('Nivel 3'), findsOneWidget);
      expect(find.text('Nivel 4'), findsOneWidget);

      expect(find.text('Fácil'), findsOneWidget);
      expect(find.text('Intermedio'), findsOneWidget);
      expect(find.text('Avanzado'), findsOneWidget);
      expect(find.text('Experto'), findsOneWidget);
    });

    testWidgets('Permite seleccionar Nivel 2 y abrir la pantalla de juego del nivel 2',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PantallaSeleccionNivel(),
        ),
      );
      await tester.pumpAndSettle();

      // Tocamos el botón del nivel 2
      await tester.tap(find.byKey(const Key('boton_jugar_nivel_2')));
      await tester.pumpAndSettle();

      // Debe abrir la pantalla con el título del Nivel 2
      expect(find.text('Brilliant - Nivel 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('casilla_0_0')), findsOneWidget);

      // Tocamos volver
      await tester.tap(find.byKey(const Key('boton_volver_seleccion')));
      await tester.pumpAndSettle();

      // Debe volver al menú de selección
      expect(find.text('Selecciona tu Tablero'), findsOneWidget);
    });
  });
}
