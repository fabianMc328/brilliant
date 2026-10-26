import 'package:test/test.dart';
import 'package:brilliant/niveles/catalogo_niveles.dart';

void main() {
  group('Catálogo de Niveles', () {
    test('Contiene exactamente los 4 niveles oficiales', () {
      expect(CatalogoNiveles.todos.length, 4);
      expect(CatalogoNiveles.todos.map((n) => n.numero), [1, 2, 3, 4]);
    });

    test('Permite buscar nivel por número', () {
      expect(CatalogoNiveles.porNumero(1).id, 'nivel_1');
      expect(CatalogoNiveles.porNumero(2).id, 'nivel_2');
      expect(CatalogoNiveles.porNumero(3).id, 'nivel_3');
      expect(CatalogoNiveles.porNumero(4).id, 'nivel_4');
      // Si no existe, devuelve nivel 1 por defecto
      expect(CatalogoNiveles.porNumero(99).id, 'nivel_1');
    });

    test('Permite buscar nivel por id', () {
      expect(CatalogoNiveles.porId('nivel_2').numero, 2);
      expect(CatalogoNiveles.porId('nivel_invalido').numero, 1);
    });
  });
}
