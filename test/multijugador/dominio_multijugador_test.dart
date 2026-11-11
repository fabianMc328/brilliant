import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/multijugador/constantes_multijugador.dart';
import 'package:brilliant/multijugador/dominio/estado_carrera_region.dart';
import 'package:brilliant/multijugador/dominio/estado_sala_multijugador.dart';
import 'package:brilliant/multijugador/dominio/estados_jugador_sala.dart';
import 'package:brilliant/multijugador/dominio/jugador_multijugador.dart';
import 'package:brilliant/multijugador/dominio/mensajes_protocolo.dart';
import 'package:brilliant/multijugador/dominio/modelos_mapa.dart';

void main() {
  group('Dominio Cliente Multijugador - DTOs y Protocolo JSON', () {
    test('Metas oficiales de puntos escalan de 2 a 6 jugadores (26, 24, 22, 20)', () {
      expect(ConstantesMultijugador.obtenerMetaPuntos(2), 26);
      expect(ConstantesMultijugador.obtenerMetaPuntos(3), 24);
      expect(ConstantesMultijugador.obtenerMetaPuntos(4), 22);
      expect(ConstantesMultijugador.obtenerMetaPuntos(5), 20);
      expect(ConstantesMultijugador.obtenerMetaPuntos(6), 20);
    });

    test('EstadoCarreraRegion calcula correctamente el escalón disponible (1º, 2º, 3º+)', () {
      const tabla = {1: 7, 2: 5, 3: 3};

      const sinCompletar = EstadoCarreraRegion(
        regionId: 'azul_1',
        completadosPrevios: 0,
      );
      expect(sinCompletar.escalonActual, 1);
      expect(sinCompletar.puntosDisponibles(tabla), 7);

      const unoCompleto = EstadoCarreraRegion(
        regionId: 'azul_1',
        completadosPrevios: 1,
        idsJugadoresCompletaron: ['j1'],
      );
      expect(unoCompleto.escalonActual, 2);
      expect(unoCompleto.puntosDisponibles(tabla), 5);

      const cincoCompletos = EstadoCarreraRegion(
        regionId: 'azul_1',
        completadosPrevios: 5,
      );
      expect(cincoCompletos.escalonActual, 3);
      expect(cincoCompletos.puntosDisponibles(tabla), 3);
    });

    test('Validación de todosListosParaIniciar exige entre 2 y 6 jugadores conectados y listos', () {
      const j1 = ResumenJugador(
        id: '1',
        apodo: 'Uno',
        esAnfitrion: true,
        estaListo: true,
        participacion: EstadoParticipacion.conectado,
      );
      const j2NoListo = ResumenJugador(
        id: '2',
        apodo: 'Dos',
        esAnfitrion: false,
        estaListo: false,
        participacion: EstadoParticipacion.conectado,
      );

      const sala1 = EstadoSalaMultijugador(
        codigoSala: 'ABC234',
        miJugadorId: '1',
        fase: FaseSala.enLobby,
        nivelId: 'nivel_1',
        jugadores: [j1],
      );
      expect(sala1.todosListosParaIniciar, isFalse);

      const sala2Incompleta = EstadoSalaMultijugador(
        codigoSala: 'ABC234',
        miJugadorId: '1',
        fase: FaseSala.enLobby,
        nivelId: 'nivel_1',
        jugadores: [j1, j2NoListo],
      );
      expect(sala2Incompleta.todosListosParaIniciar, isFalse);

      final seisListos = List.generate(
        6,
        (i) => ResumenJugador(
          id: '$i',
          apodo: 'Jugador$i',
          esAnfitrion: i == 0,
          estaListo: true,
          participacion: EstadoParticipacion.conectado,
        ),
      );
      final sala6Lista = EstadoSalaMultijugador(
        codigoSala: 'ABC234',
        miJugadorId: '0',
        fase: FaseSala.enLobby,
        nivelId: 'nivel_1',
        jugadores: seisListos,
      );
      expect(sala6Lista.todosListosParaIniciar, isTrue);

      final seisConUnoCaido = [
        ...seisListos.sublist(0, 5),
        seisListos[5].copiarCon(participacion: EstadoParticipacion.reconectando),
      ];
      final salaCaida = EstadoSalaMultijugador(
        codigoSala: 'ABC234',
        miJugadorId: '0',
        fase: FaseSala.enLobby,
        nivelId: 'nivel_1',
        jugadores: seisConUnoCaido,
      );
      expect(salaCaida.todosListosParaIniciar, isFalse);
    });

    test('Serialización JSON de EventoServidor y EstadoSalaMultijugador preserva todos los datos', () {
      final estadoOriginal = EstadoSalaMultijugador(
        codigoSala: 'K7M4P9',
        miJugadorId: 'j1',
        fase: FaseSala.jugandoRondas,
        nivelId: 'nivel_4',
        jugadores: const [
          ResumenJugador(
            id: 'j1',
            apodo: 'Fabian',
            esAnfitrion: true,
            estaListo: true,
            participacion: EstadoParticipacion.conectado,
            puntuacion: 14,
            regionesCompletadas: 2,
          ),
        ],
        rondaActual: 5,
        dado1: 3,
        dado2: 6,
        segundosRestantes: 29,
        metaPuntos: 20,
        misValoresTablero: {
          const PosicionMapa(0, 4): 5,
          const PosicionMapa(2, 2): 3,
        },
        miDesglosePuntos: const {'naranja_4_6': 6, 'azul_1': 8},
        carreraPorRegion: const {
          'naranja_4_6': EstadoCarreraRegion(
            regionId: 'naranja_4_6',
            completadosPrevios: 1,
            idsJugadoresCompletaron: ['j1'],
          ),
        },
        mensajeEventoReciente: 'Ronda 5 iniciada',
      );

      final evento = EventoServidor(
        tipo: TipoEventoServidor.actualizacionSala,
        solicitudId: 'req_1',
        credencial: const CredencialSesionSala(
          codigoSala: 'K7M4P9',
          jugadorId: 'j1',
          tokenSesion: 'tok_secreto',
          apodo: 'Fabian',
        ),
        estadoSala: estadoOriginal,
      );

      final reconstruido = EventoServidor.fromJson(evento.toJson());
      expect(reconstruido.tipo, TipoEventoServidor.actualizacionSala);
      expect(reconstruido.credencial?.tokenSesion, 'tok_secreto');
      expect(reconstruido.estadoSala?.codigoSala, 'K7M4P9');
      expect(reconstruido.estadoSala?.nivelId, 'nivel_4');
      expect(
        reconstruido.estadoSala?.misValoresTablero[const PosicionMapa(0, 4)],
        5,
      );
      expect(reconstruido.estadoSala?.miDesglosePuntos['azul_1'], 8);
      expect(
        reconstruido.estadoSala?.carreraPorRegion['naranja_4_6']?.escalonActual,
        2,
      );
    });
  });
}
