import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/main.dart';
import 'package:restaurant_app/screens/welcome_screen.dart';

void main() {
  // This is a more meaningful widget test for your application.
  // It verifies that the initial WelcomeScreen is displayed correctly.
  testWidgets('WelcomeScreen muestra las opciones principales', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verifica que la pantalla de bienvenida se muestre
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Verifica que los botones principales estén presentes
    expect(find.text('Login Restaurant'), findsOneWidget);
    expect(find.text('Crear un restaurante'), findsOneWidget);
  });
}
