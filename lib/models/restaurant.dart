class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> categories; // CAMBIO: Añadido campo para las categorías

  Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.categories, // CAMBIO: Añadido al constructor
  });

  factory Restaurant.fromFirestore(Map<String, dynamic> data, String id) {
    return Restaurant(
      id: id,
      name: data['Nombre'] ?? '',
      imageUrl: data['imagen'] ?? '',
      // CAMBIO: Leemos el array 'categories' de Firestore.
      // Si no existe, usamos una lista vacía.
      // ADEMÁS: Filtramos cualquier valor nulo que pueda venir en la lista.
      categories: List<String>.from(
          (data['categories'] as List<dynamic>? ?? []).where((c) => c != null).map((c) => c.toString())
      ),
    );
  }
}
