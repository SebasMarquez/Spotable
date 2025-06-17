// lib/widgets/orders_footer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as orderModel;
import '../providers/user_provider.dart';
import '../widgets/orders_dialog.dart';

class OrdersFooter extends StatelessWidget {
  const OrdersFooter({Key? key}) : super(key: key);

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
            final orders = snapshot.data!;
            final activeOrders =
                orders
                    .where(
                      (order) =>
                          order.estado.toLowerCase() == 'generada' ||
                          order.estado.toLowerCase() == 'en cocina' ||
                          order.estado.toLowerCase() == 'lista',
                    )
                    .toList();
            // print('OrdersFooter StreamBuilder: Total orders: ${orders.length}, Active orders: ${activeOrders.length}');

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
                                  activeOrders.isNotEmpty
                                      ? const Color(0xFFB71C1C).withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              activeOrders.isNotEmpty
                                  ? Icons.restaurant
                                  : Icons.check_circle,
                              color:
                                  activeOrders.isNotEmpty
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
                              if (activeOrders.isNotEmpty)
                                Text(
                                  '${activeOrders.length} en preparación',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          if (orders.isNotEmpty)
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

  Stream<List<orderModel.Order>> _getUserOrders(String cedula) {
    // print('OrdersFooter _getUserOrders: Called for cedula: $cedula');
    return FirebaseFirestore.instance
        .collectionGroup('Order')
        .where('cedula', isEqualTo: cedula)
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((querySnapshot) async {
          // print('OrdersFooter _getUserOrders: Firestore query returned ${querySnapshot.docs.length} documents for cedula $cedula.');
          List<orderModel.Order> orders = [];
          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            // print('OrdersFooter _getUserOrders: Processing order doc ID: ${doc.id}, Data (first 100 chars): ${data.toString().substring(0, data.toString().length > 100 ? 100 : data.toString().length)}');

            String restauranteName = "Nombre no encontrado";
            String restauranteId = "ID no encontrado";

            final restauranteRef = doc.reference.parent.parent;

            if (restauranteRef == null) {
              // print('OrdersFooter _getUserOrders: Error - Restaurante reference (parent.parent) is null for order ${doc.id}');
            } else {
              restauranteId = restauranteRef.id;
              // print('OrdersFooter _getUserOrders: Restaurante ID for order ${doc.id} is $restauranteId');
              try {
                final restSnap =
                    await FirebaseFirestore.instance
                        .collection('Restaurante')
                        .doc(restauranteId)
                        .get();
                if (restSnap.exists) {
                  restauranteName =
                      restSnap.data()?['Nombre'] as String? ??
                      "Nombre no disponible en doc";
                  // print('OrdersFooter _getUserOrders: Restaurante name for ${doc.id} is $restauranteName');
                } else {
                  // print('OrdersFooter _getUserOrders: Restaurante document $restauranteId does not exist for order ${doc.id}.');
                  restauranteName = "Restaurante no existe en DB";
                }
              } catch (e) {
                // print('OrdersFooter _getUserOrders: EXCEPTION fetching restaurant name for ID $restauranteId (Order ID: ${doc.id}): $e');
              }
            }

            try {
              final itemsMap = data['Items'] as Map<dynamic, dynamic>?;
              final itemsList =
                  itemsMap?.entries.map((entry) {
                    dynamic rawQuantity = entry.value;
                    int quantity = 0;
                    if (rawQuantity is int) {
                      quantity = rawQuantity;
                    } else if (rawQuantity is String) {
                      quantity = int.tryParse(rawQuantity) ?? 0;
                    } else if (rawQuantity is double) {
                      quantity = rawQuantity.toInt();
                    } else {
                      // print('OrdersFooter _getUserOrders: Order ${doc.id}, Item: ${entry.key}, Unknown quantity type: $rawQuantity');
                    }
                    // print('OrdersFooter _getUserOrders: Order ${doc.id}, Item: ${entry.key}, RawQty: $rawQuantity, ParsedQty: $quantity');

                    return orderModel.OrderItem(
                      menuItemId: '',
                      name: entry.key.toString(),
                      price: 0,
                      quantity: quantity,
                    );
                  }).toList() ??
                  [];

              Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;

              orders.add(
                orderModel.Order(
                  id: doc.id,
                  restauranteId: restauranteId,
                  restauranteName: restauranteName,
                  items: itemsList,
                  total: (data['total'] as num?)?.toDouble() ?? 0.0,
                  estado: data['estado'] as String? ?? 'Generado',
                  createdAt:
                      createdAtTimestamp != null
                          ? createdAtTimestamp.toDate()
                          : DateTime.now(),
                ),
              );
            } catch (e) {
              // print('OrdersFooter _getUserOrders: EXCEPTION mapping order document ${doc.id} to Order object: $e');
            }
          }
          // print('OrdersFooter _getUserOrders: Finished processing for cedula $cedula. Total orders mapped: ${orders.length}');
          return orders;
        })
        .handleError((error, stackTrace) {
          // print('OrdersFooter _getUserOrders: ERROR in stream for cedula $cedula: $error');
          // print('OrdersFooter _getUserOrders: StackTrace for stream error: $stackTrace');
          throw error;
        });
  }

  void _showOrdersDialog(BuildContext context, List<orderModel.Order> orders) {
    showDialog(
      context: context,
      builder: (context) => OrdersDialog(orders: orders),
    );
  }
}
