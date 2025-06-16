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
  //final String customerName;
  //final String? customerPhone;
  //final String? customerEmail;
  final List<OrderItem> items;
  final double total;
  //final String status; // 'pending', 'preparing', 'ready', 'delivered', 'cancelled'
  //final String? notes;
  //final DateTime createdAt;
  //final DateTime? updatedAt;
  //final String? deliveryAddress;
  //final String orderType; // 'delivery', 'pickup', 'dine_in'

  Order({
    required this.id,
    required this.restauranteId,
    //required this.customerName,
    //this.customerPhone,
    //this.customerEmail,
    required this.items,
    required this.total,
    //this.status = 'pending',
    //this.notes,
    //required this.createdAt,
    //this.updatedAt,
    //this.deliveryAddress,
    //this.orderType = 'pickup',
  });

  // Crear Order desde Firestore
  static Order fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Order(
      id: doc.id,
      restauranteId: data['restauranteId'] ?? '',
      //customerName: data['customerName'] ?? '',
      //customerPhone: data['customerPhone'],
      //customerEmail: data['customerEmail'],
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ?? [],
      total: (data['total'] ?? 0).toDouble(),
      //status: data['status'] ?? 'pending',
      //notes: data['notes'],
      //createdAt: data['createdAt'] != null 
      //    ? (data['createdAt'] as Timestamp).toDate() 
      //    : DateTime.now(),
      //updatedAt: data['updatedAt'] != null 
      //    ? (data['updatedAt'] as Timestamp).toDate() 
      //    : null,
      //deliveryAddress: data['deliveryAddress'],
      //orderType: data['orderType'] ?? 'pickup',
    );
  }

  // Convertir Order a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'restauranteId': restauranteId,
      //'customerName': customerName,
      //'customerPhone': customerPhone,
      //'customerEmail': customerEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      //'status': status,
      //'notes': notes,
      //'createdAt': Timestamp.fromDate(createdAt),
      //'updatedAt': FieldValue.serverTimestamp(),
      //'deliveryAddress': deliveryAddress,
      //'orderType': orderType,
    };
  }

  // Método copyWith para actualizaciones
  Order copyWith({
    String? id,
    String? restauranteId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    List<OrderItem>? items,
    double? total,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deliveryAddress,
    String? orderType,
  }) {
    return Order(
      id: id ?? this.id,
      restauranteId: restauranteId ?? this.restauranteId,
      //customerName: customerName ?? this.customerName,
      //customerPhone: customerPhone ?? this.customerPhone,
      //customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      total: total ?? this.total,
      //status: status ?? this.status,
      //notes: notes ?? this.notes,
      //createdAt: createdAt ?? this.createdAt,
      //updatedAt: updatedAt ?? this.updatedAt,
      //deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      //orderType: orderType ?? this.orderType,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, items: $items, total: $total)';
  }
}