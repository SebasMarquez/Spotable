class Restaurant {
  final String id;
  final String name;
  final String imageUrl;

  Restaurant({required this.id, required this.name, required this.imageUrl});

  factory Restaurant.fromFirestore(Map<String, dynamic> data, String id) {
    return Restaurant(
      id: id,
      name: data['Nombre'] ?? '',
      imageUrl: data['imagen'] ?? '',
    );
  }
}
