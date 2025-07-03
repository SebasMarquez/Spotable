class CartItem {
  final String dishId;
  final String restaurantId;
  final int quantity;
  final String dishName;
  final double unitPrice;
  final String dishImageUrl;

  CartItem({
    required this.dishId,
    required this.restaurantId,
    required this.quantity,
    required this.dishName,
    required this.unitPrice,
    required this.dishImageUrl,
  });

  factory CartItem.fromMap(Map<String, dynamic> data, String dishId) {
    return CartItem(
      dishId: dishId,
      restaurantId: data['restaurantId'],
      quantity: data['quantity'],
      dishName: data['dishName'],
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      dishImageUrl: data['dishImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'quantity': quantity,
      'dishName': dishName,
      'unitPrice': unitPrice,
      'dishImageUrl': dishImageUrl,
    };
  }
} 