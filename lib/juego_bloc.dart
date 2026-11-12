import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'juego_evento.dart';
import 'juego_estado.dart';
import 'niveles/catalogo_niveles.dart';
import 'region.dart';
import 'tablero.dart';

class JuegoBloc extends Bloc<JuegoEvento, JuegoEstado> {
  final Random _random;

  JuegoBloc({Random? random})
      : _random = random ?? Random(),
        super(JuegoSinIniciar()) {
    on<IniciarConfiguracionInicial>(_onIniciarConfiguracion);
    on<IniciarNivel>(_onIniciarNivel);
    on<ColocarValorInicial>(_onColocarValorInicial);
    on<LlenarValoresAleatorios>(_onLlenarValoresAleatorios);
    on<LimpiarValoresIniciales>(_onLimpiarValoresIniciales);
    on<AvanzarJuego>(_onAvanzarJuego);
    on<TirarDados>(_onTirarDados);
    on<SeleccionarDado>(_onSeleccionarDado);
    on<SeleccionarAncla>(_onSeleccionarAncla);
    on<ColocarNumero>(_onColocarNumero);
    on<DeseleccionarAncla>(_onDeseleccionarAncla);
    on<PasarTurno>(_onPasarTurno);
  }

  void _onIniciarConfiguracion(
    IniciarConfiguracionInicial event,
    Emitter<JuegoEstado> emit,
  ) {
    final nivel = event.nivel ?? CatalogoNiveles.nivel1;
    emit(JuegoEsperandoValoresIniciales(
      casillasInciales: event.casillasInciales,
      valoresColocados: const {},
      nivel: nivel,
    ));
  }

  void _onIniciarNivel(
    IniciarNivel event,
    Emitter<JuegoEstado> emit,
  ) {
    emit(JuegoEsperandoValoresIniciales(
      casillasInciales: event.nivel.casillasIniciales,
      valoresColocados: const {},
      nivel: event.nivel,
    ));
  }

