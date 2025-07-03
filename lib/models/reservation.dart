import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String reservationId;
  final String userId;
  final String userName;
  final String restaurantId;
  final String? restaurantName;
  final String? tableId;
  final DateTime reservationTime;
  final int partySize;
  String status; // pendiente, confirmada, completada, cancelada
  final String? managedByEmployeeId;
  final String? managedByEmployeeName;
  final String? comments;
  final DateTime createdAt;

  Reservation({
    required this.reservationId,
    required this.userId,
    required this.userName,
    required this.restaurantId,
    this.restaurantName,
    this.tableId,
    required this.reservationTime,
    required this.partySize,
    required this.status,
    this.managedByEmployeeId,
    this.managedByEmployeeName,
    this.comments,
    required this.createdAt,
  });

  factory Reservation.fromMap(Map<String, dynamic> data, String id) {
    return Reservation(
      reservationId: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'],
      tableId: data['tableId'],
      reservationTime: (data['reservationTime'] is Timestamp)
          ? (data['reservationTime'] as Timestamp).toDate()
          : DateTime.tryParse(data['reservationTime'] ?? '') ?? DateTime.now(),
      partySize: data['partySize'] ?? data['people'] ?? 1,
      status: data['status'] ?? '',
      managedByEmployeeId: data['managedByEmployeeId'],
      managedByEmployeeName: data['managedByEmployeeName'],
      comments: data['comments'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'tableId': tableId,
      'reservationTime': Timestamp.fromDate(reservationTime),
      'partySize': partySize,
      'status': status,
      'managedByEmployeeId': managedByEmployeeId,
      'managedByEmployeeName': managedByEmployeeName,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 