import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'juego_evento.dart';
import 'juego_estado.dart';
import 'nivel1_tablero.dart';
import 'region.dart';
import 'tablero.dart';

class JuegoBloc extends Bloc<JuegoEvento, JuegoEstado> {
  final Random _random;

  JuegoBloc({Random? random})
      : _random = random ?? Random(),
        super(JuegoSinIniciar()) {
    on<IniciarConfiguracionInicial>(_onIniciarConfiguracion);
    on<ColocarValorInicial>(_onColocarValorInicial);
    on<LlenarValoresAleatorios>(_onLlenarValoresAleatorios);
    on<LimpiarValoresIniciales>(_onLimpiarValoresIniciales);
    on<AvanzarJuego>(_onAvanzarJuego);
    on<TirarDados>(_onTirarDados);
    on<SeleccionarAncla>(_onSeleccionarAncla);
    on<ColocarNumero>(_onColocarNumero);
    on<DeseleccionarAncla>(_onDeseleccionarAncla);
    on<PasarTurno>(_onPasarTurno);
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
        emit(estadoActual);
        return;
      }

      // 2. Validar que el valor esté entre 1 y 6
      if (event.valor < 1 || event.valor > 6) {
        emit(JuegoError("El valor inicial debe estar entre 1 y 6.", estadoActual));
        emit(estadoActual);
        return;
      }

      // 3. Si el número ya fue usado en otra coordenada, lo quitamos de esa coordenada antigua
      final nuevosValores = Map<Coordenada, int>.from(estadoActual.valoresColocados);
      
      if (nuevosValores.containsValue(event.valor)) {
        final coordenadaExistente = nuevosValores.entries
            .firstWhere((e) => e.value == event.valor)
            .key;
        nuevosValores.remove(coordenadaExistente);
      }

      // 4. Todo es válido, asignamos a la nueva coordenada
      nuevosValores[event.coordenada] = event.valor;

