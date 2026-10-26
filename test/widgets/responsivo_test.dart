import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/juego_bloc.dart';
import 'package:brilliant/juego_evento.dart';
import 'package:brilliant/pantalla_juego.dart';
import 'package:brilliant/pantalla_seleccion_nivel.dart';

void main() {
  final dimensionesMovil = [
    const Size(320, 480), // Pantallas ultra compactas
    const Size(360, 640), // Android compacto / presupuesto
    const Size(375, 667), // iPhone SE / 8
    const Size(390, 844), // iPhone 12 / 13 / 14
    const Size(412, 915), // Pixel 7 / Galaxy S23
  ];

  for (final dim in dimensionesMovil) {
    testWidgets('Responsividad en pantalla ${dim.width}x${dim.height}', (tester) async {
      tester.view.physicalSize = dim;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Probar PantallaSeleccionNivel
      await tester.pumpWidget(
        const MaterialApp(
          home: PantallaSeleccionNivel(),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Probar PantallaJuego en Fase 1
      final bloc = JuegoBloc();
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const PantallaJuego(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Probar PantallaJuego en Fase 2
      bloc.add(LlenarValoresAleatorios());
      await tester.pumpAndSettle();
      bloc.add(AvanzarJuego());
      await tester.pumpAndSettle();

      // Verificar que los dados y puntuación están visibles
      expect(find.byKey(const Key('dado_1')), findsOneWidget);
      expect(find.byKey(const Key('texto_puntuacion_total')), findsOneWidget);
    });
  }
}
