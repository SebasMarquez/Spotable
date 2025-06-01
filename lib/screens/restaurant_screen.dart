import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class RestaurantScreen extends StatelessWidget {
  final String restaurantId;

  const RestaurantScreen({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: firebaseService.fetchRestaurantInfo(restaurantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        final name = data['Nombre'] ?? 'Restaurante';
        final imageUrl = data['imagen'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text('Panel Restaurante'),
            backgroundColor: Colors.red[600],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo y nombre
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.restaurant, size: 80),
                    ),
                  )
                else
                  const Icon(Icons.restaurant, size: 80),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Sección de pedidos realizados
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pedidos realizados',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 300, // Altura fija para el scroll
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firebaseService.ordersStream(restaurantId),
                    builder: (context, orderSnapshot) {
                      if (orderSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!orderSnapshot.hasData ||
                          orderSnapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay pedidos realizados.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      final orders = orderSnapshot.data!.docs;
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final orderData =
                              order.data() as Map<String, dynamic>;
                          final total = orderData['Total'] ?? 0;
                          final itemsRaw = orderData['Items'];
                          final items =
                              itemsRaw is Map
                                  ? [itemsRaw]
                                  : (itemsRaw is List ? itemsRaw : []);
                          return Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pedido #${orderData['Id'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...items.map((item) {
                                    if (item is Map<String, dynamic>) {
                                      final name =
                                          item['Name'] ?? item['name'] ?? '';
                                      final qty =
                                          item['Cantidad'] ??
                                          item['cantidad'] ??
                                          0;
                                      return Row(
                                        children: [
                                          Text(
                                            'x$qty',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              name.toString(),
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  }),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Total: \$${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Sección de mesas (vacía)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mesas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('Próximamente...')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
