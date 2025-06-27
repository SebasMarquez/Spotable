import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as app_order;
import '../models/order.dart' show OrderItem; // Import OrderItem directly
import '../screens/cart_screen.dart'; // Importar para DeliveryType
import '../providers/user_provider.dart';
import 'firebase_service.dart';

class CartService extends ChangeNotifier {
  List<CartItem> _cartItems = [];
  bool _isPlacingOrder = false;
  String? _currentRestaurantId;

  List<CartItem> get cartItems => _cartItems;
  bool get isPlacingOrder => _isPlacingOrder;
  String? get currentRestaurantId => _currentRestaurantId;

  /// Verificar si hay un restaurante establecido
  bool get hasRestaurantSet => _currentRestaurantId != null;

  int get totalItems {
    return _cartItems.fold(0, (total, item) => total + item.quantity);
  }

  double get totalPrice {
    return _cartItems.fold(0.0, (total, item) => total + item.totalPrice);
  }

  /// Establecer el restaurante actual (llamar al inicio de la sesión)
  void setCurrentRestaurant(String restaurantId) {
    _currentRestaurantId = restaurantId;
    print('🏪 Restaurante actual establecido: $restaurantId');
  }

  void addToCart(MenuItem menuItem, int quantity) {
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    if (existingItemIndex >= 0) {
      _cartItems[existingItemIndex].quantity += quantity;
    } else {
      _cartItems.add(CartItem(menuItem: menuItem, quantity: quantity));
    }

    notifyListeners();
  }

  // Cambio: usar String en lugar de int para el ID del menuItem
  void removeFromCart(String menuItemId) {
    _cartItems.removeWhere((item) => item.menuItem.id == menuItemId);
    notifyListeners();
  }

  // Cambio: usar String en lugar de int para el ID del menuItem
  void updateQuantity(String menuItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(menuItemId);
      return;
    }

    final itemIndex = _cartItems.indexWhere(
      (item) => item.menuItem.id == menuItemId,
    );

