import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/app_colors.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback onTap;

  const MenuItemCard({Key? key, required this.menuItem, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias, // Importante para que el ClipRRect funcione
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGEN CORREGIDA Y ACTUALIZADA
            Expanded(flex: 3, child: _buildImageWidget()),

            // INFORMACIÓN DEL PLATO
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NOMBRE
                        Text(
                          menuItem.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // CATEGORÍAS AÑADIDAS
                        if (menuItem.category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            menuItem.category.join(', '), // Une la lista de categorías con comas
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),

                    // PRECIO
                    Text(
                      '\$${menuItem.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DE IMAGEN ACTUALIZADO ---
  Widget _buildImageWidget() {
    Widget image;

    if (menuItem.image.startsWith('assets/')) {
      // Si la ruta comienza con 'assets/', usamos Image.asset
      image = Image.asset(
        menuItem.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (menuItem.image.startsWith('http')) {
      // Si comienza con 'http', asumimos que es una URL de red
      image = Image.network(
        menuItem.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error cargando imagen: $error');
          return _buildPlaceholder();
        },
      );
    } else {
      // Si no hay ninguna imagen o la ruta no es válida, mostramos el placeholder
      image = _buildPlaceholder();
    }
    
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: image,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(Icons.restaurant_menu, size: 32, color: Colors.grey[400]),
      ),
    );
  }
}
