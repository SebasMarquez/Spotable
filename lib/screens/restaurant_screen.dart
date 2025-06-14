import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'menu_mngmt_screen.dart'; // Nueva pantalla que crearemos

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
            title: const Text('Panel Restaurante'),
            backgroundColor: Colors.red[600],
            elevation: 0,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header con logo y nombre
                _buildRestaurantHeader(name, imageUrl),
                const SizedBox(height: 32),

                // Cards de navegación rápida
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Sección de pedidos realizados
                _buildOrdersSection(firebaseService),
                const SizedBox(height: 24),

                // Sección de mesas
                _buildTablesSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestaurantHeader(String name, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[50]!, Colors.red[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.red[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.restaurant, size: 60, color: Colors.white),
                    ),
              ),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.restaurant, size: 60, color: Colors.white),
            ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        child: _buildActionCard(
          icon: Icons.restaurant_menu,
          title: 'Gestionar Menú',
          subtitle: 'Editar platos y disponibilidad',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MenuManagementScreen(restaurantId: restaurantId),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSection(FirebaseService firebaseService) {
    return _buildSection(
      title: 'Pedidos Recientes',
      icon: Icons.receipt_long,
      child: SizedBox(
        height: 240,
        child: StreamBuilder<QuerySnapshot>(
          stream: firebaseService.ordersStream(restaurantId),
          builder: (context, orderSnapshot) {
            if (orderSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'No hay pedidos realizados.',
              );
            }
            final orders = orderSnapshot.data!.docs;
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = orders[index];
                final orderData = order.data() as Map<String, dynamic>;
                final total = orderData['total'] ?? 0;
                final itemsRaw = orderData['Items'];
                final items = itemsRaw is Map ? itemsRaw : <String, dynamic>{};
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pedido #${orderData['Id'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$${total.toString()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...items.entries.map((entry) {
                          final nombre = entry.key;
                          final cantidad = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'x$cantidad',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    nombre.toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTablesSection() {
    return _buildSection(
      title: 'Estado de Mesas',
      icon: Icons.table_restaurant,
      child: SizedBox(
        height: 240,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Restaurante')
              .doc(restaurantId)
              .collection('Mesas')
              .snapshots(),
          builder: (context, mesaSnapshot) {
            if (mesaSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!mesaSnapshot.hasData || mesaSnapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.table_restaurant_outlined,
                message: 'No hay mesas registradas.',
              );
            }
            final mesas = mesaSnapshot.data!.docs;
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: mesas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final mesa = mesas[index];
                final mesaData = mesa.data() as Map<String, dynamic>;
                final numero = mesaData['numero'] ?? '';
                final estado = mesaData['Estado'] ?? false;
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: estado 
                                ? Colors.red[100] 
                                : Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            estado ? Icons.event_seat : Icons.event_seat_outlined,
                            color: estado ? Colors.red[600] : Colors.green[600],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mesa $numero',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                estado ? 'Ocupada' : 'Disponible',
                                style: TextStyle(
                                  color: estado ? Colors.red[600] : Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
