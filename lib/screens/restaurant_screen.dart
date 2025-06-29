import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'menu_mngmt_screen.dart';
import '../utils/app_colors.dart';
import '../models/order.dart' as app_order; // Alias your Order model to avoid conflict
import '../widgets/order_card.dart'; // Import the new OrderCard widget

class RestaurantScreen extends StatelessWidget {
  final String restaurantId;
  final VoidCallback onLogout;

  const RestaurantScreen(
      {Key? key, required this.restaurantId, required this.onLogout})
      : super(key: key);

  // Nuevo método para actualizar el estado del pedido
  Future<void> _updateOrderStatus(
      BuildContext context, String orderId, String newStatus) async {
    try {
      // Usar FirebaseService para actualizar el estado
      await FirebaseService.updateOrderEstado(
        restaurantId: restaurantId,
        orderId: orderId,
        nuevoEstado: newStatus,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado del pedido actualizado a "$newStatus"'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NUEVO: Método para mostrar el diálogo de confirmación
  void _showStatusChangeConfirmation(
      BuildContext context, app_order.Order order, String nextStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Cambio de Estado'),
          content: Text(
              '¿Estás seguro de que deseas cambiar el estado del pedido #${order.id.substring(0, 8)}... de "${order.estado}" a "$nextStatus"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _updateOrderStatus(context, order.id, nextStatus); // Ejecutar el cambio
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getNextStatusButtonColor(order.estado), // Usa el color del siguiente estado
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // NUEVO: Método para mostrar diálogo de confirmación para cambiar estado de mesa
  void _showToggleTableStatusConfirmation(
    BuildContext context,
    String tableId,
    String tableNumber,
    bool currentStatus,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cambiar Estado de Mesa'),
          content: Text(
            '¿Estás seguro de que deseas cambiar el estado de la Mesa $tableNumber a "${currentStatus ? 'Disponible' : 'Ocupada'}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _toggleTableStatus(
                    context, tableId, currentStatus); // Ejecutar el cambio
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: currentStatus ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // NUEVO: Método para cambiar el estado de la mesa
  Future<void> _toggleTableStatus(
      BuildContext context, String tableId, bool currentStatus) async {
    try {
      // Si el estado actual es 'Ocupada' (true), al cambiarlo a 'Disponible' (false)
      // debemos limpiar la reservación asociada.
      if (currentStatus) {
        await FirebaseService.setTableAsAvailableAndClearReservation(
          restaurantId: restaurantId,
          tableId: tableId,
        );
      } else {
        // Si el estado actual es 'Disponible' (false), simplemente lo cambiamos a 'Ocupada' (true).
        await FirebaseService.updateTableStatus(
          restaurantId: restaurantId,
          tableId: tableId,
          isOccupied: true,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado de la mesa actualizado.'),
            backgroundColor: AppColors.secondary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado de la mesa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: firebaseService.fetchRestaurantInfo(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Restaurante no encontrado')),
            body: _buildEmptyState(
              icon: Icons.restaurant_menu,
              message: 'No se encontró información para este restaurante.',
            ),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar Sesión',
                onPressed: onLogout,
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                // Diseño de una sola columna para pantallas pequeñas (móviles)
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildRestaurantHeader(name, imageUrl),
                      const SizedBox(height: 32),
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Reservaciones Activas',
                        icon: Icons.event_seat,
                        child: _buildReservationsList(),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Pedidos Recientes',
                        icon: Icons.receipt_long,
                        child: _buildOrdersList(firebaseService),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Estado de Mesas',
                        icon: Icons.table_restaurant,
                        child: _buildTablesList(),
                      ),
                    ],
                  ),
                );
              } else {
                // Diseño de tres columnas para pantallas grandes (tablets, desktops)
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildRestaurantHeader(name, imageUrl),
                          const SizedBox(height: 32),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: _buildSection(
                                title: 'Reservaciones Activas',
                                icon: Icons.event_seat,
                                child: _buildReservationsList(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: _buildSection(
                                title: 'Pedidos Recientes',
                                icon: Icons.receipt_long,
                                child: _buildOrdersList(firebaseService),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: _buildSection(
                                title: 'Estado de Mesas',
                                icon: Icons.table_restaurant,
                                child: _buildTablesList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildRestaurantHeader(String name, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                color: Colors.white,
                child: Image.network(
                  imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
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
                builder: (context) =>
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
          color: Colors.white,
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

  Widget _buildReservationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(restaurantId)
          .collection('Reservas')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildEmptyState(
              icon: Icons.error_outline,
              message: 'Error al cargar reservaciones: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_seat_outlined,
            message: 'No hay reservaciones activas.',
          );
        }
        final reservedTables = snapshot.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reservedTables.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tableDoc = reservedTables[index];
            final tableData = tableDoc.data() as Map<String, dynamic>;
            final numero = tableData['numero_mesa'] ?? ''; // CAMBIO: Leer 'numero_mesa'
            final nombreCliente = tableData['nombreCliente'] ?? 'Sin nombre';
            final contactoCliente =
                tableData['contactoCliente']?.toString() ?? '';
            final fechaHoraReservacion =
                tableData['fecha_HoraReservacion'] as Timestamp?;

            String fechaHoraTexto = 'Sin fecha';
            if (fechaHoraReservacion != null) {
              final fechaHora = fechaHoraReservacion.toDate();
              fechaHoraTexto =
                  '${fechaHora.day}/${fechaHora.month}/${fechaHora.year} ${fechaHora.hour}:${fechaHora.minute.toString().padLeft(2, '0')}';
            }

            return Card(
              elevation: 2,
              color: Colors.white,
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
                          onPressed: () => _showClearReservationDialog(
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
    );
  }

  Widget _buildReservationDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
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
          title: const Text('Limpiar Reservación'),
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
      // Obtener la reservación para encontrar el ID de la mesa asociada
      final reservationRef = FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(restaurantId)
          .collection('Reservas')
          .doc(docId);
      final reservationSnapshot = await reservationRef.get();

      if (!reservationSnapshot.exists) {
        throw Exception('La reservación no fue encontrada.');
      }

      final reservationData = reservationSnapshot.data() as Map<String, dynamic>;
      final tableId = reservationData['id_mesa'] as String?;

      if (tableId != null && tableId.isNotEmpty) {
        // Usar la función centralizada que actualiza la mesa y limpia todas las reservaciones asociadas
        await FirebaseService.setTableAsAvailableAndClearReservation(
          restaurantId: restaurantId,
          tableId: tableId,
        );
      } else {
        // Como fallback, si no hay mesa asociada, simplemente borrar la reservación
        await reservationRef.delete();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reservación de Mesa ${mesaNumero.isNotEmpty ? mesaNumero : '?'} limpiada exitosamente',
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

  Widget _buildOrdersList(FirebaseService firebaseService) {
    return StreamBuilder<List<app_order.Order>>( // Corrected StreamBuilder type
      stream: FirebaseService.getOrdersByRestaurante(restaurantId),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (orderSnapshot.hasError) {
          return _buildEmptyState(
              icon: Icons.error_outline,
              message: 'Error al cargar pedidos: ${orderSnapshot.error}');
        }
        // Correctly check if data is null or empty list for List<Order>
        if (!orderSnapshot.hasData || orderSnapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.receipt_long_outlined,
            message: 'No hay pedidos realizados.',
          );
        }
        final orders = orderSnapshot.data!; // Now 'orders' is correctly List<app_order.Order>

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = orders[index];
            String nextStatus = '';
            VoidCallback? onPressed;

            switch (order.estado) {
              case 'Generado':
                nextStatus = 'En cocina';
                // Llamamos al diálogo de confirmación en lugar de la actualización directa
                onPressed = () => _showStatusChangeConfirmation(context, order, nextStatus);
                break;
              case 'En cocina':
                nextStatus = 'Listo';
                // Llamamos al diálogo de confirmación en lugar de la actualización directa
                onPressed = () => _showStatusChangeConfirmation(context, order, nextStatus);
                break;
              case 'Listo':
                nextStatus = 'Entregado';
                // Llamamos al diálogo de confirmación en lugar de la actualización directa
                onPressed = () => _showStatusChangeConfirmation(context, order, nextStatus);
                break;
              default:
                onPressed = null; // No action for other statuses like "Entregado" or "Cancelado"
            }

            return Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: ListTile(
                title: Text('Pedido #${order.id.substring(0, 8)}... - ${order.restauranteName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cliente: ${order.cedulaCliente}'),
                    Text('Total: \$${order.total.toStringAsFixed(2)}'),
                    Text('Estado: ${order.estado}'),
                    if (order.idMesa != null && order.idMesa!.isNotEmpty)
                      Text('Mesa: ${order.idMesa}'),
                    if (order.deliveryType == 'delivery' && order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                      Text('Dirección: ${order.deliveryAddress}'),
                  ],
                ),
                trailing: onPressed != null
                    ? ElevatedButton(
                        onPressed: onPressed, // Ahora llama al diálogo de confirmación
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getNextStatusButtonColor(order.estado),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(nextStatus),
                      )
                    : _getStatusIconForAdmin(order.estado),
                onTap: () {
                  // Opcional: Expandir para ver más detalles del pedido
                },
              ),
            );
          },
        );
      },
    );
  }

  // Helper para el color del botón del siguiente estado
  Color _getNextStatusButtonColor(String currentStatus) {
    switch (currentStatus) {
      case 'Generado':
        return Colors.orange[600]!; // Para "En cocina"
      case 'En cocina':
        return Colors.green[600]!; // Para "Listo"
      case 'Listo':
        return Colors.blue[600]!; // Para "Entregado" (o morado)
      default:
        return Colors.grey;
    }
  }

  // Helper para mostrar un icono si no hay botón de acción
  Widget _getStatusIconForAdmin(String status) {
    switch (status.toLowerCase()) {
      case 'entregado':
        return Icon(Icons.done_all, color: Colors.green);
      case 'cancelado':
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.info_outline, color: Colors.grey);
    }
  }

  Future<String?> _getNombreCliente(String cedula) async {
    if (cedula.isEmpty) return null;
    try {
      final user = await FirebaseFirestore.instance
          .collection('Usuario')
          .doc(cedula)
          .get();
      return user.data()?['nombre'] as String?;
    } catch (e) {
      debugPrint('Error fetching client name for $cedula: $e');
      return null;
    }
  }

  Widget _buildTablesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(restaurantId)
          .collection('Mesas')
          .snapshots(),
      builder: (context, mesaSnapshot) {
        if (mesaSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (mesaSnapshot.hasError) {
          return _buildEmptyState(
              icon: Icons.error_outline,
              message: 'Error al cargar mesas: ${mesaSnapshot.error}');
        }
        if (!mesaSnapshot.hasData || mesaSnapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.table_restaurant_outlined,
            message: 'No hay mesas registradas.',
          );
        }
        final mesas = mesaSnapshot.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mesas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final mesa = mesas[index];
            final mesaData = mesa.data() as Map<String, dynamic>;
            final numero = mesaData['numero'] ?? '';
            final estado = mesaData['Estado'] ?? false;

            return Card(
              elevation: 2,
              color: Colors.white,
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
                              color: estado
                                  ? Colors.red[600]
                                  : Colors.green[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: estado,
                      onChanged: (value) {
                        _showToggleTableStatusConfirmation(
                          context,
                          mesa.id,
                          numero.toString(),
                          estado,
                        );
                      },
                      activeColor: Colors.red[600],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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