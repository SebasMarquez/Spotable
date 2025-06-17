// lib/widgets/orders_footer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart' as orderModel;
import '../providers/user_provider.dart';
import './orders_dialog.dart'; // Asegúrate que la importación es correcta

class OrdersFooter extends StatelessWidget {
  const OrdersFooter({super.key});

  Stream<List<orderModel.Order>> _getUserOrders(String cedula) {
    print('OrdersFooter _getUserOrders: Called for cedula: $cedula');
    return FirebaseFirestore.instance
        .collectionGroup('Order')
        .where('cedulaCliente', isEqualTo: cedula) // Cambiado a cedulaCliente
        .orderBy('createdAt', descending: true) // Reinstated
        .snapshots()
        .asyncMap((querySnapshot) async {
          print(
            'OrdersFooter _getUserOrders: Firestore query returned ${querySnapshot.docs.length} documents for cedula $cedula.',
          );
          List<orderModel.Order> orders = [];
          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            print(
              'OrdersFooter _getUserOrders: Processing order doc ID: ${doc.id}, Cedula (from doc field cedulaCliente): ${data['cedulaCliente']}, Estado: ${data['estado']}',
            );

            // restauranteName and restauranteId are now directly part of the Order object via fromFirestore
            // No need to manually extract them here if Order.fromFirestore handles it.

            try {
              orders.add(orderModel.Order.fromFirestore(doc));
            } catch (e) {
              print(
                "OrdersFooter _getUserOrders: Error converting Firestore doc to Order object for doc ${doc.id}: $e. Data: $data",
              );
            }
          }
          print(
            'OrdersFooter _getUserOrders: Processed ${orders.length} orders for cedula $cedula.',
          );
          // Filter for active states after processing all orders from the snapshot
          return orders
              .where(
                (order) =>
                    ['Generado', 'En cocina', 'Listo'].contains(order.estado),
              )
              .toList();
        })
        .handleError((error) {
          print('OrdersFooter _getUserOrders: Error in stream: $error');
          return <orderModel.Order>[];
        });
  }

  @override
  Widget build(BuildContext context) {
    // print("OrdersFooter: build method called");
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // print('OrdersFooter Consumer: Building. User cedula: ${userProvider.user?.cedula}');
        if (userProvider.user == null || userProvider.user!.cedula.isEmpty) {
          // print('OrdersFooter Consumer: User is null or cedula is empty. Returning SizedBox.shrink().');
          return const SizedBox.shrink();
        }
        // print('OrdersFooter Consumer: User authenticated (${userProvider.user!.cedula}). Setting up StreamBuilder.');

        return StreamBuilder<List<orderModel.Order>>(
          stream: _getUserOrders(userProvider.user!.cedula),
          builder: (context, snapshot) {
            // print('OrdersFooter StreamBuilder: ConnectionState: ${snapshot.connectionState}');
            // print('OrdersFooter StreamBuilder: HasData: ${snapshot.hasData}');
            // print('OrdersFooter StreamBuilder: HasError: ${snapshot.hasError}');

            if (snapshot.hasError) {
              // print('OrdersFooter StreamBuilder: ERROR: ${snapshot.error}');
              // print('OrdersFooter StreamBuilder: StackTrace: ${snapshot.stackTrace}');
              print(
                'OrdersFooter StreamBuilder: DETAILED ERROR: ${snapshot.error}',
              );
              print(
                'OrdersFooter StreamBuilder: DETAILED STACKTRACE: ${snapshot.stackTrace}',
              );
              // Return a visible error message instead of SizedBox.shrink()
              return Container(
                height: 50,
                color: Colors.pink[200],
                child: Center(
                  child: Text(
                    'Error en Stream: ${snapshot.error}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              // print('OrdersFooter StreamBuilder: Waiting for data.');
              return Container(
                height: 50,
                color: Colors.yellow[600],
                child: Center(
                  child: Text(
                    'Esperando datos...',
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // print('OrdersFooter StreamBuilder: No data in snapshot or data is empty.');
              return Container(
                height: 50,
                color: Colors.orange[600],
                child: Center(
                  child: Text(
                    'Sin pedidos',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              );
            }

            // print('OrdersFooter StreamBuilder: Data received. Orders count: ${snapshot.data!.length}. Proceeding to build footer UI.');
            final orders =
                snapshot
                    .data!; // These are already the active orders filtered by the stream

            // The 'activeOrders' filtering here was redundant and potentially incorrect
            // as 'orders' from snapshot.data! is already filtered by _getUserOrders
            // to include only states: ['Generado', 'En cocina', 'Listo'].
            // We will use 'orders' directly for active order logic.
            // print('OrdersFooter StreamBuilder: Total orders from stream (should be active): ${orders.length}');

            return Container(
              margin: const EdgeInsets.all(16),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(25),
                shadowColor: Colors.black26,
                child: InkWell(
                  onTap: () => _showOrdersDialog(context, orders),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    height: 50, // Changed from 200 back to 50
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: const Color(0xFFB71C1C).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  orders
                                          .isNotEmpty // Use orders directly
                                      ? const Color(0xFFB71C1C).withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              orders
                                      .isNotEmpty // Use orders directly
                                  ? Icons.restaurant
                                  : Icons.check_circle,
                              color:
                                  orders
                                          .isNotEmpty // Use orders directly
                                      ? const Color(0xFFB71C1C)
                                      : Colors.green,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mis Pedidos',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              if (orders.isNotEmpty) // Use orders directly
                                Text(
                                  '${orders.length} en preparación', // Use orders.length
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          if (orders
                              .isNotEmpty) // This badge shows the count of active orders
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB71C1C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${orders.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrdersDialog(BuildContext context, List<orderModel.Order> orders) {
    showDialog(
      context: context,
      builder: (context) => OrdersDialog(orders: orders),
    );
  }
}
