import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';
import '../models/dish.dart';
import '../models/user.dart' as app_user;
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../models/order.dart' as order_model;
import 'dart:ui';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  app_user.User? _currentUser;
  List<Restaurant> _restaurants = [];
  Map<String, List<Dish>> _menus = {};
  bool _isLoading = true;
  String? _errorMessage;

  // State for UI interaction
  String? _expandedRestaurantId;
  int _selectedIndex = 0; // 0: Reservas, 1: Carrito, 2: Órdenes
  int? _activeSheetIndex;

  // Data lists
  List<Map<String, dynamic>> _myReservations = [];
  List<order_model.Order> _myOrders = [];
  
  // Cart state
  List<_CartItem> _cartItems = [];
  String? _cartRestaurantId;
  bool _isPlacingOrder = false;
  
  // Expansion and text controllers
  int? _expandedOrderIndex;
  Map<String, int?> _expandedDishIndex = {};
  Map<String, TextEditingController> _dishCommentControllers = {};

  // New state variables
  List<ShippingAddress> addresses = [];
  String? selectedAddressId;
  bool isLoadingAddresses = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dishCommentControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final user = await _firebaseService.getCurrentUserData();
      final restaurantsSnap = await FirebaseFirestore.instance.collection('restaurants').where('isActive', isEqualTo: true).get();
      final restaurants = restaurantsSnap.docs.map((doc) => Restaurant.fromMap(doc.data(), doc.id)).toList();
      
      final menus = <String, List<Dish>>{};
      for (final r in restaurants) {
        final dishesSnap = await FirebaseFirestore.instance.collection('dishes').where('restaurantId', isEqualTo: r.id).where('isAvailable', isEqualTo: true).get();
        menus[r.id] = dishesSnap.docs.map((d) => Dish.fromMap(d.data(), d.id)).toList();
      }

      List<Map<String, dynamic>> myReservations = [];
      List<order_model.Order> myOrders = [];
      if (user != null) {
        final resSnap = await FirebaseFirestore.instance.collection('reservations').where('userId', isEqualTo: user.id).orderBy('reservationTime', descending: true).get();
        myReservations = resSnap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        
        final ordersSnap = await FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: user.id).orderBy('createdAt', descending: true).get();
        myOrders = ordersSnap.docs.map((doc) => order_model.Order.fromMap(doc.data(), doc.id)).toList();
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _restaurants = restaurants;
          _menus = menus;
          _myReservations = myReservations;
          _myOrders = myOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar datos: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (_activeSheetIndex == index) {
      setState(() {
        _activeSheetIndex = null;
        _selectedIndex = -1;
      });
      return;
    }
    setState(() {
      _activeSheetIndex = index;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: Stack(
        children: [
          // Imagen de fondo con blur fuerte y overlay
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/fondo_spotable_mobile.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.black.withOpacity(0.18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildHomeContent(),
          if (_activeSheetIndex != null) _buildDraggableSheet(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Center(
        child: Image.asset('assets/images/Logo_spotable.png', height: 40),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle, color: AppColors.primary, size: 30),
          tooltip: 'Ver perfil',
          onPressed: _currentUser == null ? null : () async {
            await showDialog(
              context: context,
              builder: (context) => UserProfileDialog(
                user: _currentUser!,
                onProfileUpdated: _loadData,
              ),
            );
          },
        ),
      ],
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentUser != null) ...[
            Center(
              child: Text(
                '¡Bienvenido, ${_currentUser!.name.split(' ').first}!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Center(
            child: Text(
              'Restaurantes disponibles',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
          ),
          const SizedBox(height: 16),
          _buildRestaurantsList(),
        ],
      ),
    );
  }

  Widget _buildRestaurantsList() {
    if (_restaurants.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No hay restaurantes disponibles en este momento.'),
      ));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _restaurants.length,
      itemBuilder: (context, index) {
        final r = _restaurants[index];
        final isExpanded = _expandedRestaurantId == r.id;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                leading: r.logoUrl != null && r.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(r.logoUrl!, width: 56, height: 56, fit: BoxFit.cover),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant, size: 32, color: AppColors.primary),
                      ),
                title: Text(r.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.categories.join(', '), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 18),
                        const SizedBox(width: 4),
                        Text(r.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: r.isOpen ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r.isOpen ? 'Abierto' : 'Cerrado', style: TextStyle(color: r.isOpen ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _expandedRestaurantId = isExpanded ? null : r.id;
                  });
                },
              ),
              if (isExpanded) _buildMenuForRestaurant(r),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuForRestaurant(Restaurant restaurant) {
    final menu = _menus[restaurant.id];
    if (menu == null || menu.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Este restaurante no tiene un menú disponible."),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                if (_currentUser != null)
                  OutlinedButton.icon(
                    onPressed: () => _showReservationModal(restaurant),
                    icon: const Icon(Icons.event_available, size: 18),
                    label: const Text('Reservar'),
                     style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
              ],
            ),
          ),
          ...menu.asMap().entries.map((entry) {
            final i = entry.key;
            final dish = entry.value;
            final isDishExpanded = _expandedDishIndex[restaurant.id] == i;
            final cartQty = _cartQuantityForDish(dish.id);
            _dishCommentControllers[dish.id] ??= TextEditingController(text: _cartCommentForDish(dish.id) ?? '');

            return Card(
              elevation: 0,
              color: Colors.grey[50],
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: (dish.imageUrl != null && dish.imageUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              dish.imageUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.fastfood, color: AppColors.primary),
                          ),
                    title: Text(dish.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('\$${dish.price.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: Icon(isDishExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.primary),
                      onPressed: () => _expandDish(restaurant.id, i),
                    ),
                  ),
                  if (isDishExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dish.imageUrl != null && dish.imageUrl!.isNotEmpty)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  dish.imageUrl!,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(dish.description ?? ''),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dishCommentControllers[dish.id],
                            decoration: const InputDecoration(
                              labelText: 'Detalles para la orden (opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.comment),
                            ),
                            minLines: 1, maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: cartQty > 0 ? () => _addOrUpdateToCart(dish, restaurant, cartQty - 1, _dishCommentControllers[dish.id]?.text) : null,
                              ),
                              Text('$cartQty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _addOrUpdateToCart(dish, restaurant, cartQty + 1, _dishCommentControllers[dish.id]?.text),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () => _addOrUpdateToCart(dish, restaurant, cartQty > 0 ? cartQty : 1, _dishCommentControllers[dish.id]?.text),
                                icon: const Icon(Icons.add_shopping_cart),
                                label: Text(cartQty > 0 ? 'Actualizar' : 'Añadir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
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
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex < 0 ? 0 : _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[600],
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Badge(
            label: Text(_myReservations.where((r) => r['status'] == 'pendiente' || r['status'] == 'confirmada').length.toString()),
            isLabelVisible: _myReservations.where((r) => r['status'] == 'pendiente' || r['status'] == 'confirmada').isNotEmpty,
            child: const Icon(Icons.event),
          ),
          label: 'Reservas',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text(_cartItems.length.toString()),
            isLabelVisible: _cartItems.isNotEmpty,
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Carrito',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text(_myOrders.where((o) => o.status != 'entregado').length.toString()),
            isLabelVisible: _myOrders.where((o) => o.status != 'entregado').isNotEmpty,
            child: const Icon(Icons.receipt_long),
          ),
          label: 'Órdenes',
        ),
      ],
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      key: ValueKey(_activeSheetIndex),
      initialChildSize: 0.6,
      minChildSize: 0.2,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.2))],
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getSheetTitle(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() { _activeSheetIndex = null; _selectedIndex = -1; }),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _getSheetContent(scrollController)),
            ],
          ),
        );
      },
    );
  }

  String _getSheetTitle() {
    switch (_activeSheetIndex) {
      case 0: return 'Mis Reservaciones';
      case 1: return 'Mi Carrito';
      case 2: return 'Mis Órdenes';
      default: return '';
    }
  }

  Widget _getSheetContent(ScrollController scrollController) {
    switch (_activeSheetIndex) {
      case 0: return _buildReservationsContent(scrollController);
      case 1: return _buildCartContent(scrollController);
      case 2: return _buildOrdersContent(scrollController);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildReservationsContent(ScrollController scrollController) {
    if (_myReservations.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No tienes reservaciones registradas.')));
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _myReservations.length,
      itemBuilder: (context, index) {
        final res = _myReservations[index];
        final status = res['status'] ?? 'pendiente';
        Color cardColor;
        IconData iconData;
        switch(status) {
          case 'pendiente': cardColor = Colors.orange; iconData = Icons.schedule; break;
          case 'confirmada': cardColor = Colors.blue; iconData = Icons.check; break;
          case 'completada': cardColor = Colors.green; iconData = Icons.check_circle; break;
          case 'cancelada': cardColor = Colors.red; iconData = Icons.cancel; break;
          default: cardColor = Colors.grey; iconData = Icons.help;
        }
        return Card(
          color: cardColor.withOpacity(0.15),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(iconData, color: cardColor),
            title: Text(res['restaurantName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: cardColor)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha: ${res['reservationTime'] != null ? (res['reservationTime'] as Timestamp).toDate().toString().substring(0, 16) : ''}'),
                Text('Personas: ${res['partySize'] ?? res['people'] ?? ''}'),
                Text('Estado: $status', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            trailing: status == 'pendiente' || status == 'confirmada'
                ? IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _showCancelReservationDialog(res),
                    tooltip: 'Cancelar reservación',
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildCartContent(ScrollController scrollController) {
    if (_cartItems.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('Tu carrito está vacío.')));
    }
    return Stack(
      children: [
        ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            if (_cartRestaurantId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Restaurante: ${_restaurants.firstWhere((r) => r.id == _cartRestaurantId).name}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ..._cartItems.map((item) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.imageUrl!, width: 44, height: 44, fit: BoxFit.cover))
                      : Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fastfood, color: AppColors.primary)),
                  title: Text(item.dishName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('\$${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _changeCartQuantity(item.dishId, -1)),
                      Text('${item.quantity}'),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _changeCartQuantity(item.dishId, 1)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeFromCart(item.dishId)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                Text('\$${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ],
        ),
        Positioned(
          left: 16, right: 16, bottom: 16,
          child: ElevatedButton.icon(
            onPressed: _isPlacingOrder || _cartItems.isEmpty ? null : _placeOrder,
            icon: _isPlacingOrder ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.shopping_bag),
            label: const Text('Realizar pedido'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersContent(ScrollController scrollController) {
    if (_myOrders.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No tienes órdenes registradas.')));
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _myOrders.length,
      itemBuilder: (context, index) {
        final order = _myOrders[index];
        final isExpanded = _expandedOrderIndex == index;
        final cardColor = _getOrderStatusColor(order.status);
        return Card(
          color: cardColor.withOpacity(0.15),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              ListTile(
                leading: Icon(_getOrderStatusIcon(order.status), color: cardColor),
                title: Text(order.restaurantName, style: TextStyle(fontWeight: FontWeight.bold, color: cardColor)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fecha: ${order.createdAt.toString().substring(0, 16)}'),
                    Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
                    Text('Estado: ${order.status}', style: TextStyle(fontWeight: FontWeight.w500, color: cardColor)),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: cardColor),
                  onPressed: () => setState(() { _expandedOrderIndex = isExpanded ? null : index; }),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Row(
                        children: [
                          const Text('Tipo de orden:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text(
                            order.type == 'dine-in' ? 'Comer en restaurante' : order.type == 'pickup' ? 'Pick Up' : order.type == 'delivery' ? 'Domicilio' : order.type,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (order.type == 'dine-in' && (order.tableName != null && order.tableName!.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.table_restaurant, size: 20),
                            const SizedBox(width: 8),
                            Text('Mesa: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(order.tableName!),
                          ],
                        ),
                      ],
                      if (order.type == 'delivery' && order.shippingAddress != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.local_shipping, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((order.shippingAddress?['label'] ?? '').toString().isNotEmpty)
                                    Text(order.shippingAddress?['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(order.shippingAddress?['address'] ?? ''),
                                  if ((order.shippingAddress?['details'] ?? '').toString().isNotEmpty)
                                    Text(order.shippingAddress?['details'], style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (order.type == 'dine-in' && order.handledByEmployeeName != null && order.handledByEmployeeName!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20),
                            const SizedBox(width: 8),
                            Text('Atiende: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(order.handledByEmployeeName!),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text('Platos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      ...order.items.map((item) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${item.dishName} x${item.quantity}', style: const TextStyle(fontSize: 15))),
                              Text('\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          )),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _expandDish(String restaurantId, int index) {
    setState(() {
      _expandedDishIndex[restaurantId] = _expandedDishIndex[restaurantId] == index ? null : index;
    });
  }

  int _cartQuantityForDish(String dishId) {
    try {
      return _cartItems.firstWhere((item) => item.dishId == dishId).quantity;
    } catch (e) {
      return 0;
    }
  }

  String? _cartCommentForDish(String dishId) {
    try {
      return _cartItems.firstWhere((item) => item.dishId == dishId).comment;
    } catch (e) {
      return null;
    }
  }

  void _addOrUpdateToCart(Dish dish, Restaurant restaurant, int quantity, String? comment) {
    if (_cartRestaurantId != null && _cartRestaurantId != restaurant.id) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Carrito de otro restaurante'),
          content: const Text('Solo puedes pedir de un restaurante a la vez. ¿Deseas limpiar el carrito y añadir este plato?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                setState(() { _cartItems.clear(); _cartRestaurantId = null; });
                Navigator.of(context).pop();
                _addOrUpdateToCart(dish, restaurant, quantity, comment);
              },
              child: const Text('Limpiar y añadir'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _cartRestaurantId = restaurant.id;
      final index = _cartItems.indexWhere((item) => item.dishId == dish.id);
      if (quantity > 0) {
        if (index >= 0) {
          _cartItems[index] = _cartItems[index].copyWith(quantity: quantity, comment: comment);
        } else {
          _cartItems.add(_CartItem(
            dishId: dish.id, dishName: dish.name, quantity: quantity, unitPrice: dish.price,
            imageUrl: dish.imageUrl, restaurantId: restaurant.id, restaurantName: restaurant.name, comment: comment,
          ));
        }
      } else {
        if (index >= 0) _cartItems.removeAt(index);
      }
      if (_cartItems.isEmpty) _cartRestaurantId = null;
    });
  }

  void _removeFromCart(String dishId) {
    setState(() {
      _cartItems.removeWhere((item) => item.dishId == dishId);
      if (_cartItems.isEmpty) _cartRestaurantId = null;
    });
  }

  void _changeCartQuantity(String dishId, int delta) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.dishId == dishId);
      if (index >= 0) {
        final newQty = _cartItems[index].quantity + delta;
        if (newQty <= 0) {
          _cartItems.removeAt(index);
        } else {
          _cartItems[index] = _cartItems[index].copyWith(quantity: newQty);
        }
        if (_cartItems.isEmpty) _cartRestaurantId = null;
      }
    });
  }

  double get _cartTotal => _cartItems.fold(0, (sum, item) => sum + item.unitPrice * item.quantity);

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty || _currentUser == null || _cartRestaurantId == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String? selectedType;
        TextEditingController joinCodeController = TextEditingController();
        String? joinError;
        bool isJoining = false;
        Future<void> loadAddresses() async {
          isLoadingAddresses = true;
          final snap = await FirebaseFirestore.instance
              .collection('shipping_address')
              .where('userId', isEqualTo: _currentUser!.id)
              .get();
          addresses = snap.docs.map((d) => ShippingAddress.fromMap(d.data(), d.id)).toList();
          if (addresses.isNotEmpty) selectedAddressId = addresses.first.id;
          isLoadingAddresses = false;
        }
        void showAddAddressDialog() async {
          final controller = TextEditingController();
          final detailsController = TextEditingController();
          final labelController = TextEditingController();
          final formKey = GlobalKey<FormState>();
          final result = await showDialog<ShippingAddress>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Agregar dirección'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      validator: (v) => v == null || v.isEmpty ? 'Ingresa la dirección' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: detailsController,
                      decoration: const InputDecoration(labelText: 'Detalles (opcional)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: 'Etiqueta (opcional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(context).pop(ShippingAddress(
                      id: '',
                      userId: _currentUser!.id,
                      address: controller.text,
                      details: detailsController.text,
                      label: labelController.text,
                    ));
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          );
          if (result != null) {
            await FirebaseFirestore.instance.collection('shipping_address').add(result.toMap());
            await loadAddresses();
            // ignore: use_build_context_synchronously
            (context as Element).markNeedsBuild();
          }
        }
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('¿Cómo deseas recibir tu pedido?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: 'dine-in',
                    groupValue: selectedType,
                    onChanged: (v) => setStateDialog(() => selectedType = v),
                    title: const Text('Comer en el restaurante'),
                  ),
                  RadioListTile<String>(
                    value: 'pickup',
                    groupValue: selectedType,
                    onChanged: (v) => setStateDialog(() => selectedType = v),
                    title: const Text('Pick Up'),
                  ),
                  RadioListTile<String>(
                    value: 'delivery',
                    groupValue: selectedType,
                    onChanged: (v) async {
                      setStateDialog(() => selectedType = v);
                      setStateDialog(() => isLoadingAddresses = true);
                      await loadAddresses();
                      setStateDialog(() => isLoadingAddresses = false);
                    },
                    title: const Text('Domicilio'),
                  ),
                  if (selectedType == 'delivery') ...[
                    const SizedBox(height: 12),
                    if (isLoadingAddresses)
                      const Center(child: CircularProgressIndicator())
                    else if (addresses.isEmpty)
                      Column(
                        children: [
                          const Text('No tienes direcciones guardadas.'),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar dirección'),
                            onPressed: showAddAddressDialog,
                          ),
                        ],
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: selectedAddressId,
                        items: addresses.map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.label?.isNotEmpty == true ? a.label! : a.address),
                        )).toList(),
                        onChanged: (v) => setStateDialog(() => selectedAddressId = v),
                        decoration: const InputDecoration(labelText: 'Dirección de envío'),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar dirección'),
                          onPressed: showAddAddressDialog,
                        ),
                      ),
                    ],
                  ],
                  if (selectedType == 'dine-in') ...[
                    const SizedBox(height: 12),
                    FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('tables')
                          .where('restaurantId', isEqualTo: _cartRestaurantId)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final tables = snapshot.data!.docs;
                        final userId = _currentUser!.id;
                        final userTable = _findTableWithUser(tables, userId);
                        if (userTable != null) {
                          return Column(
                            children: [
                              const Text('Estás sentado en una mesa.'),
                              Text('Mesa: ${userTable['tableName']}'),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('No estás sentado en una mesa.'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: joinCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Código de mesa',
                                  errorText: joinError,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: isJoining
                                    ? null
                                    : () async {
                                        setStateDialog(() { isJoining = true; joinError = null; });
                                        final code = joinCodeController.text.trim();
                                        final tableDoc = _findTableWithJoinCode(tables, code);
                                        if (tableDoc == null) {
                                          setStateDialog(() { joinError = 'Código inválido'; isJoining = false; });
                                          return;
                                        }
                                        final currentUserIds = List<String>.from(tableDoc['currentUserId'] ?? []);
                                        final currentUserNames = List<String>.from(tableDoc['currentUserName'] ?? []);
                                        final capacity = tableDoc['capacity'] ?? 1;
                                        if (currentUserIds.length >= capacity) {
                                          setStateDialog(() { joinError = 'La mesa está llena.'; isJoining = false; });
                                          return;
                                        }
                                        if (currentUserIds.contains(userId)) {
                                          setStateDialog(() { joinError = 'Ya estás en esta mesa.'; isJoining = false; });
                                          return;
                                        }
                                        currentUserIds.add(userId);
                                        currentUserNames.add(_currentUser!.name);
                                        await FirebaseFirestore.instance.collection('tables').doc(tableDoc.id).update({
                                          'currentUserId': currentUserIds,
                                          'currentUserName': currentUserNames,
                                        });
                                        setStateDialog(() { isJoining = false; joinError = null; });
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Te has unido a la mesa.')));
                                      },
                                child: isJoining ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Unirse a mesa'),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedType == null
                      ? null
                      : () async {
                          if (selectedType == 'delivery' && (addresses.isEmpty || selectedAddressId == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes agregar y seleccionar una dirección de envío.'), backgroundColor: Colors.red));
                            return;
                          }
                          Navigator.of(context).pop();
                          setState(() => _isPlacingOrder = true);
                          try {
                            final restaurant = _restaurants.firstWhere((r) => r.id == _cartRestaurantId);
                            String? tableId;
                            String? tableName;
                            Map<String, dynamic>? shippingAddressMap;
                            String? handledByEmployeeId;
                            String? handledByEmployeeName;
                            if (selectedType == 'dine-in') {
                              // Buscar mesa del usuario
                              final tablesSnap = await FirebaseFirestore.instance
                                  .collection('tables')
                                  .where('restaurantId', isEqualTo: _cartRestaurantId)
                                  .get();
                              final tables = tablesSnap.docs;
                              final userId = _currentUser!.id;
                              final userTable = _findTableWithUser(tables, userId);
                              if (userTable == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes estar sentado en una mesa para pedir en el restaurante.'), backgroundColor: Colors.red));
                                setState(() => _isPlacingOrder = false);
                                return;
                              }
                              tableId = userTable.id;
                              tableName = userTable['tableName'];
                              handledByEmployeeId = userTable['assignedEmployeeId'];
                              handledByEmployeeName = userTable['assignedEmployeeName'];
                            }
                            if (selectedType == 'delivery') {
                              final selected = addresses.firstWhere((a) => a.id == selectedAddressId);
                              shippingAddressMap = selected.toMap();
                              shippingAddressMap['id'] = selected.id;
                            }
                            final orderData = {
                              'userId': _currentUser!.id, 'userName': _currentUser!.name,
                              'restaurantId': restaurant.id, 'restaurantName': restaurant.name,
                              'type': selectedType,
                              'status': 'revision',
                              'tableId': tableId,
                              'tableName': tableName,
                              'shippingAddress': shippingAddressMap,
                              'items': _cartItems.map((item) => {
                                'dishId': item.dishId, 'dishName': item.dishName, 'quantity': item.quantity,
                                'unitPrice': item.unitPrice, 'comment': item.comment
                              }).toList(),
                              'totalAmount': _cartTotal,
                              'handledByEmployeeId': handledByEmployeeId,
                              'handledByEmployeeName': handledByEmployeeName,
                              'createdAt': DateTime.now(),
                            };
                            await FirebaseFirestore.instance.collection('orders').add(orderData);
                            setState(() {
                              _cartItems.clear();
                              _cartRestaurantId = null;
                              _isPlacingOrder = false;
                              _onItemTapped(2);
                            });
                            await _loadData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Pedido realizado con éxito!'), backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al realizar pedido: $e'), backgroundColor: Colors.red));
                            }
                          } finally {
                            if (mounted) setState(() => _isPlacingOrder = false);
                          }
                        },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReservationModal(Restaurant restaurant) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ReservationForm(
        restaurant: restaurant, user: _currentUser!,
        onReservationMade: () async {
          Navigator.of(context).pop();
          await _loadData();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('¡Reservación realizada con éxito!'), backgroundColor: Colors.green[600]));
        },
      ),
    );
  }

  void _showCancelReservationDialog(Map<String, dynamic> reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reservación'),
        content: Text('¿Seguro que deseas cancelar la reservación en ${reservation['restaurantName'] ?? ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('reservations').doc(reservation['id']).update({'status': 'cancelada'});
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Reservación cancelada'), backgroundColor: Colors.orange[700]));
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'revision': return Colors.blueGrey;
      case 'en_cocina': return Colors.orange;
      case 'listo': return Colors.green;
      case 'entregado': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status) {
      case 'revision': return Icons.hourglass_top;
      case 'en_cocina': return Icons.kitchen;
      case 'listo': return Icons.check_circle_outline;
      case 'entregado': return Icons.done_all;
      default: return Icons.help_outline;
    }
  }

  // Helper para buscar un documento o null
  QueryDocumentSnapshot<Map<String, dynamic>>? _findTableWithUser(List<QueryDocumentSnapshot<Map<String, dynamic>>> tables, String userId) {
    for (final t in tables) {
      final ids = t['currentUserId'];
      if (ids is List && ids.contains(userId)) return t;
    }
    return null;
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _findTableWithJoinCode(List<QueryDocumentSnapshot<Map<String, dynamic>>> tables, String code) {
    for (final t in tables) {
      if (t['joinCode'] == code) return t;
    }
    return null;
  }
}

class _ReservationForm extends StatefulWidget {
  final Restaurant restaurant;
  final app_user.User user;
  final VoidCallback onReservationMade;
  const _ReservationForm({required this.restaurant, required this.user, required this.onReservationMade});

  @override
  State<_ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<_ReservationForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDateTime;
  int _people = 2;
  String? _comments;
  bool _isLoading = false;
  late TextEditingController _dateTimeController;
  List<Map<String, dynamic>> _availableTables = [];
  String? _selectedTableId;
  bool _isLoadingTables = false;

  @override
  void initState() {
    super.initState();
    _dateTimeController = TextEditingController();
  }

  @override
  void dispose() {
    _dateTimeController.dispose();
    super.dispose();
  }

  void _updateDateTimeController() {
    _dateTimeController.text = _selectedDateTime != null ? '${_selectedDateTime!.toLocal()}'.substring(0, 16) : '';
  }

  Future<void> _loadAvailableTables() async {
    if (_selectedDateTime == null) return;
    setState(() { _isLoadingTables = true; _availableTables = []; _selectedTableId = null; });
    try {
      final tablesSnap = await FirebaseFirestore.instance.collection('tables').where('restaurantId', isEqualTo: widget.restaurant.id).get();
      final allTables = tablesSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      
      final startOfDay = DateTime(_selectedDateTime!.year, _selectedDateTime!.month, _selectedDateTime!.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final reservationsSnap = await FirebaseFirestore.instance.collection('reservations')
          .where('restaurantId', isEqualTo: widget.restaurant.id)
          .where('reservationTime', isGreaterThanOrEqualTo: startOfDay)
          .where('reservationTime', isLessThan: endOfDay)
          .get();
      final existingReservations = reservationsSnap.docs.map((doc) => doc.data()).toList();
      
      final availableTables = <Map<String, dynamic>>[];
      for (final table in allTables) {
        if ((table['capacity'] as int? ?? 0) >= _people) {
          final isAvailable = _isTableAvailableForTime(table['id'] as String, _selectedDateTime!, existingReservations);
          availableTables.add({
            ...table,
            'available': isAvailable,
            'reason': isAvailable ? null : 'Horario no disponible',
          });
        }
      }
      setState(() { _availableTables = availableTables; _isLoadingTables = false; });
    } catch (e) {
      if(mounted) {
        setState(() => _isLoadingTables = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar mesas: $e'), backgroundColor: Colors.red[600]));
      }
    }
  }

  bool _isTableAvailableForTime(String tableId, DateTime requestedTime, List<Map<String, dynamic>> existingReservations) {
    const conflictWindow = Duration(hours: 1, minutes: 59);
    final requestedStart = requestedTime;
    final requestedEnd = requestedTime.add(conflictWindow);

    for (final reservation in existingReservations) {
      if (reservation['tableId'] != tableId) continue;
      final status = reservation['status'] ?? 'pendiente';
      if (status == 'cancelada') continue;
      
      final existingTime = (reservation['reservationTime'] as Timestamp).toDate();
      final existingStart = existingTime;
      final existingEnd = existingTime.add(conflictWindow);

      if (requestedStart.isBefore(existingEnd) && requestedEnd.isAfter(existingStart)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reservar en ${widget.restaurant.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Fecha y hora', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                readOnly: true, controller: _dateTimeController,
                onTap: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 60)));
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
                    if (pickedTime != null) {
                      setState(() {
                        _selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                        _updateDateTimeController();
                        _selectedTableId = null;
                      });
                      await _loadAvailableTables();
                    }
                  }
                },
                validator: (value) => _selectedDateTime == null ? 'Selecciona fecha y hora' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '2',
                decoration: const InputDecoration(labelText: 'Número de personas', border: OutlineInputBorder(), prefixIcon: Icon(Icons.people)),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() { _people = int.tryParse(value) ?? 2; _selectedTableId = null; });
                  if (_selectedDateTime != null) _loadAvailableTables();
                },
                validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1 ? 'Ingresa un número válido' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedDateTime != null) ...[
                Text('Mesa disponible', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                if (_isLoadingTables) const Center(child: CircularProgressIndicator())
                else if (_availableTables.where((t) => t['available'] == true).isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange[200]!)),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(child: Text('No hay mesas disponibles para $_people personas en este horario.', style: TextStyle(color: Colors.orange[800]))),
                      ],
                    ),
                  )
                else
                  ..._availableTables.map((table) {
                    final isAvailable = table['available'] == true;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: RadioListTile<String>(
                        title: Text('Mesa ${table['tableName']}'),
                        subtitle: Text('Capacidad: ${table['capacity']} personas' + (!isAvailable ? ' (${table['reason']})' : '')),
                        value: table['id'],
                        groupValue: _selectedTableId,
                        onChanged: isAvailable ? (value) => setState(() => _selectedTableId = value) : null,
                        activeColor: AppColors.primary,
                        secondary: !isAvailable ? const Icon(Icons.block, color: Colors.red) : null,
                      ),
                    );
                  }),
                const SizedBox(height: 16),
              ],
              TextFormField(
                decoration: const InputDecoration(labelText: 'Comentarios (opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.comment)),
                maxLines: 2,
                onChanged: (value) => _comments = value,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || _selectedTableId == null) ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isLoading = true);
                    try {
                      await FirebaseFirestore.instance.collection('reservations').add({
                        'userId': widget.user.id, 'userName': widget.user.name,
                        'restaurantId': widget.restaurant.id, 'restaurantName': widget.restaurant.name,
                        'tableId': _selectedTableId, 'reservationTime': _selectedDateTime,
                        'partySize': _people, 'comments': _comments,
                        'createdAt': DateTime.now(), 'status': 'pendiente',
                      });
                      widget.onReservationMade();
                    } catch (e) {
                      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reservar: $e'), backgroundColor: Colors.red[600]));
                    } finally {
                      if(mounted) setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirmar reserva', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserProfileDialog extends StatefulWidget {
  final app_user.User user;
  final VoidCallback onProfileUpdated;
  const UserProfileDialog({required this.user, required this.onProfileUpdated});

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _cedulaController;
  late TextEditingController _telefonoController;
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;
  List<ShippingAddress> _addresses = [];
  bool _isLoadingAddresses = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _cedulaController = TextEditingController(text: widget.user.personalId ?? '');
    _telefonoController = TextEditingController(text: widget.user.phone ?? '');
    _loadAddresses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoadingAddresses = true);
    final snap = await FirebaseFirestore.instance
        .collection('shipping_address')
        .where('userId', isEqualTo: widget.user.id)
        .get();
    setState(() {
      _addresses = snap.docs.map((d) => ShippingAddress.fromMap(d.data(), d.id)).toList();
      _isLoadingAddresses = false;
    });
  }

  Future<void> _addOrEditAddress({ShippingAddress? address}) async {
    final controller = TextEditingController(text: address?.address ?? '');
    final detailsController = TextEditingController(text: address?.details ?? '');
    final labelController = TextEditingController(text: address?.label ?? '');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<ShippingAddress>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(address == null ? 'Agregar dirección' : 'Editar dirección'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (v) => v == null || v.isEmpty ? 'Ingresa la dirección' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Detalles (opcional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Etiqueta (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context).pop(ShippingAddress(
                id: address?.id ?? '',
                userId: widget.user.id,
                address: controller.text,
                details: detailsController.text,
                label: labelController.text,
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null) {
      if (address == null) {
        await FirebaseFirestore.instance.collection('shipping_address').add(result.toMap());
      } else {
        await FirebaseFirestore.instance.collection('shipping_address').doc(address.id).update(result.toMap());
      }
      await _loadAddresses();
    }
  }

  Future<void> _deleteAddress(ShippingAddress address) async {
    await FirebaseFirestore.instance.collection('shipping_address').doc(address.id).delete();
    await _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Perfil de usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(labelText: 'Cédula'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Ingresa tu cédula' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Ingresa tu teléfono' : null,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Direcciones de envío', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              const SizedBox(height: 6),
              if (_isLoadingAddresses)
                const Center(child: CircularProgressIndicator())
              else if (_addresses.isEmpty)
                const Text('No tienes direcciones guardadas.')
              else
                ..._addresses.map((a) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(a.label?.isNotEmpty == true ? a.label! : a.address),
                    subtitle: Text(a.details?.isNotEmpty == true ? a.details! : a.address),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEditAddress(address: a)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteAddress(a)),
                      ],
                    ),
                  ),
                )),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar dirección'),
                  onPressed: () => _addOrEditAddress(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isLoading = true);
                    String? errorMsg;
                    try {
                      final auth = FirebaseAuth.instance;
                      final currentUser = auth.currentUser;
                      if(currentUser == null) throw Exception("No hay usuario autenticado.");

                      final emailChanged = _emailController.text != widget.user.email;
                      final passwordChanged = _newPasswordController.text.isNotEmpty;

                      if (emailChanged || passwordChanged) {
                        if(_passwordController.text.isEmpty) throw Exception("Se requiere contraseña actual para cambiar correo o contraseña.");
                        final cred = EmailAuthProvider.credential(email: widget.user.email, password: _passwordController.text);
                        await currentUser.reauthenticateWithCredential(cred);
                      }
                      if (emailChanged) await currentUser.updateEmail(_emailController.text);
                      if (passwordChanged) await currentUser.updatePassword(_newPasswordController.text);
                      
                      await FirebaseFirestore.instance.collection('users').doc(widget.user.id).update({
                        'name': _nameController.text, 'email': _emailController.text,
                        'personalId': _cedulaController.text, 'phone': _telefonoController.text,
                        'updatedAt': DateTime.now(),
                      });
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        widget.onProfileUpdated();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado'), backgroundColor: Colors.green));
                      }
                    } on FirebaseAuthException catch (e) {
                      errorMsg = e.message;
                    } catch (e) {
                      errorMsg = 'Error inesperado: $e';
                    } finally {
                      if (errorMsg != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
                      }
                      if(mounted) setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(
          onPressed: _isLoading ? null : () async {
            final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
              title: const Text('Confirmar cierre de sesión'), content: const Text('¿Seguro que deseas cerrar sesión?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sí, cerrar sesión')),
              ],
            ));
            if (confirmed == true) {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
              }
            }
          },
          child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

class _CartItem {
  final String dishId;
  final String dishName;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;
  final String restaurantId;
  final String restaurantName;
  final String? comment;

  _CartItem({
    required this.dishId,
    required this.dishName,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
    required this.restaurantId,
    required this.restaurantName,
    this.comment,
  });

  _CartItem copyWith({int? quantity, String? comment}) => _CartItem(
        dishId: dishId,
        dishName: dishName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
        imageUrl: imageUrl,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        comment: comment ?? this.comment,
      );
}

class ShippingAddress {
  final String id;
  final String userId;
  final String address;
  final String? details;
  final String? label;
  ShippingAddress({required this.id, required this.userId, required this.address, this.details, this.label});
  factory ShippingAddress.fromMap(Map<String, dynamic> map, String id) => ShippingAddress(
    id: id,
    userId: map['userId'],
    address: map['address'],
    details: map['details'],
    label: map['label'],
  );
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'address': address,
    'details': details,
    'label': label,
  };
}
