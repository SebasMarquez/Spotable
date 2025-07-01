import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../screens/menu_screen.dart'; // Aunque no se usa directamente, lo mantenemos por si se necesita
import 'reservation_dialog.dart'; // Importa el diálogo de reserva
import 'menu_dialog.dart'; // Importa el nuevo diálogo de menú

class RestaurantOptionsDialog extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantOptionsDialog({Key? key, required this.restaurant}) : super(key: key);

  // Helper para construir la imagen del restaurante, manejando assets y URLs
  Widget _buildRestaurantImage() {
    if (restaurant.imageUrl.startsWith('assets/')) {
      return Image.asset(
        restaurant.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant, size: 60, color: Colors.grey),
      );
    } else if (restaurant.imageUrl.startsWith('http')) {
      return Image.network(
        restaurant.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant, size: 60, color: Colors.grey),
      );
    } else {
      return const Icon(Icons.restaurant, size: 60, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Para que el diálogo se ajuste a su contenido
          children: [
            // Información del Restaurante
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '¿Qué te gustaría hacer?',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // Botones de Acción
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Icon(Icons.restaurant_menu, color: Colors.red[700]),
              title: const Text('Ver Menú', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pop(); // Cierra el diálogo de opciones
                showDialog(
                  context: context,
                  barrierDismissible: false, // Evita que se cierre al tocar fuera
                  // Abre el nuevo diálogo de menú
                  builder: (context) => MenuDialog(restaurantId: restaurant.id),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Icon(Icons.event_available, color: Colors.green[700]),
              title: const Text('Hacer Reserva', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pop(); // Cierra este diálogo
                showDialog(
                  context: context,
                  builder: (context) => ReservationDialog(restauranteId: restaurant.id),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
