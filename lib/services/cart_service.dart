import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import 'firebase_service.dart';

class CartService extends ChangeNotifier {
  List<CartItem> _cartItems = [];
  bool _isPlacingOrder = false;
  String? _currentRestaurantId; // Agregar ID del restaurante actual

  List<CartItem> get cartItems => _cartItems;
  bool get isPlacingOrder => _isPlacingOrder;
  String? get currentRestaurantId => _currentRestaurantId;

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

  void removeFromCart(int menuItemId) {
    _cartItems.removeWhere((item) => item.menuItem.id == menuItemId);
    notifyListeners();
  }

  void updateQuantity(int menuItemId, int newQuantity) {
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
      final orderId = await FirebaseService.createOrder(_currentRestaurantId!, orderData);
      
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
  Future<bool> placeOrderSimple() async {
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

      // Crear la orden con solo la estructura básica que necesitas
      Map<String, dynamic> orderData = {
        'Items': itemsMap,
        'total': totalPrice,
      };

      // Guardar en Firebase usando el nuevo método
      final orderId = await FirebaseService.createOrder(_currentRestaurantId!, orderData);
      
      print('✅ Orden creada exitosamente con ID: $orderId');
      print('🏪 Restaurante: $_currentRestaurantId');
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
      final orderId = await FirebaseService.createOrder(restaurantId, orderData);
      
      print('✅ Orden creada exitosamente con ID: $orderId');
      print('🏪 Restaurante: $restaurantId');
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

  /// Obtener el resumen de la orden antes de confirmar
  Map<String, dynamic> getOrderSummary() {
    return {
      'items': _cartItems.map((item) => {
        'name': item.menuItem.name,
        'quantity': item.quantity,
        'price': item.menuItem.price,
        'total': item.totalPrice,
      }).toList(),
      'totalPrice': totalPrice,
      'totalItems': totalItems,
      'restaurantId': _currentRestaurantId,
    };
  }

  /// Verificar si hay un restaurante establecido
  bool get hasRestaurantSet => _currentRestaurantId != null;
}