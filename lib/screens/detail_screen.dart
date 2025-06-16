import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../services/cart_service.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_colors.dart';

class DetailScreen extends StatefulWidget {
  final MenuItem menuItem;

  const DetailScreen({Key? key, required this.menuItem}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Plato'),
        backgroundColor: Colors.white,
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // IMAGEN CORREGIDA - Ahora con aspecto uniforme
                _buildImageWidget(),
                SizedBox(height: 20),

                // NOMBRE
                Text(
                  widget.menuItem.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),

                // DESCRIPCIÓN
                Text(
                  widget.menuItem.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),

                // PRECIO
                Text(
                  '\$${widget.menuItem.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 24),

                // SELECTOR DE CANTIDAD
                _buildQuantitySelector(),
                SizedBox(height: 24),

                // BOTÓN AGREGAR AL CARRITO
                _buildAddToCartButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (widget.menuItem.image.isEmpty) {
      return _buildPlaceholder();
    }

    return Container(
      height: 250, // Altura fija para uniformidad
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.menuItem.image,
          fit:
              BoxFit
                  .cover, // CLAVE: Esto hace que la imagen cubra todo el espacio manteniendo proporción
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 250,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cargando imagen...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error cargando imagen: $error');
            return _buildPlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Sin imagen disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed:
                quantity > 1
                    ? () {
                      setState(() {
                        quantity--;
                      });
                    }
                    : null,
            icon: Icon(Icons.remove),
            style: IconButton.styleFrom(
              backgroundColor:
                  quantity > 1 ? AppColors.primary : Colors.grey[300],
              foregroundColor: quantity > 1 ? Colors.white : Colors.grey[600],
              shape: CircleBorder(),
              padding: EdgeInsets.all(8),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                quantity++;
              });
            },
            icon: Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: CircleBorder(),
              padding: EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Provider.of<CartService>(
            context,
            listen: false,
          ).addToCart(widget.menuItem, quantity);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.menuItem.name} agregado al carrito',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 20),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Agregar al Carrito - \$${(widget.menuItem.price * quantity).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
