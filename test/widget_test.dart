import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/main.dart';

void main() {
  testWidgets('Verificar carga de la pantalla de casillas', (
    WidgetTester tester,
  ) async {
    // Construye la aplicación principal
    await tester.pumpWidget(const AplicacionBrilliant());

    // Comprueba que el título de la barra superior se muestre
    expect(find.text('Boceto de Casilla - Brilliant'), findsOneWidget);
  });
}
