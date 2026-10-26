import 'package:flutter_test/flutter_test.dart';

import 'dominio/reglas_test.dart' as reglas_test;
import 'dominio/tipo_test.dart' as tipo_test;
import 'dominio/region_test.dart' as region_test;
import 'dominio/tablero_test.dart' as tablero_test;
import 'dominio/nivel1_test.dart' as nivel1_test;
import 'dominio/nivel2_test.dart' as nivel2_test;
import 'dominio/nivel3_test.dart' as nivel3_test;
import 'dominio/nivel4_test.dart' as nivel4_test;
import 'dominio/catalogo_niveles_test.dart' as catalogo_niveles_test;
import 'bloc/juego_bloc_test.dart' as juego_bloc_test;
import 'widgets/casilla_juego_test.dart' as casilla_juego_test;
import 'widgets/widget_dado_test.dart' as widget_dado_test;
import 'widgets/componentes_panel_test.dart' as componentes_panel_test;
import 'widgets/pantalla_juego_test.dart' as pantalla_juego_test;
import 'widgets/pantalla_seleccion_nivel_test.dart'
    as pantalla_seleccion_nivel_test;
import 'widgets/responsivo_test.dart' as responsivo_test;

// Corre todas las pruebas del juego juntas.
void main() {
  group('Reglas y lógica del tablero', () {
    reglas_test.main();
    tipo_test.main();
    region_test.main();
    tablero_test.main();
    nivel1_test.main();
    nivel2_test.main();
    nivel3_test.main();
    nivel4_test.main();
    catalogo_niveles_test.main();
  });

  group('Estados, dados y turnos', () {
    juego_bloc_test.main();
  });

  group('Pantallas, dados y botones visuales', () {
    casilla_juego_test.main();
    widget_dado_test.main();
    componentes_panel_test.main();
    pantalla_juego_test.main();
    pantalla_seleccion_nivel_test.main();
    responsivo_test.main();
  });
}
