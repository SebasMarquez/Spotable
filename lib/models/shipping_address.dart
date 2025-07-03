class ShippingAddress {
  final String id;
  final String alias;
  final String address;
  final String city;
  final String? details;

  ShippingAddress({
    required this.id,
    required this.alias,
    required this.address,
    required this.city,
    this.details,
  });

  factory ShippingAddress.fromMap(Map<String, dynamic> data, String id) {
    return ShippingAddress(
      id: id,
      alias: data['alias'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      details: data['details'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alias': alias,
      'address': address,
      'city': city,
      'details': details,
    };
  }
} 