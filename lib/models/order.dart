import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? notes;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
    };
  }

  static OrderItem fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
    );
  }

  double get subtotal => price * quantity;
}

class Order {
  final String id;
  final String restauranteId;
  final String restauranteName;
  final List<OrderItem> items;
  final double total;
  final String estado;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.restauranteId,
    required this.restauranteName,
    required this.items,
    required this.total,
    required this.estado,
    required this.createdAt,
  });

  // Crear Order desde Firestore
  static Order fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Order(
      id: doc.id,
      restauranteId: data['restauranteId'] ?? '',
      restauranteName: data['restauranteName'] ?? '',
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (data['total'] ?? 0).toDouble(),
      estado: data['estado'] ?? 'Generado',
      createdAt:
          data['createdAt'] != null && data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  // Convertir Order a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'restauranteId': restauranteId,
      'restauranteName': restauranteName,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'estado': estado,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Método copyWith para actualizaciones
  Order copyWith({
    String? id,
    String? restauranteId,
    String? restauranteName,
    List<OrderItem>? items,
    double? total,
    String? estado,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      restauranteId: restauranteId ?? this.restauranteId,
      restauranteName: restauranteName ?? this.restauranteName,
      items: items ?? this.items,
      total: total ?? this.total,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, items: $items, total: $total)';
  }
}
