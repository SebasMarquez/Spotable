import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../services/cart_service.dart';
import 'menu_screen.dart';
import '../widgets/reservation_dialog.dart';
import 'cart_screen.dart';

class SelectOptionScreen extends StatelessWidget {
  final Restaurant restaurant;

  const SelectOptionScreen({Key? key, required this.restaurant})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Escuchamos al CartService para saber cuándo mostrar el botón del carrito
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // --- BOTÓN DE CARRITO FLOTANTE ---
      floatingActionButton: cartService.totalItems > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(restaurantId: restaurant.id),
                  ),
                );
              },
              backgroundColor: Colors.red[600],
              icon: Badge(
                label: Text('${cartService.totalItems}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              label: Text('Ver Carrito (\$${cartService.totalPrice.toStringAsFixed(2)})'),
            )
          : null, // Si no hay items, no se muestra el botón
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- Información del restaurante (sin cambios) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: _buildRestaurantImage(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB71C1C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¿Qué te gustaría hacer?',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- Botones de opciones (sin cambios funcionales) ---
            _buildOptionButton(
              context: context,
              icon: Icons.restaurant_menu,
              title: 'Ver Menú',
              subtitle: 'Explora nuestros platos',
              color: const Color(0xFFB71C1C),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuScreen(restaurantId: restaurant.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildOptionButton(
              context: context,
              icon: Icons.event_available,
              title: 'Hacer Reserva',
              subtitle: 'Reserva tu mesa',
              color: const Color(0xFF2E7D32),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => ReservationDialog(restauranteId: restaurant.id),
                );
              },
            ),
            const SizedBox(height: 80), // Espacio para que el FAB no tape nada
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantImage() {
    if (restaurant.imageUrl.startsWith('assets/')) {
      return Image.asset(restaurant.imageUrl, fit: BoxFit.cover);
    } else if (restaurant.imageUrl.startsWith('http')) {
      return Image.network(restaurant.imageUrl, fit: BoxFit.cover);
    } else {
      return const Icon(Icons.restaurant, size: 80, color: Colors.grey);
    }
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    // ... (Este widget no tiene cambios)
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
