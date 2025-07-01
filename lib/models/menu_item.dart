import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String? id;
  final String name;
  final double price;
  final String image;
  final String description;
  final List<String> category; // CAMBIO: Ahora es una lista de Strings
  final bool available;

  MenuItem({
    this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.category, // CAMBIO: Ahora espera una lista
    this.available = true,
  });

  static MenuItem fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final categoriesData = data['Categoria'];
    List<String> categories;
    if (categoriesData is List) {
      // Filtramos cualquier valor nulo y luego lo convertimos a String.
      categories = categoriesData
          .where((item) => item != null)
          .map((item) => item.toString()).toList();
    } else if (categoriesData is String) {
      categories = [categoriesData];
    } else {
      categories = [];
    }

    return MenuItem(
      id: doc.id,
      name: data['Nombre'] ?? '',
      description: data['Descripción'] ?? '',
      price: (data['Precio'] ?? 0).toDouble(),
      category: categories,
      image: data['Imagen'] ?? '',
      available: data['available'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Nombre': name,
      'Descripción': description,
      'Precio': price,
      'Categoria': category, // Guardamos la lista
      'Imagen': image,
      'available': available,
    };
  }
}
