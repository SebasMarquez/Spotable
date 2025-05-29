import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    required this.quantity,
  });

  double get totalPrice => menuItem.price * quantity;
}