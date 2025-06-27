import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/main.dart';
import 'package:restaurant_app/providers/user_provider.dart';
import 'package:restaurant_app/services/cart_service.dart';
import 'package:restaurant_app/screens/welcome_screen.dart';

void main() {
  // This is a more meaningful widget test for your application.
  // It verifies that the initial WelcomeScreen is displayed correctly.
  testWidgets('WelcomeScreen shows login options', (WidgetTester tester) async {
    // Build our app with the necessary providers, just like in main.dart.
    // The test environment needs to know about the providers your widgets depend on.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartService()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: MyApp(),
      ),
    );

    // Wait for any animations or async operations to complete.
    await tester.pumpAndSettle();

    // Verify that the WelcomeScreen is being displayed and contains the two main options.
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Soy Usuario'), findsOneWidget);
    expect(find.text('Soy Restaurante'), findsOneWidget);
  });
}
