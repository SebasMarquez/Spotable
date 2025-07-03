import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeMetric {
  final String id;
  final String employeeId;
  final String restaurantId;
  final int totalRatings;
  final double averageRating;
  final int ordersHandled;
  final int reservationsManaged;
  final int tablesServed;
  final double totalTips;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime lastUpdated;

  EmployeeMetric({
    required this.id,
    required this.employeeId,
    required this.restaurantId,
    required this.totalRatings,
    required this.averageRating,
    required this.ordersHandled,
    required this.reservationsManaged,
    required this.tablesServed,
    required this.totalTips,
    required this.periodStart,
    required this.periodEnd,
    required this.lastUpdated,
  });

  factory EmployeeMetric.fromMap(Map<String, dynamic> data, [String? id]) {
    return EmployeeMetric(
      id: id ?? data['id'] ?? '',
      employeeId: data['employeeId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      totalRatings: data['totalRatings'] ?? 0,
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      ordersHandled: data['ordersHandled'] ?? 0,
      reservationsManaged: data['reservationsManaged'] ?? 0,
      tablesServed: data['tablesServed'] ?? 0,
      totalTips: (data['totalTips'] ?? 0).toDouble(),
      periodStart: data['periodStart'] != null 
          ? (data['periodStart'] as Timestamp).toDate()
          : DateTime.now(),
      periodEnd: data['periodEnd'] != null 
          ? (data['periodEnd'] as Timestamp).toDate()
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'restaurantId': restaurantId,
      'totalRatings': totalRatings,
      'averageRating': averageRating,
      'ordersHandled': ordersHandled,
      'reservationsManaged': reservationsManaged,
      'tablesServed': tablesServed,
      'totalTips': totalTips,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
} 