      emit(estadoActual.copiarCon(valoresColocados: nuevosValores));
    }
  }

  void _onLlenarValoresAleatorios(
    LlenarValoresAleatorios event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEsperandoValoresIniciales) {
      final estadoActual = state as JuegoEsperandoValoresIniciales;
      
      final numeros = [1, 2, 3, 4, 5, 6];
      numeros.shuffle(_random);
      
      final nuevosValores = <Coordenada, int>{};
      for (int i = 0; i < estadoActual.casillasInciales.length; i++) {
        nuevosValores[estadoActual.casillasInciales[i]] = numeros[i];
      }
      
      emit(estadoActual.copiarCon(valoresColocados: nuevosValores));
    }
  }

  void _onLimpiarValoresIniciales(
    LimpiarValoresIniciales event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEsperandoValoresIniciales) {
      final estadoActual = state as JuegoEsperandoValoresIniciales;
      emit(estadoActual.copiarCon(valoresColocados: const {}));
    }
  }

  void _onAvanzarJuego(
    AvanzarJuego event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEsperandoValoresIniciales) {
      final estadoActual = state as JuegoEsperandoValoresIniciales;

      // Regla: Se deben haber colocado las 6 casillas iniciales
      if (!estadoActual.listosParaAvanzar) {
        final faltantes = estadoActual.casillasInciales.length - estadoActual.valoresColocados.length;
        emit(JuegoError(
            "Falta colocar $faltantes número(s) en las casillas inciales para poder empezar.", 
            estadoActual));
        emit(estadoActual);
        return;
      }

      // Inicializamos el Tablero de Nivel 1 con sus regiones y celdas
      final tablero = Nivel1Config.crearTablero();

      // Inyectamos los 6 valores iniciales en las celdas
      for (final entry in estadoActual.valoresColocados.entries) {
        final celda = tablero.celdas[entry.key];
        if (celda != null) {
          celda.valor = entry.value;
        }
      }

      // Tiramos los primeros dos dados
      final d1 = _random.nextInt(6) + 1;
      final d2 = _random.nextInt(6) + 1;
      final hayJugadas = _hayJugadasPosibles(tablero, d1, d2);

      emit(JuegoEnProgreso(
        tablero: tablero,
        dado1: d1,
        dado2: d2,
        hayJugadasDisponibles: hayJugadas,
        turno: 1,
        puntuacionTotal: 0,
        regionesCompletadasIds: const [],
        desglosePuntos: const {},
      ));
    }
  }

  void _onTirarDados(
    TirarDados event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEnProgreso) {
      final actual = state as JuegoEnProgreso;
      final d1 = _random.nextInt(6) + 1;
      final d2 = _random.nextInt(6) + 1;
      final hayJugadas = _hayJugadasPosibles(actual.tablero, d1, d2);

      emit(actual.copiarCon(
        dado1: d1,
        dado2: d2,
        limpiarAncla: true,
        limpiarNumeroAColocar: true,
        casillasValidas: {},
        hayJugadasDisponibles: hayJugadas,
        limpiarFeedback: true,
      ));
    }
  }

  void _onSeleccionarAncla(
    SeleccionarAncla event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEnProgreso) {
      final actual = state as JuegoEnProgreso;
      final celda = actual.tablero.celdas[event.coordenada];

      if (celda == null || celda.estaVacia) {
        emit(actual.copiarCon(
          mensajeFeedback: 'Debes seleccionar una casilla ocupada como ancla.',
        ));
        return;
      }

      final valorAncla = celda.valor!;

      // Validar si el ancla coincide con dado1 o dado2
      if (valorAncla != actual.dado1 && valorAncla != actual.dado2) {
        emit(actual.copiarCon(
          mensajeFeedback: 'El ancla seleccionada ($valorAncla) no coincide con los dados (${actual.dado1} o ${actual.dado2}).',
        ));
        return;
      }

      // Si el ancla coincide con dado1, el número a colocar es dado2; si coincide con dado2, es dado1
      final int numeroAColocar;
      if (valorAncla == actual.dado1) {
        numeroAColocar = actual.dado2;
      } else {
        numeroAColocar = actual.dado1;
      }

      // Buscamos los lugares ortogonales válidos donde se puede colocar el número
      final validas = actual.tablero.obtenerPosiblesLugaresParaAncla(event.coordenada, numeroAColocar);

      String? feedback;
      if (validas.isEmpty) {
        feedback = 'No hay casillas válidas para colocar el $numeroAColocar junto a esta ancla.';
      } else {
        feedback = 'Colocando el $numeroAColocar. Selecciona una casilla iluminada.';
      }

      emit(actual.copiarCon(
        anclaSeleccionada: event.coordenada,
        numeroAColocar: numeroAColocar,
        casillasValidas: validas,
        mensajeFeedback: feedback,
      ));
    }
  }

  void _onColocarNumero(
    ColocarNumero event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEnProgreso) {
      final actual = state as JuegoEnProgreso;

      if (actual.numeroAColocar == null || !actual.casillasValidas.contains(event.coordenada)) {
        emit(actual.copiarCon(
          mensajeFeedback: 'Selecciona una de las casillas iluminadas válidas.',
        ));
        return;
      }

      // Colocamos el número en el tablero
      final colocado = actual.tablero.colocarNumero(event.coordenada, actual.numeroAColocar!);
      if (!colocado) {
        emit(actual.copiarCon(
          mensajeFeedback: 'No se pudo colocar el número en esa casilla.',
        ));
        return;
      }

      // Verificamos si alguna región se acaba de completar
      final completadas = List<String>.from(actual.regionesCompletadasIds);
      String? avisoCompletada;

      for (final region in actual.tablero.regiones) {
        if (!completadas.contains(region.id) && actual.tablero.esRegionCompleta(region)) {
          completadas.add(region.id);
          avisoCompletada = '¡Región completada con éxito! 🎉';
        }
      }

      // Recalcular puntuación
      final nuevaPuntuacion = actual.tablero.calcularPuntuacionTotal(completadas);
      final nuevoDesglose = actual.tablero.calcularDesglosePuntos(completadas);

      // Tiramos automáticamente los dados para el siguiente turno
      final nuevoD1 = _random.nextInt(6) + 1;
      final nuevoD2 = _random.nextInt(6) + 1;
      final hayJugadas = _hayJugadasPosibles(actual.tablero, nuevoD1, nuevoD2);

      emit(actual.copiarCon(
        turno: actual.turno + 1,
        dado1: nuevoD1,
        dado2: nuevoD2,
        limpiarAncla: true,
        limpiarNumeroAColocar: true,
        casillasValidas: {},
        puntuacionTotal: nuevaPuntuacion,
        regionesCompletadasIds: completadas,
        desglosePuntos: nuevoDesglose,
        hayJugadasDisponibles: hayJugadas,
        mensajeFeedback: avisoCompletada ?? '¡Número colocado! Nuevos dados tirados.',
      ));
    }
  }

  void _onDeseleccionarAncla(
    DeseleccionarAncla event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEnProgreso) {
      final actual = state as JuegoEnProgreso;
      emit(actual.copiarCon(
        limpiarAncla: true,
        limpiarNumeroAColocar: true,
        casillasValidas: {},
        limpiarFeedback: true,
      ));
    }
  }

  void _onPasarTurno(
    PasarTurno event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEnProgreso) {
      final actual = state as JuegoEnProgreso;
      final nuevoD1 = _random.nextInt(6) + 1;
      final nuevoD2 = _random.nextInt(6) + 1;
      final hayJugadas = _hayJugadasPosibles(actual.tablero, nuevoD1, nuevoD2);

      emit(actual.copiarCon(
        turno: actual.turno + 1,
        dado1: nuevoD1,
        dado2: nuevoD2,
        limpiarAncla: true,
        limpiarNumeroAColocar: true,
        casillasValidas: {},
        hayJugadasDisponibles: hayJugadas,
        mensajeFeedback: 'Turno pasado. Nuevos dados: $nuevoD1 y $nuevoD2',
      ));
    }
  }

  /// Verifica si existe al menos una colocación válida en el tablero para los dados dados
  bool _hayJugadasPosibles(Tablero tablero, int d1, int d2) {
    for (final entry in tablero.celdas.entries) {
      final valor = entry.value.valor;
      if (valor == null) continue;

      if (valor == d1) {
        final posibles = tablero.obtenerPosiblesLugaresParaAncla(entry.key, d2);
        if (posibles.isNotEmpty) return true;
      }
      if (valor == d2) {
        final posibles = tablero.obtenerPosiblesLugaresParaAncla(entry.key, d1);
        if (posibles.isNotEmpty) return true;
      }
    }
    return false;
  }
}