    if (itemIndex >= 0) {
      _cartItems[itemIndex].quantity = newQuantity;
      notifyListeners();
    }
  }

  /// Incrementar cantidad de un item específico
  // Cambio: usar String en lugar de int para el ID del menuItem
  void incrementItem(String menuItemId) {
    final itemIndex = _cartItems.indexWhere(
      (item) => item.menuItem.id == menuItemId,
    );

    if (itemIndex >= 0) {
      _cartItems[itemIndex].quantity++;
      notifyListeners();
    }
  }

  /// Decrementar cantidad de un item específico
  // Cambio: usar String en lugar de int para el ID del menuItem
  void decrementItem(String menuItemId) {
    final itemIndex = _cartItems.indexWhere(
      (item) => item.menuItem.id == menuItemId,
    );

    if (itemIndex >= 0) {
      if (_cartItems[itemIndex].quantity > 1) {
        _cartItems[itemIndex].quantity--;
        notifyListeners();
      } else {
        // Si la cantidad es 1, eliminar el item completamente
        removeFromCart(menuItemId);
      }
    }
  }

  /// Obtener la cantidad de un item específico
  // Cambio: usar String en lugar de int para el ID del menuItem y crear MenuItem con todos los parámetros requeridos
  int getItemQuantity(String menuItemId) {
    final item = _cartItems.firstWhere(
      (item) => item.menuItem.id == menuItemId,
      orElse:
          () => CartItem(
            menuItem: MenuItem(
              id: 'not-found',
              name: '',
              price: 0,
              image: '', // Parámetro requerido agregado
              description: '', // Parámetro requerido agregado
              category: '', // Parámetro requerido agregado
            ),
            quantity: 0,
          ),
    );
    return item.quantity;
  }

  /// Verificar si un item está en el carrito
  // Cambio: usar String en lugar de int para el ID del menuItem
  bool isItemInCart(String menuItemId) {
    return _cartItems.any((item) => item.menuItem.id == menuItemId);
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  /// Crear orden básica (requiere que se haya establecido el restaurante)
  Future<bool> placeOrder({String? customerName, String? customerPhone}) async {
    if (_currentRestaurantId == null) {
      print('❌ Error: No se ha establecido el ID del restaurante');
      return false;
    }

    if (_cartItems.isEmpty) {
      print('❌ Error: El carrito está vacío');
      return false;
    }

    _isPlacingOrder = true;
    notifyListeners();

    try {
      // Crear el mapa de items según tu estructura de Firebase
      Map<String, dynamic> itemsMap = {};
      for (var cartItem in _cartItems) {
        itemsMap[cartItem.menuItem.name] = cartItem.quantity;
      }

      // Crear la orden con la estructura específica de tu Firebase
      Map<String, dynamic> orderData = {
        'Items': itemsMap,
        'total': totalPrice,
        //'createdAt': FieldValue.serverTimestamp(), // Agregar timestamp para ordenamiento
      };

      // Guardar en Firebase usando el nuevo método
      final orderId = await FirebaseService.createOrder(
        _currentRestaurantId!,
        orderData,
      );

      print('✅ Orden creada exitosamente con ID: $orderId');
      print('🏪 Restaurante: $_currentRestaurantId');
      print('📋 Items: ${itemsMap.toString()}');
      print('💰 Total: \$${totalPrice.toStringAsFixed(2)}');
      print('🕒 Timestamp: ${DateTime.now().toIso8601String()}');

      // Limpiar el carrito después de crear la orden exitosamente
      clearCart();

      _isPlacingOrder = false;
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Error al crear la orden: $e');
      _isPlacingOrder = false;
      notifyListeners();
      return false;
    }
  }

  /// Crear orden simple (solo items y total)
  Future<bool> placeOrderSimple(
    BuildContext context, {
    required DeliveryType deliveryType,
    String? deliveryAddress,
  }) async {
    // Obtener UserProvider para acceder a los datos del usuario
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.user;

    if (userData == null) {
      print(
        '❌ Error: Datos de usuario no disponibles para realizar el pedido.',
      );
      return false;
    }

    if (_cartItems.isEmpty) {
      return false;
    }

    _isPlacingOrder = true;
    notifyListeners();

    try {
      // Obtener la reserva activa más reciente del usuario
      final activeReservationSnapshot =
          await FirebaseFirestore.instance
              .collection('Usuario')
              .doc(userData.cedula)
              .collection('ReservasActivas')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

      String? idMesa;
      String? idRestaurante;
      String? nombreRestaurante;

      if (activeReservationSnapshot.docs.isNotEmpty) {
        final reservationData = activeReservationSnapshot.docs.first.data();
        idMesa = reservationData['id_mesa'] as String?;
        idRestaurante = reservationData['id_restaurante'] as String?;
        nombreRestaurante = reservationData['nombre_restaurante'] as String?;
        print(
          'ℹ️ Reserva activa encontrada: Mesa $idMesa, Restaurante $idRestaurante ($nombreRestaurante)',
        );
      } else {
        print('ℹ️ No se encontraron reservas activas para el usuario.');
        if (_currentRestaurantId != null) {
          idRestaurante = _currentRestaurantId;
          // Attempt to get restaurant name if only ID is available from _currentRestaurantId
          try {
            final restDoc =
                await FirebaseFirestore.instance
                    .collection('Restaurante')
                    .doc(_currentRestaurantId!)
                    .get();
            nombreRestaurante =
                restDoc.data()?['nombre'] ??
                'Restaurante (ID: $_currentRestaurantId)';
          } catch (e) {
            print(
              'Error fetching restaurant name for $_currentRestaurantId: $e',
            );
            nombreRestaurante = 'Restaurante (ID: $_currentRestaurantId)';
          }
          print(
            'ℹ️ Usando _currentRestaurantId: $idRestaurante ($nombreRestaurante) para el pedido.',
          );
        }
      }

      if (idRestaurante == null || idRestaurante.isEmpty) {
        print(
          '❌ Error: ID del restaurante es desconocido. No se puede crear el pedido.',
        );
        _isPlacingOrder = false;
        notifyListeners();
        return false;
      }
      nombreRestaurante ??= 'Restaurante (ID: $idRestaurante)';

      final orderItems =
          _cartItems.map((cartItem) {
            if (cartItem.menuItem.id == null) {
              print(
                'Error: menuItem.id es nulo para ${cartItem.menuItem.name}',
              );
              throw Exception(
                'ID de menuItem nulo durante la creación del pedido.',
              );
            }
            return OrderItem(
              menuItemId: cartItem.menuItem.id!,
              name: cartItem.menuItem.name,
              quantity: cartItem.quantity,
              price: cartItem.menuItem.price,
              // notes field removed
            );
          }).toList();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final customOrderId =
          idMesa != null && idMesa.isNotEmpty
              ? '${idRestaurante}_${idMesa}_$timestamp'
              : '${idRestaurante}_${userData.cedula}_$timestamp';

      final order = app_order.Order(
        id: customOrderId,
        items: orderItems,
        total: totalPrice, // Make sure totalPrice is calculated correctly
        restauranteId: idRestaurante,
        restauranteName: nombreRestaurante,
        estado: 'Generado', // Initial state set to "Generado"
        createdAt: DateTime.now(),
        cedulaCliente: userData.cedula, // Correctly assigning cedulaCliente
        deliveryType: deliveryType.name, // Asignar directamente en el modelo
        deliveryAddress: deliveryAddress, // Asignar directamente en el modelo
      );

      final orderData = order.toMap();
      if (idMesa != null) {
        orderData['idMesa'] = idMesa;
      }

      print(
        'DEBUG CartService: Preparando para guardar pedido con ID: $customOrderId',
      );
      print('DEBUG CartService: Datos del pedido a guardar: $orderData');
      print(
        'DEBUG CartService: Cedula en pedido (del modelo): ${order.cedulaCliente}',
      );
      print('DEBUG CartService: Estado en pedido: ${order.estado}');
      print(
        'DEBUG CartService: Restaurante ID en pedido: ${order.restauranteId}',
      );
      if (idMesa != null) {
        print(
          'DEBUG CartService: ID Mesa (añadido al mapa): ${orderData['idMesa']}',
        );
      }

      await FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(idRestaurante)
          .collection('Order')
          .doc(customOrderId)
          .set(orderData);

      print('✅ Orden simple creada exitosamente con ID: $customOrderId');
      print('👤 Cliente: ${userData.nombre} (Cédula: ${userData.cedula})');
      print(
        '🍽️ Mesa: $idMesa en Restaurante: $nombreRestaurante ($idRestaurante)',
      );

      clearCart();
      _isPlacingOrder = false;
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Error al crear la orden simple: $e');
      _isPlacingOrder = false;
      notifyListeners();
      return false;
    }
  }

  /// Crear orden especificando directamente el restaurante (útil para casos especiales)
  Future<bool> placeOrderForRestaurant({
    required String restaurantId,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    if (_cartItems.isEmpty) {
      print('❌ Error: El carrito está vacío');
      return false;
    }

    _isPlacingOrder = true;
    notifyListeners();

    try {
      // Crear el mapa de items según tu estructura de Firebase
      Map<String, dynamic> itemsMap = {};
      for (var cartItem in _cartItems) {
        itemsMap[cartItem.menuItem.name] = cartItem.quantity;
      }

      // Crear la orden con la estructura específica de tu Firebase
      Map<String, dynamic> orderData = {
        'Items': itemsMap,
        'total': totalPrice,
        //'createdAt': FieldValue.serverTimestamp(),
        //'status': 'pending',
      };

      // Agregar información del cliente si se proporciona
      if (customerName != null) orderData['customerName'] = customerName;
      if (customerPhone != null) orderData['customerPhone'] = customerPhone;
      if (notes != null && notes.isNotEmpty) orderData['notes'] = notes;

      // Guardar en Firebase usando el nuevo método
      final orderId = await FirebaseService.createOrder(
        restaurantId,
        orderData,
      );

      print('✅ Orden creada exitosamente con ID: $orderId');
      print('🏪 Restaurante: $restaurantId');
      print('📋 Items: ${itemsMap.toString()}');
      print('💰 Total: \${totalPrice.toStringAsFixed(2)}');
      print('🕒 Timestamp: ${DateTime.now().toIso8601String()}');

      // Limpiar el carrito después de crear la orden exitosamente
      clearCart();

      _isPlacingOrder = false;
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Error al crear la orden: $e');
      _isPlacingOrder = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtener el resumen de la orden antes de confirmar
  Map<String, dynamic> getOrderSummary() {
    return {
      'items':
          _cartItems
              .map(
                (item) => {
                  'name': item.menuItem.name,
                  'quantity': item.quantity,
                  'price': item.menuItem.price,
                  'total': item.totalPrice,
                },
              )
              .toList(),
      'totalPrice': totalPrice,
      'totalItems': totalItems,
      'restaurantId': _currentRestaurantId,
    };
  }
}
