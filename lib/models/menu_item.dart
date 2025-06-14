import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo de datos para los platos del menú
class MenuItem {
  final String? id;
  final String name;
  final double price;
  final String image;
  final String description;
  final String category;
  final bool available;

  MenuItem({
    this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.category,
    this.available = true,
  });

  // Crear MenuItem desde Firestore
  static MenuItem fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MenuItem(
      id: doc.id,
      name: data['Nombre'] ?? '',
      description: data['Descripción'] ?? '',
      price: (data['Precio'] ?? 0).toDouble(),
      category: data['Categoria'] ?? '',
      image: data['Imagen'] ?? '',
      available: data['available'] ?? true,
    );
  }

  // Convertir MenuItem a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'Nombre': name,
      'Descripción': description,
      'Precio': price,
      'Categoria': category,
      'Imagen': image,
      'available': available,
    };
  }

  // Método copyWith para actualizaciones
  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    //String? imageUrl,
    bool? available,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      image: image ?? image,
      available: available ?? this.available,
    );
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, name: $name, price: $price, category: $category, image: $image)';
  }
}
