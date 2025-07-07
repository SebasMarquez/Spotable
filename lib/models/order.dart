import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String dishId;
  final String dishName;
  final int quantity;
  final double unitPrice;
  final String? comment;

  OrderItem({
    required this.dishId,
    required this.dishName,
    required this.quantity,
    required this.unitPrice,
    this.comment,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      dishId: data['dishId'],
      dishName: data['dishName'],
      quantity: data['quantity'],
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      comment: data['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dishId': dishId,
      'dishName': dishName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'comment': comment,
    };
  }

  OrderItem copyWith({
    int? quantity,
    String? comment,
  }) {
    return OrderItem(
      dishId: dishId,
      dishName: dishName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      comment: comment ?? this.comment,
    );
  }
}

class Order {
  final String orderId;
  final String userId;
  final String userName;
  final String restaurantId;
  final String restaurantName;
  final String type; // delivery, pickup, dine-in
  String status; // revision, en_cocina, listo, entregado
  final String? tableId;
  final String? tableName;
  final List<OrderItem> items;
  final double totalAmount;
  final String? handledByEmployeeId;
  final String? handledByEmployeeName;
  final DateTime createdAt;
  String? detail;
  final Map<String, dynamic>? shippingAddress;

  Order({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.restaurantId,
    required this.restaurantName,
    required this.type,
    required this.status,
    this.tableId,
    this.tableName,
    required this.items,
    required this.totalAmount,
    this.handledByEmployeeId,
    this.handledByEmployeeName,
    required this.createdAt,
    this.detail,
    this.shippingAddress,
  });

  factory Order.fromMap(Map<String, dynamic> data, String id) {
    return Order(
      orderId: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? '',
      tableId: data['tableId'],
      tableName: data['tableName'],
      items: (data['items'] as List<dynamic>? ?? []).map((item) => OrderItem.fromMap(item)).toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      handledByEmployeeId: data['handledByEmployeeId'],
      handledByEmployeeName: data['handledByEmployeeName'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      detail: data['detail'],
      shippingAddress: data['shippingAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'type': type,
      'status': status,
      'tableId': tableId,
      'tableName': tableName,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'handledByEmployeeId': handledByEmployeeId,
      'handledByEmployeeName': handledByEmployeeName,
      'createdAt': Timestamp.fromDate(createdAt),
      'detail': detail,
      'shippingAddress': shippingAddress,
    };
  }
} 