  void _onColocarValorInicial(
    ColocarValorInicial event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEsperandoValoresIniciales) {
      final estadoActual = state as JuegoEsperandoValoresIniciales;

      // Revisa que sea una estrella válida.
      if (!estadoActual.casillasInciales.contains(event.coordenada)) {
        emit(JuegoError(
            "Solo puedes colocar valores iniciales en las casillas inciales.",
            estadoActual));
        emit(estadoActual);
        return;
      }

      // Debe ser del 1 al 6.
      if (event.valor < 1 || event.valor > 6) {
        emit(JuegoError(
            "El valor inicial debe estar entre 1 y 6.", estadoActual));
        emit(estadoActual);
        return;
      }

      // Si ya usamos el número en otra estrella, lo movemos acá.
      final nuevosValores =
          Map<Coordenada, int>.from(estadoActual.valoresColocados);

      if (nuevosValores.containsValue(event.valor)) {
        final coordenadaExistente = nuevosValores.entries
            .firstWhere((e) => e.value == event.valor)
            .key;
        nuevosValores.remove(coordenadaExistente);
      }

      // Guardamos el número en la casilla.
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

      // No deja avanzar si faltan estrellas por llenar.
      if (!estadoActual.listosParaAvanzar) {
        final faltantes = estadoActual.casillasInciales.length -
            estadoActual.valoresColocados.length;
        emit(JuegoError(
            "Falta colocar $faltantes número(s) en las casillas inciales para poder empezar.",
            estadoActual));
        emit(estadoActual);
        return;
      }

      // Arma el tablero con las zonas del nivel elegido.
      final tablero = estadoActual.nivel.crearTablero();

      // Pone los 6 números iniciales en el tablero.
      for (final entry in estadoActual.valoresColocados.entries) {
        final celda = tablero.celdas[entry.key];
        if (celda != null) {
          celda.valor = entry.value;
        }
      }

      // Primer tiro de dados.
      final d1 = _random.nextInt(6) + 1;
      final d2 = _random.nextInt(6) + 1;
      final hayJugadas = _hayJugadasPosibles(tablero, d1, d2);

      emit(JuegoEnProgreso(
        tablero: tablero,
        nivel: estadoActual.nivel,
        dado1: d1,
        dado2: d2,
        debeTirarDados: false,
        hayJugadasDisponibles: hayJugadas,
        turno: 1,
        puntuacionTotal: 0,
        regionesCompletadasIds: const [],
        desglosePuntos: const {},
        mensajeFeedback: '¡Partida lista! Toca un dado para colocar su número.',
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
        turno: actual.debeTirarDados ? actual.turno + 1 : actual.turno,
        dado1: d1,
        dado2: d2,
        debeTirarDados: false,
        limpiarDadoSeleccionado: true,
        limpiarAncla: true,
        limpiarNumeroAColocar: true,
        casillasValidas: {},
        hayJugadasDisponibles: hayJugadas,
        mensajeFeedback: 'Dados tirados: $d1 y $d2. Toca un dado para colocar su número.',
      ));
    }
  }

  void _onSeleccionarDado(
    SeleccionarDado event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is! JuegoEnProgreso) return;
    final actual = state as JuegoEnProgreso;

    if (actual.debeTirarDados) {
      emit(actual.copiarCon(
        mensajeFeedback: 'Debes presionar obligatoriamente "Tirar Dados" para tu siguiente turno.',
      ));
      return;
    }

    // Si ya estaba seleccionado el mismo dado, deseleccionarlo
    if (actual.indiceDadoSeleccionado == event.indiceDado) {
      emit(actual.copiarCon(
        limpiarDadoSeleccionado: true,
        limpiarAncla: true,
        limpiarNumeroAColocar: true,
        casillasValidas: {},
        mensajeFeedback: 'Dado deseleccionado. Elige un dado para jugar.',
      ));
      return;
    }

    final numeroAColocar = event.valor;
    final valorAnclaRequerido =
        event.indiceDado == 1 ? actual.dado2 : actual.dado1;

    final validas = actual.tablero.obtenerPosiblesLugaresParaDado(
      numeroAColocar: numeroAColocar,
      valorAncla: valorAnclaRequerido,
    );

    String feedback;
    if (validas.isEmpty) {
      feedback =
          'No hay casillas válidas para colocar el $numeroAColocar con anclas de valor $valorAnclaRequerido.';
    } else {
      feedback =
          'Dado $numeroAColocar seleccionado. Toca una casilla iluminada en verde para colocarlo.';
    }

    emit(actual.copiarCon(
      indiceDadoSeleccionado: event.indiceDado,
      numeroAColocar: numeroAColocar,
      casillasValidas: validas,
      limpiarAncla: true,
      mensajeFeedback: feedback,
    ));
  }

  void _onSeleccionarAncla(
    SeleccionarAncla event,
    Emitter<JuegoEstado> emit,
  ) {
    if (state is JuegoEnProgreso) {
      final actual = state as JuegoEnProgreso;

      if (actual.debeTirarDados) {
        emit(actual.copiarCon(
          mensajeFeedback: 'Debes presionar obligatoriamente "Tirar Dados" para tu siguiente turno.',
        ));
        return;
      }

      final celda = actual.tablero.celdas[event.coordenada];
      if (celda == null || celda.estaVacia) {
        emit(actual.copiarCon(
          mensajeFeedback: 'Debes seleccionar una casilla ocupada como ancla.',
        ));
        return;
      }

      final valorAncla = celda.valor!;

      // Checa que el ancla coincida con alguno de los dos dados.
      if (valorAncla != actual.dado1 && valorAncla != actual.dado2) {
        emit(actual.copiarCon(
          mensajeFeedback:
              'El ancla seleccionada ($valorAncla) no coincide con los dados (${actual.dado1} o ${actual.dado2}).',
        ));
        return;
      }

      // El otro dado es el número que vamos a poner.
      final int numeroAColocar;
      final int indiceDado;
      if (valorAncla == actual.dado1) {
        numeroAColocar = actual.dado2;
        indiceDado = 2;
      } else {
        numeroAColocar = actual.dado1;
        indiceDado = 1;
      }

      // Busca casillas vecinas donde sea legal meter el número.
      final validas = actual.tablero
          .obtenerPosiblesLugaresParaAncla(event.coordenada, numeroAColocar);

      String? feedback;
      if (validas.isEmpty) {
        feedback =
            'No hay casillas válidas para colocar el $numeroAColocar junto a esta ancla.';
      } else {
        feedback =
            'Colocando el $numeroAColocar. Selecciona una casilla iluminada.';
      }

      emit(actual.copiarCon(
        anclaSeleccionada: event.coordenada,
        indiceDadoSeleccionado: indiceDado,
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

      if (actual.debeTirarDados) {
        emit(actual.copiarCon(
          mensajeFeedback: 'Debes presionar "Tirar Dados" para tu siguiente turno.',
        ));
        return;
      }

      if (actual.numeroAColocar == null ||
          !actual.casillasValidas.contains(event.coordenada)) {
        emit(actual.copiarCon(
          mensajeFeedback: 'Selecciona una de las casillas iluminadas válidas.',
        ));
        return;
      }

      // Pone el número en la casilla elegida.
      final colocado = actual.tablero
          .colocarNumero(event.coordenada, actual.numeroAColocar!);
      if (!colocado) {
        emit(actual.copiarCon(
          mensajeFeedback: 'No se pudo colocar el número en esa casilla.',
        ));
        return;
      }

      // Checa si se completó alguna región.
      final completadas = List<String>.from(actual.regionesCompletadasIds);
      String? avisoCompletada;

      for (final region in actual.tablero.regiones) {
        if (!completadas.contains(region.id) &&
            actual.tablero.esRegionCompleta(region)) {
          completadas.add(region.id);
          avisoCompletada = '¡Región completada con éxito! 🎉';
        }
      }

      // Recalcula el puntaje acumulado.
      final nuevaPuntuacion =
          actual.tablero.calcularPuntuacionTotal(completadas);
      final nuevoDesglose =
          actual.tablero.calcularDesglosePuntos(completadas);

      // Requerimiento explícito: Una vez puesto el dado, debe volver a picarle
      // obligatoriamente al botón de tirar dados para generar otros dos números.
      emit(actual.copiarCon(
        limpiarAncla: true,
        limpiarNumeroAColocar: true,
        limpiarDadoSeleccionado: true,
        casillasValidas: {},
        debeTirarDados: true,
        puntuacionTotal: nuevaPuntuacion,
        regionesCompletadasIds: completadas,
        desglosePuntos: nuevoDesglose,
        mensajeFeedback: avisoCompletada != null
            ? '$avisoCompletada ¡Tira los dados para tu siguiente turno!'
            : '¡Número colocado! Presiona obligatoriamente "Tirar Dados" para continuar.',
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
        limpiarDadoSeleccionado: true,
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
        debeTirarDados: false,
        limpiarDadoSeleccionado: true,
        limpiarAncla: true,
        limpiarNumeroAColocar: true,
        casillasValidas: {},
        hayJugadasDisponibles: hayJugadas,
        mensajeFeedback: 'Turno pasado. Nuevos dados: $nuevoD1 y $nuevoD2.',
      ));
    }
  }

  // Revisa si hay alguna jugada posible con estos dados.
  bool _hayJugadasPosibles(Tablero tablero, int d1, int d2) {
    for (final entry in tablero.celdas.entries) {
      final valor = entry.value.valor;
      if (valor == null) continue;

      if (valor == d1) {
        final posibles =
            tablero.obtenerPosiblesLugaresParaAncla(entry.key, d2);
        if (posibles.isNotEmpty) return true;
      }
      if (valor == d2) {
        final posibles =
            tablero.obtenerPosiblesLugaresParaAncla(entry.key, d1);
        if (posibles.isNotEmpty) return true;
      }
    }
    return false;
  }
}
