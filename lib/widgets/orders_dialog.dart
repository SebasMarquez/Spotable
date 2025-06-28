// lib/widgets/orders_dialog.dart
import 'package:flutter/material.dart';
import '../models/order.dart' as orderModel;
import '../models/menu_item.dart'; // No se usa directamente aquí, pero es común.
import '../services/firebase_service.dart'; // Importar FirebaseService
import '../screens/cart_screen.dart'; // Importar DeliveryType, ya que OrdersDialog no tiene un contexto directo para ello.


class OrdersDialog extends StatelessWidget {
  final List<orderModel.Order> orders;

  const OrdersDialog({Key? key, required this.orders}) : super(key: key);

  // NUEVO: Método para mostrar el diálogo de cambio de tipo de pedido
  void _showChangeDeliveryTypeDialog(BuildContext context, orderModel.Order order) {
    TextEditingController addressController = TextEditingController(text: order.deliveryAddress);
    TextEditingController tableIdController = TextEditingController(text: order.idMesa);
    DeliveryType? selectedDeliveryType = order.deliveryType == 'delivery' ? DeliveryType.delivery : DeliveryType.dineIn;
    
    // Lista de estados donde NO se permite cambiar de 'delivery' a 'dineIn'
    final List<String> noChangeToDineInStates = ['Listo', 'Entregado', 'Cancelado'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Usamos StatefulBuilder para que el diálogo se pueda reconstruir internamente
          builder: (BuildContext context, StateSetter setState) {
            bool canChangeToDineIn = !(order.estado == 'Listo' || order.estado == 'Entregado' || order.estado == 'Cancelado');
            
            return AlertDialog(
              title: const Text('Cambiar Tipo de Pedido'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<DeliveryType>(
                      title: const Text('Para comer en el local'),
                      value: DeliveryType.dineIn,
                      groupValue: selectedDeliveryType,
                      onChanged: canChangeToDineIn || order.deliveryType != 'delivery' // Permite si siempre es dineIn o si se puede cambiar
                          ? (DeliveryType? value) {
                              setState(() {
                                selectedDeliveryType = value;
                              });
                            }
                          : null, // Deshabilitado si no se puede cambiar a dineIn
                      activeColor: Colors.blue,
                    ),
                    if (!canChangeToDineIn && selectedDeliveryType == DeliveryType.dineIn && order.deliveryType == 'delivery')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          'No se puede cambiar a "comer en local" porque el pedido está "${order.estado}".',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    RadioListTile<DeliveryType>(
                      title: const Text('A domicilio'),
                      value: DeliveryType.delivery,
                      groupValue: selectedDeliveryType,
                      onChanged: (DeliveryType? value) {
                        setState(() {
                          selectedDeliveryType = value;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                    if (selectedDeliveryType == DeliveryType.delivery) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección de entrega',
                          hintText: 'Ej: Calle Falsa 123, Ciudad',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (selectedDeliveryType == DeliveryType.delivery && (value == null || value.isEmpty)) {
                            return 'La dirección es obligatoria para pedidos a domicilio.';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (selectedDeliveryType == DeliveryType.dineIn) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: tableIdController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Mesa',
                          hintText: 'Ej: 5',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (selectedDeliveryType == DeliveryType.dineIn && (value == null || value.isEmpty)) {
                            return 'El número de mesa es obligatorio para pedidos en local.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDeliveryType == DeliveryType.delivery && addressController.text.isEmpty) {
                      // Simple validation for address
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Por favor, ingresa una dirección de entrega.')),
                      );
                      return;
                    }
                     if (selectedDeliveryType == DeliveryType.dineIn && tableIdController.text.isEmpty) {
                      // Simple validation for table ID
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Por favor, ingresa un número de mesa.')),
                      );
                      return;
                    }

                    // Regla de negocio: Si se intenta cambiar de 'delivery' a 'dineIn' y el estado no lo permite
                    if (order.deliveryType == 'delivery' && selectedDeliveryType == DeliveryType.dineIn && noChangeToDineInStates.contains(order.estado)) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('No se puede cambiar a "comer en local" si el pedido está "${order.estado}".')),
                        );
                        return;
                    }


                    try {
                      await FirebaseService.updateOrderDeliveryType(
                        restaurantId: order.restauranteId,
                        orderId: order.id,
                        newDeliveryType: selectedDeliveryType!.name,
                        newDeliveryAddress: selectedDeliveryType == DeliveryType.delivery ? addressController.text : null,
                        newTableId: selectedDeliveryType == DeliveryType.dineIn ? tableIdController.text : null,
                      );
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Tipo de pedido actualizado correctamente')),
                        );
                        Navigator.of(dialogContext).pop(); // Cerrar el diálogo al éxito
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Error al actualizar tipo de pedido: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth:
              MediaQuery.of(context).size.width *
              0.95, // Changed from 0.9 to 0.95
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFB71C1C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Mis Pedidos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Lista de pedidos
            Flexible(
              child:
                  orders.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tienes pedidos aún',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _buildOrderCard(
                            context, // Pasar el contexto para el diálogo
                            order,
                            index == orders.length - 1,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // Modificar _buildOrderCard para aceptar BuildContext y el nuevo botón
  Widget _buildOrderCard(BuildContext context, orderModel.Order order, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(order.estado).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del pedido
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt,
                        color: _getStatusColor(order.estado),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pedido ${order.idMesa ?? 'N/A'}', // Ajusta para mostrar N/A si no hay mesa
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(order.estado),
              ],
            ),

            const SizedBox(height: 12),

            // Tipo de entrega y dirección/mesa
            Row(
              children: [
                Icon(order.deliveryType == 'delivery' ? Icons.delivery_dining : Icons.restaurant_menu,
                     size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded( // Added Expanded here
                  child: Text(
                    order.deliveryType == 'delivery'
                        ? 'A domicilio' + (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty ? ': ${order.deliveryAddress}' : '')
                        : 'En local' + (order.idMesa != null && order.idMesa!.isNotEmpty ? ': Mesa ${order.idMesa}' : ''),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis, // Added overflow
                  ),
                ),
                 // NUEVO: Botón para cambiar el tipo de pedido
                if (order.estado != 'Entregado' && order.estado != 'Cancelado')
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _showChangeDeliveryTypeDialog(context, order),
                    tooltip: 'Cambiar tipo de pedido',
                  ),
              ],
            ),


            const SizedBox(height: 12),

            // Fecha y hora
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  _formatDateTime(order.createdAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Items del pedido
            ...order.items.map((item) => _buildOrderItem(item)),

            const SizedBox(height: 12),

            // Total
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(orderModel.OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${item.quantity}x ${item.name}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            ),
          ),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String estado) {
    final color = _getStatusColor(estado);
    final icon = _getStatusIcon(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            estado,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'generado':
        return Colors.blue;
      case 'en cocina':
        return Colors.orange;
      case 'listo':
        return Colors.green;
      case 'entregado':
        return Colors.purple; // Usado morado para 'Entregado' para distinguirlo
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'generado':
        return Icons.schedule;
      case 'en cocina':
        return Icons.kitchen_outlined;
      case 'listo':
        return Icons.check_circle_outline;
      case 'entregado':
        return Icons.done_all;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Hace un momento';
    }
  }
}