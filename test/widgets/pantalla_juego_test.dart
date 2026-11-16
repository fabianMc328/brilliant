import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/juego_bloc.dart';
import 'package:brilliant/pantalla_juego.dart';

// Prueba la pantalla del juego completa, los botones y el paso de fase 1 a fase 2.
void main() {
  group('Pantalla Principal del Juego', () {
    testWidgets('Carga la pantalla con sus botones y las 49 casillas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => JuegoBloc(),
            child: const PantallaJuego(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Brilliant - Nivel 1'), findsOneWidget);
      expect(find.byKey(const Key('boton_limpiar')), findsOneWidget);
      expect(find.byKey(const Key('boton_aleatorio')), findsOneWidget);
      expect(find.byKey(const Key('boton_comenzar_nivel')), findsOneWidget);
      expect(find.byKey(const ValueKey('casilla_0_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('casilla_6_6')), findsOneWidget);
    });

    testWidgets('Llenar aleatorio y comenzar nivel pasa a la fase de dados', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => JuegoBloc(),
            child: const PantallaJuego(),
          ),
        ),
      );
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

    testWidgets(
      'Botón atrás en partida solitario pide confirmación para finalizar',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  key: const Key('abrir_juego_solitario'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => JuegoBloc(),
                          child: const PantallaJuego(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('abrir_juego_solitario')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('boton_aleatorio')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('boton_comenzar_nivel')));
        await tester.pumpAndSettle();

        // Pulsamos la flecha atrás durante una partida activa
        await tester.tap(find.byKey(const Key('boton_volver_seleccion')));
        await tester.pumpAndSettle();

        expect(find.text('¿Finalizar partida?'), findsOneWidget);

        // Cancelar mantiene la partida abierta
        await tester.tap(find.text('Seguir jugando'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dado_1')), findsOneWidget);

        // Confirmar cierra la partida y regresa
        await tester.tap(find.byKey(const Key('boton_volver_seleccion')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Finalizar partida'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('abrir_juego_solitario')), findsOneWidget);
      },
    );
  });
}
