import 'package:flutter/material.dart';
import '../region.dart';
import '../tablero.dart';

// Lo que debe tener cualquier nivel del juego.
abstract class NivelDefinicion {
  int get numero;
  String get id;
  String get nombre;
  String get dificultad;
  Color get colorTema;
  String get descripcion;
  List<Region> get regiones;
  List<Coordenada> get casillasIniciales;

  // Arma el tablero de 7x7 con las zonas del nivel.
  Tablero crearTablero() {
    final tablero = Tablero(filas: 7, columnas: 7);
    tablero.cargarRegiones(regiones);
    return tablero;
  }
}
