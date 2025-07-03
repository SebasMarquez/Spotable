import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phone;
  final String? website;
  final String? logoUrl;
  final List<String> categories;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final bool isActive;
  final bool isOpen;
  final Map<String, Map<String, String>> openingHours;
  final List<String> deliveryOptions;
  final List<String> paymentMethods;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String password;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    this.website,
    this.logoUrl,
    required this.categories,
    required this.rating,
    required this.totalReviews,
    required this.totalOrders,
    required this.isActive,
    required this.isOpen,
    required this.openingHours,
    required this.deliveryOptions,
    required this.paymentMethods,
    required this.createdAt,
    required this.updatedAt,
    required this.password,
  });

  factory Restaurant.fromMap(Map<String, dynamic> data, [String? id]) {
    return Restaurant(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      website: data['website'],
      logoUrl: data['logoUrl'],
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      totalOrders: data['totalOrders'] ?? 0,
      isActive: data['isActive'] ?? true,
      isOpen: data['isOpen'] ?? true,
      openingHours: _parseOpeningHours(data['openingHours']),
      deliveryOptions: List<String>.from(data['deliveryOptions'] ?? ['pickup', 'delivery']),
      paymentMethods: List<String>.from(data['paymentMethods'] ?? ['cash', 'card']),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      password: data['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'website': website,
      'logoUrl': logoUrl,
      'categories': categories,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'isActive': isActive,
      'isOpen': isOpen,
      'openingHours': openingHours,
      'deliveryOptions': deliveryOptions,
      'paymentMethods': paymentMethods,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'password': password,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? website,
    String? logoUrl,
    List<String>? categories,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    bool? isActive,
    bool? isOpen,
    Map<String, Map<String, String>>? openingHours,
    List<String>? deliveryOptions,
    List<String>? paymentMethods,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? password,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      isActive: isActive ?? this.isActive,
      isOpen: isOpen ?? this.isOpen,
      openingHours: openingHours ?? this.openingHours,
      deliveryOptions: deliveryOptions ?? this.deliveryOptions,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      password: password ?? this.password,
    );
  }

  static Map<String, Map<String, String>> _parseOpeningHours(dynamic data) {
    if (data == null) {
      return {
        'monday': {'open': '08:00', 'close': '22:00'},
        'tuesday': {'open': '08:00', 'close': '22:00'},
        'wednesday': {'open': '08:00', 'close': '22:00'},
        'thursday': {'open': '08:00', 'close': '22:00'},
        'friday': {'open': '08:00', 'close': '23:00'},
        'saturday': {'open': '09:00', 'close': '23:00'},
        'sunday': {'open': '09:00', 'close': '21:00'},
      };
    }

    if (data is Map) {
      Map<String, Map<String, String>> result = {};
      data.forEach((key, value) {
        if (value is Map) {
          Map<String, String> dayHours = {};
          value.forEach((hourKey, hourValue) {
            dayHours[hourKey.toString()] = hourValue.toString();
          });
          result[key.toString()] = dayHours;
        }
      });
      return result;
    }

    return {
      'monday': {'open': '08:00', 'close': '22:00'},
      'tuesday': {'open': '08:00', 'close': '22:00'},
      'wednesday': {'open': '08:00', 'close': '22:00'},
      'thursday': {'open': '08:00', 'close': '22:00'},
      'friday': {'open': '08:00', 'close': '23:00'},
      'saturday': {'open': '09:00', 'close': '23:00'},
      'sunday': {'open': '09:00', 'close': '21:00'},
    };
  }
} 