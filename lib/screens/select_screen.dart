import 'package:flutter/material.dart';
import '/screens/menu_screen.dart';
import '/screens/reservation_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  // Implementación de la navegación a la pantalla del menú del restaurante
  void _navigateToMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MenuScreen()),
    );
  }

  void _navigateToReservation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReservationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Ver menú del restaurante'),
                onPressed: () => _navigateToMenu(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.event_seat),
                label: const Text('Realizar una reservación'),
                onPressed: () => _navigateToReservation(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
