import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:brilliant/juego_bloc.dart';
import 'package:brilliant/juego_evento.dart';
import 'package:brilliant/juego_estado.dart';
import 'package:brilliant/nivel1_tablero.dart';
import 'package:brilliant/region.dart';

void main() {
  group('JuegoBloc Pruebas', () {
    late JuegoBloc bloc;

    final casillasInciales = Nivel1Config.casillasIniciales;

    setUp(() {
      bloc = JuegoBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('El estado inicial debe ser JuegoSinIniciar', () {
      expect(bloc.state, isA<JuegoSinIniciar>());
    });

    blocTest<JuegoBloc, JuegoEstado>(
      'IniciarConfiguracionInicial cambia el estado a JuegoEsperandoValoresIniciales',
      build: () => bloc,
      act: (bloc) => bloc.add(IniciarConfiguracionInicial(casillasInciales)),
      expect: () => [
        isA<JuegoEsperandoValoresIniciales>()
            .having((s) => s.casillasInciales.length, 'total casillas inciales', 6)
            .having((s) => s.valoresColocados, 'valores colocados (vacío al inicio)', isEmpty)
            .having((s) => s.listosParaAvanzar, 'listos', isFalse)
      ],
    );

    blocTest<JuegoBloc, JuegoEstado>(
      'AvanzarJuego sin valores iniciales bloquea y emite JuegoError temporal',
      build: () => bloc,
      seed: () => JuegoEsperandoValoresIniciales(casillasInciales: casillasInciales),
      act: (bloc) => bloc.add(AvanzarJuego()),
      expect: () => [
        isA<JuegoError>().having((s) => s.mensaje, 'mensaje', contains('Falta colocar 6 número(s)')),
        isA<JuegoEsperandoValoresIniciales>()
      ],
    );

    blocTest<JuegoBloc, JuegoEstado>(
      'ColocarValorInicial en una casilla que no es inicial emite JuegoError',
      build: () => bloc,
      seed: () => JuegoEsperandoValoresIniciales(casillasInciales: casillasInciales),
      act: (bloc) => bloc.add(ColocarValorInicial(const Coordenada(9, 9), 1)),
      expect: () => [
        isA<JuegoError>().having((s) => s.mensaje, 'mensaje', contains('Solo puedes colocar valores iniciales en las casillas inciales')),
        isA<JuegoEsperandoValoresIniciales>()
      ],
    );

    blocTest<JuegoBloc, JuegoEstado>(
      'ColocarValorInicial fuera del rango (1 al 6) emite JuegoError',
      build: () => bloc,
      seed: () => JuegoEsperandoValoresIniciales(casillasInciales: casillasInciales),
      act: (bloc) => bloc.add(ColocarValorInicial(casillasInciales[0], 7)),
      expect: () => [
        isA<JuegoError>().having((s) => s.mensaje, 'mensaje', contains('entre 1 y 6')),
        isA<JuegoEsperandoValoresIniciales>()
      ],
    );

    blocTest<JuegoBloc, JuegoEstado>(
      'ColocarValorInicial repetido reasigna el valor a la nueva coordenada eliminándolo de la anterior',
      build: () => bloc,
      seed: () => JuegoEsperandoValoresIniciales(
        casillasInciales: casillasInciales,
        valoresColocados: {casillasInciales[0]: 3},
      ),
      act: (bloc) => bloc.add(ColocarValorInicial(casillasInciales[1], 3)),
      expect: () => [
        isA<JuegoEsperandoValoresIniciales>()
            .having((s) => s.valoresColocados.containsKey(casillasInciales[0]), 'antigua eliminada', isFalse)
            .having((s) => s.valoresColocados[casillasInciales[1]], 'nueva asignada', 3)
      ],
    );

    blocTest<JuegoBloc, JuegoEstado>(
      'ColocarValorInicial válido actualiza el mapa de valores correctamente',
      build: () => bloc,
      seed: () => JuegoEsperandoValoresIniciales(casillasInciales: casillasInciales),
      act: (bloc) => bloc.add(ColocarValorInicial(casillasInciales[0], 4)),
      expect: () => [
        isA<JuegoEsperandoValoresIniciales>()
            .having((s) => s.valoresColocados.length, 'cantidad', 1)
            .having((s) => s.valoresColocados[casillasInciales[0]], 'valor asignado', 4)
            .having((s) => s.listosParaAvanzar, 'listos', isFalse)
      ],
    );

    blocTest<JuegoBloc, JuegoEstado>(
      'AvanzarJuego cuando los 6 valores YA están asignados permite transicionar a JuegoEnProgreso con dados y tablero',
      build: () => bloc,
      seed: () => JuegoEsperandoValoresIniciales(
        casillasInciales: casillasInciales,
        valoresColocados: {
          casillasInciales[0]: 1,
          casillasInciales[1]: 2,
          casillasInciales[2]: 3,
          casillasInciales[3]: 4,
          casillasInciales[4]: 5,
          casillasInciales[5]: 6,
        },
      ),
      act: (bloc) => bloc.add(AvanzarJuego()),
      expect: () => [
        isA<JuegoEnProgreso>()
            .having((s) => s.turno, 'turno inicial', 1)
            .having((s) => s.dado1 >= 1 && s.dado1 <= 6, 'dado1 en rango', isTrue)
            .having((s) => s.dado2 >= 1 && s.dado2 <= 6, 'dado2 en rango', isTrue)
            .having((s) => s.tablero.celdas[casillasInciales[0]]?.valor, 'valor casilla inicial', 1)
      ],
    );

    test('Fase 2: Seleccionar ancla ilumina posibles lugares según dados y regla de región', () {
      final tablero = Nivel1Config.crearTablero();
      // Colocamos un 3 en (1, 2) (que es casilla Azul)
      tablero.celdas[const Coordenada(1, 2)]?.valor = 3;

      final estado = JuegoEnProgreso(
        tablero: tablero,
        dado1: 3,
        dado2: 3, // Regla azul requiere que todos sean iguales, por lo que colocar un 3 en una casilla azul vecina es válido
      );

      final blocConEstado = JuegoBloc();
      blocConEstado.emit(estado);

      blocConEstado.add(SeleccionarAncla(const Coordenada(1, 2)));

      expectLater(
        blocConEstado.stream,
        emits(
          isA<JuegoEnProgreso>()
              .having((s) => s.anclaSeleccionada, 'ancla seleccionada', const Coordenada(1, 2))
              .having((s) => s.numeroAColocar, 'número a colocar', 3)
              .having((s) => s.casillasValidas, 'casillas válidas contiene vecinos azules', isNotEmpty),
        ),
      );
    });

    test('Fase 2: Colocar número en casilla válida actualiza el tablero y tira nuevos dados', () async {
      final tablero = Nivel1Config.crearTablero();
      tablero.celdas[const Coordenada(1, 2)]?.valor = 4;

      final estado = JuegoEnProgreso(
        tablero: tablero,
        dado1: 4,
        dado2: 4,
        anclaSeleccionada: const Coordenada(1, 2),
        numeroAColocar: 4,
        casillasValidas: {const Coordenada(0, 2), const Coordenada(1, 3)},
      );

      final blocConEstado = JuegoBloc();
      blocConEstado.emit(estado);

      blocConEstado.add(ColocarNumero(const Coordenada(0, 2)));

      await expectLater(
        blocConEstado.stream,
        emits(
          isA<JuegoEnProgreso>()
              .having((s) => s.turno, 'turno avanzado', 2)
              .having((s) => s.tablero.celdas[const Coordenada(0, 2)]?.valor, 'valor colocado', 4)
              .having((s) => s.anclaSeleccionada, 'ancla limpiada', isNull)
              .having((s) => s.casillasValidas, 'casillas validas reseteadas', isEmpty),
        ),
      );
    });
  });
}
