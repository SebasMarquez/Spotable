import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeReview {
  final String id;
  final String employeeId;
  final String employeeName;
  final String userId;
  final String userName;
  final String orderId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  EmployeeReview({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.userId,
    required this.userName,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory EmployeeReview.fromMap(Map<String, dynamic> data, String id) {
    return EmployeeReview(
      id: id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      orderId: data['orderId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'userId': userId,
      'userName': userName,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 