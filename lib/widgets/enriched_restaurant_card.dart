import 'package:flutter/material.dart';
import '../models/restaurant.dart';

class EnrichedRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const EnrichedRestaurantCard({Key? key, required this.restaurant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const rating = 4.5;
    const deliveryTime = "20-30 min";
    const cuisineType = "Comida Variada";

    Widget imageWidget;
    // La imagen ahora puede ser una ruta de asset o una URL de internet
    if (restaurant.imageUrl.startsWith('assets/')) {
      // Si la ruta comienza con 'assets/', usamos Image.asset
      imageWidget = Image.asset(
        restaurant.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.business_rounded, size: 40, color: Colors.grey),
      );
    } else if (restaurant.imageUrl.isNotEmpty) {
      // Si no, asumimos que es una URL de red
      imageWidget = Image.network(
        restaurant.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.business_rounded, size: 40, color: Colors.grey),
      );
    } else {
      // Si no hay ninguna imagen, mostramos un ícono
      imageWidget = const Icon(Icons.business_rounded, size: 40, color: Colors.grey);
    }
    
    // El resto del widget no cambia...
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey.shade200,
                  child: imageWidget, // Usamos el widget de imagen definido arriba
                ),
                // El resto del Stack (gradiente, tiempo de entrega, etc.)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '• $cuisineType',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}