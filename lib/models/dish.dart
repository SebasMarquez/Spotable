class Dish {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String restaurantId;
  final bool isAvailable;
  final int salesCount;
  final double averageRating;
  final int totalRatings;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.restaurantId,
    required this.isAvailable,
    required this.salesCount,
    required this.averageRating,
    required this.totalRatings,
  });

  factory Dish.fromMap(Map<String, dynamic> data, String id) {
    return Dish(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      salesCount: data['salesCount'] ?? 0,
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'restaurantId': restaurantId,
      'isAvailable': isAvailable,
      'salesCount': salesCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    };
  }
} 