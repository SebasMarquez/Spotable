import 'package:flutter/material.dart';

class CategoryCarousel extends StatelessWidget {
  // Función que se llamará cuando se toque una categoría.
  final Function(String) onCategorySelected;
  // La categoría que está actualmente seleccionada, para resaltarla.
  final String? selectedCategory;

  const CategoryCarousel({
    Key? key,
    required this.onCategorySelected,
    this.selectedCategory,
  }) : super(key: key);

  static const List<Map<String, String>> _categories = [
    {'name': 'Pizzas', 'image': 'assets/images/pizza.jpg'},
    {'name': 'Sushi', 'image': 'assets/images/sushi.jpg'},
    {'name': 'Pastas', 'image': 'assets/images/pasta.jpg'},
    {'name': 'Carnes', 'image': 'assets/images/carne.jpg'},
    {'name': 'Ensaladas', 'image': 'assets/images/ensalada.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool isSelected = category['name'] == selectedCategory;

          return AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              onTap: () => onCategorySelected(category['name']!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        category['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.red.shade100),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          // El sombreado es más oscuro si no está seleccionado
                          color: Colors.black.withOpacity(isSelected ? 0.25 : 0.45),
                          // Añadimos un borde de color si está seleccionado
                          border: isSelected ? Border.all(color: Colors.red.shade600, width: 3) : null,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        category['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}