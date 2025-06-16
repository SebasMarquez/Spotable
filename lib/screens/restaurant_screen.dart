import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'menu_mngmt_screen.dart';
import '../utils/app_colors.dart';

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
            leading:
                Navigator.of(context).canPop()
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

                // Sección de reservaciones
                _buildReservationsSection(),
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
        color: Colors.white, // Fondo blanco para el header
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
              child: Container(
                color: Colors.white, // Fondo blanco para la imagen
                child: Image.network(
                  imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.red[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
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
              child: const Icon(
                Icons.restaurant,
                size: 60,
                color: Colors.white,
              ),
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
                builder:
                    (context) =>
                        MenuManagementScreen(restaurantId: restaurantId),
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
          color: Colors.white, // Fondo blanco para las action cards
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
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsSection() {
    return _buildSection(
      title: 'Reservaciones Activas',
      icon: Icons.event_seat,
      child: SizedBox(
        height: 280,
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('Restaurante')
                  .doc(restaurantId)
                  .collection('Mesas')
                  .where('Estado', isEqualTo: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.event_seat_outlined,
                message: 'No hay reservaciones activas.',
              );
            }
            final reservedTables = snapshot.data!.docs;
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: reservedTables.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tableDoc = reservedTables[index];
                final tableData = tableDoc.data() as Map<String, dynamic>;
                final numero = tableData['numero'] ?? '';
                final datosCliente =
                    tableData['datosCliente'] as Map<String, dynamic>?;

                if (datosCliente == null) return const SizedBox.shrink();

                final nombreCliente =
                    datosCliente['nombreCliente'] ?? 'Sin nombre';
                final contactoCliente =
                    datosCliente['contactoCliente']?.toString() ?? '';
                final fechaHoraReservacion =
                    datosCliente['fecha_HoraReservacion'] as Timestamp?;

                String fechaHoraTexto = 'Sin fecha';
                if (fechaHoraReservacion != null) {
                  final fechaHora = fechaHoraReservacion.toDate();
                  fechaHoraTexto =
                      '${fechaHora.day}/${fechaHora.month}/${fechaHora.year} ${fechaHora.hour}:${fechaHora.minute.toString().padLeft(2, '0')}';
                }

                return Card(
                  elevation: 2,
                  color: Colors.white, // Fondo blanco para todas las cartas
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.event_seat,
                                    color: Colors.red[600],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Mesa $numero',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed:
                                  () => _showClearReservationDialog(
                                    context,
                                    tableDoc.id,
                                    numero.toString(),
                                  ),
                              icon: Icon(Icons.clear, color: Colors.red[600]),
                              tooltip: 'Limpiar reservación',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildReservationDetail(
                          Icons.person,
                          'Cliente',
                          nombreCliente,
                        ),
                        const SizedBox(height: 8),
                        if (contactoCliente.isNotEmpty)
                          _buildReservationDetail(
                            Icons.phone,
                            'Contacto',
                            contactoCliente,
                          ),
                        if (contactoCliente.isNotEmpty)
                          const SizedBox(height: 8),
                        _buildReservationDetail(
                          Icons.schedule,
                          'Fecha y Hora',
                          fechaHoraTexto,
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

  Widget _buildReservationDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label + ': ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  void _showClearReservationDialog(
    BuildContext context,
    String docId,
    String mesaNumero,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Limpiar Reservación'),
          content: Text(
            '¿Está seguro que desea limpiar la reservación de la Mesa $mesaNumero?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearReservation(context, docId, mesaNumero);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Limpiar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearReservation(
    BuildContext context,
    String docId,
    String mesaNumero,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(restaurantId)
          .collection('Mesas')
          .doc(docId)
          .update({'Estado': false, 'datosCliente': FieldValue.delete()});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reservación de Mesa $mesaNumero limpiada exitosamente',
            ),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al limpiar reservación: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Widget _buildOrdersSection(FirebaseService firebaseService) {
    return _buildSection(
      title: 'Pedidos Recientes',
      icon: Icons.receipt_long,
      child: SizedBox(
        height: 320,
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
                final estado = orderData['estado'] ?? 'Generado';
                final cedula = orderData['cedula'] ?? '';
                final createdAt = orderData['createdAt'];
                String hora = '';
                if (createdAt is Timestamp) {
                  final dt = createdAt.toDate();
                  hora =
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } else if (createdAt is DateTime) {
                  hora =
                      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                }

                return Card(
                  elevation: 2,
                  color: Colors.white, // Fondo blanco para todas las cartas
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final nombre = await _getNombreCliente(cedula);
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.white, // Fondo blanco
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Detalle del Pedido',
                              style: TextStyle(
                                color: Colors.black,
                              ), // Título negro
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cliente: ${nombre ?? 'Desconocido'}'),
                                Text('Cédula: $cedula'),
                                Text('Total: \$${total.toStringAsFixed(2)}'),
                                Text('Estado: $estado'),
                                Text('Hora: $hora'),
                                const SizedBox(height: 12),
                                const Text(
                                  'Items:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...items.entries.map(
                                  (entry) =>
                                      Text('• ${entry.key} x${entry.value}'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  await FirebaseService.updateOrderEstado(
                                    restaurantId: restaurantId,
                                    orderId: order.id,
                                    nuevoEstado: 'En cocina',
                                  );
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'En cocina',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await FirebaseService.updateOrderEstado(
                                    restaurantId: restaurantId,
                                    orderId: order.id,
                                    nuevoEstado: 'Listo',
                                  );
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Listo',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Cerrar',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pedido',
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
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  estado,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                tooltip: 'Eliminar pedido',
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('Restaurante')
                                      .doc(restaurantId)
                                      .collection('Order')
                                      .doc(order.id)
                                      .delete();
                                },
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
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Total: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '\$${total.toStringAsFixed(2)}', // Muestra el total guardado en firebase con el símbolo $
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Future<String?> _getNombreCliente(String cedula) async {
    if (cedula.isEmpty) return null;
    final user =
        await FirebaseFirestore.instance
            .collection('Usuario')
            .doc(cedula)
            .get();
    return user.data()?['nombre'] as String?;
  }

  Widget _buildTablesSection() {
    return _buildSection(
      title: 'Estado de Mesas',
      icon: Icons.table_restaurant,
      child: SizedBox(
        height: 240,
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
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
                  color: Colors.white, // Fondo blanco para todas las cartas
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
                            color: estado ? Colors.red[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            estado
                                ? Icons.event_seat
                                : Icons.event_seat_outlined,
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
                                  color:
                                      estado
                                          ? Colors.red[600]
                                          : Colors.green[600],
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

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
