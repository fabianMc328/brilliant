import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:brilliant/juego_bloc.dart';
import 'package:brilliant/juego_estado.dart';
import 'package:brilliant/juego_evento.dart';
import 'package:brilliant/nivel1_tablero.dart';
import 'package:brilliant/region.dart';

// Prueba los cambios de estado del Bloc tanto al elegir estrellas como al jugar con dados.
void main() {
  group('Control del juego (JuegoBloc)', () {
    late JuegoBloc bloc;
    final casillasIniciales = Nivel1Config.casillasIniciales;

    setUp(() {
      bloc = JuegoBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('Arranca en estado JuegoSinIniciar', () {
      expect(bloc.state, isA<JuegoSinIniciar>());
    });

    group('Paso 1: Colocar las estrellas iniciales', () {
      blocTest<JuegoBloc, JuegoEstado>(
        'Inicia esperando los números para las 6 estrellas',
        build: () => bloc,
        act: (b) => b.add(IniciarConfiguracionInicial(casillasIniciales)),
        expect: () => [
          isA<JuegoEsperandoValoresIniciales>()
              .having((s) => s.valoresColocados, 'vacio al inicio', isEmpty)
              .having((s) => s.listosParaAvanzar, 'no listo', isFalse),
        ],
      );

      blocTest<JuegoBloc, JuegoEstado>(
        'Guarda el número cuando se toca una estrella válida',
        build: () => bloc,
        seed: () => JuegoEsperandoValoresIniciales(casillasInciales: casillasIniciales),
        act: (b) => b.add(ColocarValorInicial(casillasIniciales[0], 5)),
        expect: () => [
          isA<JuegoEsperandoValoresIniciales>()
              .having((s) => s.valoresColocados[casillasIniciales[0]], 'guarda el 5', 5),
        ],
      );

      blocTest<JuegoBloc, JuegoEstado>(
        'Manda error si se toca una casilla sin estrella',
        build: () => bloc,
        seed: () => JuegoEsperandoValoresIniciales(casillasInciales: casillasIniciales),
        act: (b) => b.add(ColocarValorInicial(const Coordenada(0, 0), 1)),
        expect: () => [
          isA<JuegoError>(),
          isA<JuegoEsperandoValoresIniciales>(),
        ],
      );

      blocTest<JuegoBloc, JuegoEstado>(
        'Manda error si el número no está entre 1 y 6',
        build: () => bloc,
        seed: () => JuegoEsperandoValoresIniciales(casillasInciales: casillasIniciales),
        act: (b) => b.add(ColocarValorInicial(casillasIniciales[0], 9)),
        expect: () => [
          isA<JuegoError>(),
          isA<JuegoEsperandoValoresIniciales>(),
        ],
      );

      blocTest<JuegoBloc, JuegoEstado>(
        'Mueve el número a la nueva casilla si se repite',
        build: () => bloc,
        seed: () => JuegoEsperandoValoresIniciales(
          casillasInciales: casillasIniciales,
          valoresColocados: {casillasIniciales[0]: 3},
        ),
        act: (b) => b.add(ColocarValorInicial(casillasIniciales[1], 3)),
        expect: () => [
          isA<JuegoEsperandoValoresIniciales>()
              .having((s) => s.valoresColocados.containsKey(casillasIniciales[0]), 'borra de la vieja', isFalse)
              .having((s) => s.valoresColocados[casillasIniciales[1]], 'pone en la nueva', 3),
        ],
      );

      blocTest<JuegoBloc, JuegoEstado>(
        'Limpia todas las casillas',
        build: () => bloc,
        seed: () => JuegoEsperandoValoresIniciales(
          casillasInciales: casillasIniciales,
          valoresColocados: {casillasIniciales[0]: 1, casillasIniciales[1]: 2},
        ),
        act: (b) => b.add(LimpiarValoresIniciales()),
        expect: () => [
          isA<JuegoEsperandoValoresIniciales>()
              .having((s) => s.valoresColocados, 'queda vacio', isEmpty),
        ],
      );

      blocTest<JuegoBloc, JuegoEstado>(
        'Llena las 6 casillas al azar del 1 al 6',
        build: () => JuegoBloc(random: Random(1234)),
        seed: () => JuegoEsperandoValoresIniciales(casillasInciales: casillasIniciales),
        act: (b) => b.add(LlenarValoresAleatorios()),
        expect: () => [
          isA<JuegoEsperandoValoresIniciales>()
              .having((s) => s.valoresColocados.length, 'llena 6 casillas', 6)
              .having((s) => s.listosParaAvanzar, 'habilita comenzar', isTrue),
        ],
      );

      blocTest<JuegoBloc, JuegoEstado>(
        'No deja empezar si faltan casillas por llenar',
        build: () => bloc,
        seed: () => JuegoEsperandoValoresIniciales(
          casillasInciales: casillasIniciales,
          valoresColocados: {casillasIniciales[0]: 1},
        ),
        act: (b) => b.add(AvanzarJuego()),
        expect: () => [
          isA<JuegoError>(),
          isA<JuegoEsperandoValoresIniciales>(),
        ],
      );

      blocTest<JuegoBloc, JuegoEstado>(
        'Comienza el nivel cuando las 6 estrellas tienen número',
        build: () => JuegoBloc(random: Random(99)),
        seed: () => JuegoEsperandoValoresIniciales(
          casillasInciales: casillasIniciales,
          valoresColocados: {
            casillasIniciales[0]: 1,
            casillasIniciales[1]: 2,
            casillasIniciales[2]: 3,
            casillasIniciales[3]: 4,
            casillasIniciales[4]: 5,
            casillasIniciales[5]: 6,
          },
        ),
        act: (b) => b.add(AvanzarJuego()),
        expect: () => [
          isA<JuegoEnProgreso>()
              .having((s) => s.turno, 'inicia turno 1', 1)
              .having((s) => s.tablero.celdas[casillasIniciales[0]]?.valor, 'valor en casilla', 1),
        ],
      );
    });

    group('Paso 2: Dados, anclas y turnos', () {
      test('Avisa si tocas una casilla vacía para ancla', () {
        final tablero = Nivel1Config.crearTablero();
        final estado = JuegoEnProgreso(tablero: tablero, dado1: 2, dado2: 4);

        final blocTest = JuegoBloc();
        blocTest.emit(estado);

        blocTest.add(SeleccionarAncla(const Coordenada(0, 0)));

        expectLater(
          blocTest.stream,
          emits(isA<JuegoEnProgreso>().having((s) => s.mensajeFeedback, 'aviso', isNotNull)),
        );
      });

      test('Avisa si el ancla no coincide con ninguno de los dados', () {
        final tablero = Nivel1Config.crearTablero();
        tablero.celdas[const Coordenada(1, 2)]?.valor = 5;

        final estado = JuegoEnProgreso(tablero: tablero, dado1: 1, dado2: 2);

        final blocTest = JuegoBloc();
        blocTest.emit(estado);

        blocTest.add(SeleccionarAncla(const Coordenada(1, 2)));

        expectLater(
          blocTest.stream,
          emits(isA<JuegoEnProgreso>().having((s) => s.mensajeFeedback, 'aviso', isNotNull)),
        );
      });

      test('Desmarca el ancla seleccionada', () {
        final tablero = Nivel1Config.crearTablero();
        final estado = JuegoEnProgreso(
          tablero: tablero,
          dado1: 3,
          dado2: 4,
          anclaSeleccionada: const Coordenada(1, 2),
          numeroAColocar: 4,
          casillasValidas: {const Coordenada(0, 2)},
        );

        final blocTest = JuegoBloc();
        blocTest.emit(estado);

        blocTest.add(DeseleccionarAncla());

        expectLater(
          blocTest.stream,
          emits(
            isA<JuegoEnProgreso>()
                .having((s) => s.anclaSeleccionada, 'ancla quitada', isNull)
                .having((s) => s.casillasValidas, 'sin casillas verdes', isEmpty),
          ),
        );
      });

      test('Pasar turno avanza la ronda y tira nuevos dados', () {
        final tablero = Nivel1Config.crearTablero();
        final estado = JuegoEnProgreso(tablero: tablero, dado1: 1, dado2: 2, turno: 2);

        final blocTest = JuegoBloc();
        blocTest.emit(estado);

        blocTest.add(PasarTurno());

        expectLater(
          blocTest.stream,
          emits(isA<JuegoEnProgreso>().having((s) => s.turno, 'turno 3', 3)),
        );
      });

      test('Poner un número puede completar una región y sumar puntos', () async {
        final tablero = Nivel1Config.crearTablero();
        final regionAzul1 = tablero.regiones.firstWhere((r) => r.id == 'azul_1');

        for (final c in regionAzul1.coordenadas.take(3)) {
          tablero.celdas[c]?.valor = 5;
        }
        final ultimaCoord = regionAzul1.coordenadas.last;

        final estado = JuegoEnProgreso(
          tablero: tablero,
          dado1: 5,
          dado2: 5,
          anclaSeleccionada: regionAzul1.coordenadas.first,
          numeroAColocar: 5,
          casillasValidas: {ultimaCoord},
        );

        final blocTest = JuegoBloc();
        blocTest.emit(estado);

        blocTest.add(ColocarNumero(ultimaCoord));

        await expectLater(
          blocTest.stream,
          emits(
            isA<JuegoEnProgreso>()
                .having((s) => s.puntuacionTotal, 'da 7 puntos', 7)
                .having((s) => s.regionesCompletadasIds, 'completa azul 1', contains('azul_1')),
          ),
        );
      });
    });
  });
}
