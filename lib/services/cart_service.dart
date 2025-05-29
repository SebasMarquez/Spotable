import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartService extends ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  int get totalItems {
    return _cartItems.fold(0, (total, item) => total + item.quantity);
  }

  double get totalPrice {
    return _cartItems.fold(0.0, (total, item) => total + item.totalPrice);
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

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void placeOrder() {
    // Simular creación de orden
    print('Orden creada: ${_cartItems.map((item) => '${item.menuItem.name} x${item.quantity}').toList()}');
    print('Total: \$${totalPrice.toStringAsFixed(2)}');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    
    clearCart();
  }
}