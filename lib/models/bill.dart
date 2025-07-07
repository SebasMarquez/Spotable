import 'package:cloud_firestore/cloud_firestore.dart';

class Bill {
  final String billId;
  final List<String> orderIds;
  final String restaurantId;
  final String? tableId;
  final String? clientId;
  final double amount;
  final String status; // 'pagada', 'pendiente'
  final DateTime createdAt;
  final DateTime? paidAt;
  final String type; // 'delivery', 'pickup', 'dine-in'
  final String? details;

  Bill({
    required this.billId,
    required this.orderIds,
    required this.restaurantId,
    this.tableId,
    this.clientId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paidAt,
    required this.type,
    this.details,
  });

  factory Bill.fromMap(Map<String, dynamic> data, String id) {
    return Bill(
      billId: id,
      orderIds: List<String>.from(data['orderIds'] ?? []),
      restaurantId: data['restaurantId'] ?? '',
      tableId: data['tableId'],
      clientId: data['clientId'],
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pendiente',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] is Timestamp)
              ? (data['paidAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['paidAt'])
          : null,
      type: data['type'] ?? '',
      details: data['details'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderIds': orderIds,
      'restaurantId': restaurantId,
      'tableId': tableId,
      'clientId': clientId,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'type': type,
      'details': details,
    };
  }

  Bill copyWith({
    List<String>? orderIds,
    String? restaurantId,
    String? tableId,
    String? clientId,
    double? amount,
    String? status,
    DateTime? createdAt,
    DateTime? paidAt,
    String? type,
    String? details,
  }) {
    return Bill(
      billId: billId,
      orderIds: orderIds ?? this.orderIds,
      restaurantId: restaurantId ?? this.restaurantId,
      tableId: tableId ?? this.tableId,
      clientId: clientId ?? this.clientId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      type: type ?? this.type,
      details: details ?? this.details,
    );
  }
} 