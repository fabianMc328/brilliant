import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/juego_estado.dart';
import 'package:brilliant/nivel1_tablero.dart';
import 'package:brilliant/widgets/banner_instruccion.dart';
import 'package:brilliant/widgets/panel_dados.dart';
import 'package:brilliant/widgets/panel_puntuacion.dart';
import 'package:brilliant/widgets/selector_valor_inicial_sheet.dart';

// Prueba los paneles de dados, puntos, mensajes y el menú de números del 1 al 6.
void main() {
  group('Paneles y menú de números', () {
    testWidgets('Muestra el banner de instrucciones', (tester) async {
      final tablero = Nivel1Config.crearTablero();
      final estado = JuegoEnProgreso(tablero: tablero, dado1: 3, dado2: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerInstruccion(state: estado),
          ),
        ),
      );

      expect(find.byKey(const Key('banner_instruccion')), findsOneWidget);
    });

    testWidgets('Muestra los puntos acumulados y el número de turno', (tester) async {
      final tablero = Nivel1Config.crearTablero();
      final estado = JuegoEnProgreso(
        tablero: tablero,
        dado1: 1,
        dado2: 2,
        puntuacionTotal: 25,
        turno: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelPuntuacion(state: estado),
          ),
        ),
      );

      final textoPuntos = tester.widget<Text>(find.byKey(const Key('texto_puntuacion_total')));
      final textoTurno = tester.widget<Text>(find.byKey(const Key('texto_turno')));

      expect(textoPuntos.data, '25 pts');
      expect(textoTurno.data, 'Turno 5');
    });

    testWidgets('Funciona el botón de tirar dados y el de pasar turno', (tester) async {
      final tablero = Nivel1Config.crearTablero();
      bool tirarDadosLlamado = false;
      bool pasarTurnoLlamado = false;

      final estadoConJugadas = JuegoEnProgreso(
        tablero: tablero,
        dado1: 1,
        dado2: 2,
        hayJugadasDisponibles: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelDados(
              state: estadoConJugadas,
              onTirarDados: () => tirarDadosLlamado = true,
              onCancelarAncla: () {},
              onPasarTurno: () => pasarTurnoLlamado = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('dado_1')), findsOneWidget);
      expect(find.byKey(const Key('dado_2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('boton_tirar_dados')));
      expect(tirarDadosLlamado, isTrue);

      final estadoSinJugadas = JuegoEnProgreso(
        tablero: tablero,
        dado1: 1,
        dado2: 2,
        hayJugadasDisponibles: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelDados(
              state: estadoSinJugadas,
              onTirarDados: () {},
              onCancelarAncla: () {},
              onPasarTurno: () => pasarTurnoLlamado = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('boton_pasar_turno')));
      expect(pasarTurnoLlamado, isTrue);
    });

    testWidgets('El menú muestra los números del 1 al 6 y responde al tocarlos', (tester) async {
      int? seleccionado;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectorValorInicialSheet(
              valorActual: null,
              onNumeroSeleccionado: (num) => seleccionado = num,
            ),
          ),
        ),
      );

      for (int i = 1; i <= 6; i++) {
        expect(find.byKey(ValueKey('opcion_numero_$i')), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('opcion_numero_5')));
      expect(seleccionado, 5);
    });
  });
}
