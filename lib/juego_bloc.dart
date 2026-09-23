import 'package:flutter_bloc/flutter_bloc.dart';

import 'juego_evento.dart';
import 'juego_estado.dart';
import 'region.dart';

class JuegoBloc extends Bloc<JuegoEvento, JuegoEstado> {
  JuegoBloc() : super(JuegoSinIniciar()) {
    on<IniciarConfiguracionInicial>(_onIniciarConfiguracion);
    on<ColocarValorInicial>(_onColocarValorInicial);
    on<AvanzarJuego>(_onAvanzarJuego);
  }

  void _onIniciarConfiguracion(
    IniciarConfiguracionInicial event,
    Emitter<JuegoEstado> emit,
  ) {
    emit(JuegoEsperandoValoresIniciales(
      casillasInciales: event.casillasInciales,
      valoresColocados: const {},
    ));
  }

  void _onColocarValorInicial(
    ColocarValorInicial event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEsperandoValoresIniciales) {
      final estadoActual = state as JuegoEsperandoValoresIniciales;

      // 1. Validar que la coordenada enviada es una de las casillas inciales
      if (!estadoActual.casillasInciales.contains(event.coordenada)) {
        emit(JuegoError("Solo puedes colocar valores iniciales en las casillas inciales.", estadoActual));
        emit(estadoActual); // Regresar al estado anterior
        return;
      }

      // 2. Validar que el valor esté entre 1 y 6
      if (event.valor < 1 || event.valor > 6) {
        emit(JuegoError("El valor inicial debe estar entre 1 y 6.", estadoActual));
        emit(estadoActual);
        return;
      }

      // 3. Validar que el número no se haya usado ya en otra casilla
      if (estadoActual.valoresColocados.containsValue(event.valor)) {
        // Permitimos reasignar la misma coordenada
        final coordenadaExistente = estadoActual.valoresColocados.entries
            .firstWhere((e) => e.value == event.valor)
            .key;
            
        if (coordenadaExistente != event.coordenada) {
          emit(JuegoError("El número ${event.valor} ya fue colocado en otra casilla.", estadoActual));
          emit(estadoActual);
          return;
        }
      }

      // 4. Todo es válido, actualizamos el mapa
      final nuevosValores = Map<Coordenada, int>.from(estadoActual.valoresColocados);
      nuevosValores[event.coordenada] = event.valor;

      emit(estadoActual.copiarCon(valoresColocados: nuevosValores));
    }
  }

  void _onAvanzarJuego(
    AvanzarJuego event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEsperandoValoresIniciales) {
      final estadoActual = state as JuegoEsperandoValoresIniciales;

      // REGLA: No permitir avanzar hasta tener todos los valores (los 6) asignados
      if (estadoActual.listosParaAvanzar) {
        // ¡Las 6 casillas inciales ya tienen número! 
        emit(JuegoEnProgreso());
      } else {
        // Aún faltan casillas por llenar
        final faltantes = estadoActual.casillasInciales.length - estadoActual.valoresColocados.length;
        emit(JuegoError(
            "Falta colocar $faltantes número(s) en las casillas inciales para poder empezar.", 
            estadoActual));
        emit(estadoActual);
      }
    } else if (state is JuegoEnProgreso) {
      // Lógica de avance normal del juego
    }
  }
}
