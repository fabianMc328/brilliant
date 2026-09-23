import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:brilliant/juego_bloc.dart';
import 'package:brilliant/juego_evento.dart';
import 'package:brilliant/juego_estado.dart';
import 'package:brilliant/region.dart';

void main() {
  group('JuegoBloc Pruebas', () {
    late JuegoBloc bloc;

    final casillasInciales = [
      const Coordenada(0, 0),
      const Coordenada(1, 1),
      const Coordenada(2, 2),
      const Coordenada(3, 3),
      const Coordenada(4, 4),
      const Coordenada(5, 5),
    ];

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
      'ColocarValorInicial repetido en otra casilla emite JuegoError',
      build: () => bloc,
      seed: () => JuegoEsperandoValoresIniciales(
        casillasInciales: casillasInciales,
        valoresColocados: {casillasInciales[0]: 3},
      ),
      act: (bloc) => bloc.add(ColocarValorInicial(casillasInciales[1], 3)),
      expect: () => [
        isA<JuegoError>().having((s) => s.mensaje, 'mensaje', contains('ya fue colocado')),
        isA<JuegoEsperandoValoresIniciales>()
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
            .having((s) => s.valoresColocados[casillasInciales[0]], 'valor asginado', 4)
            .having((s) => s.listosParaAvanzar, 'listos', isFalse)
      ],
    );

    blocTest<JuegoBloc, JuegoEstado>(
      'AvanzarJuego cuando los 6 valores YA están asignados permite transicionar a JuegoEnProgreso',
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
      ],
    );
  });
}
