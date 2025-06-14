import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../utils/app_colors.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;

  const CartItemCard({Key? key, required this.cartItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen del producto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    cartItem.menuItem.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cartItem.menuItem.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Precio: \$${cartItem.menuItem.price.toStringAsFixed(2)} c/u",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Subtotal: \$${cartItem.totalPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Controles de cantidad
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón eliminar
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 8),
                  // Controles de cantidad
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón decrementar
                        _buildQuantityButton(
                          context,
                          icon: Icons.remove,
                          onPressed: () => _decrementQuantity(context),
                        ),
                        // Cantidad actual
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            '${cartItem.quantity}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        // Botón incrementar
                        _buildQuantityButton(
                          context,
                          icon: Icons.add,
                          onPressed: () => _incrementQuantity(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _incrementQuantity(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    // Cambio: usar String en lugar de int para el ID
    cartService.updateQuantity(
      cartItem.menuItem.id!,  // Usar String y manejar nullable
      cartItem.quantity + 1,
    );
  }

  void _decrementQuantity(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    
    if (cartItem.quantity > 1) {
      // Cambio: usar String en lugar de int para el ID
      cartService.updateQuantity(
        cartItem.menuItem.id!,  // Usar String y manejar nullable
        cartItem.quantity - 1,
      );
    } else {
      // Si la cantidad es 1, mostrar confirmación antes de eliminar
      _showDeleteConfirmation(context);
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar item'),
          content: Text(
            '¿Estás seguro de que quieres eliminar "${cartItem.menuItem.name}" del carrito?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final cartService = Provider.of<CartService>(context, listen: false);
                // Cambio: usar String en lugar de int para el ID
                cartService.removeFromCart(cartItem.menuItem.id!);  // Usar String y manejar nullable
                Navigator.of(context).pop();
                
                // Mostrar mensaje de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${cartItem.menuItem.name} eliminado del carrito'),
                    backgroundColor: AppColors.secondary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

//import 'package:flutter/material.dart';
//import '../models/cart_item.dart';
//import '../utils/app_colors.dart';
//
//class CartItemCard extends StatelessWidget {
//  final CartItem cartItem;
//
//  const CartItemCard({Key? key, required this.cartItem}) : super(key: key);
//
//  @override
//  Widget build(BuildContext context) {
//    return Card(
//      elevation: 2,
//      color: AppColors.cardBackground,
//      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//      child: Padding(
//        padding: EdgeInsets.all(16),
//        child: IntrinsicHeight(
//          child: Row(
//            crossAxisAlignment: CrossAxisAlignment.stretch,
//            children: [
//              // Imagen del producto
//              Container(
//                width: 60,
//                height: 60,
//                decoration: BoxDecoration(
//                  color: Colors.grey.shade100,
//                  borderRadius: BorderRadius.circular(12),
//                  boxShadow: [
//                    BoxShadow(
//                      color: Colors.black.withOpacity(0.05),
//                      blurRadius: 4,
//                      offset: Offset(0, 2),
//                    ),
//                  ],
//                ),
//                child: ClipRRect(
//                  borderRadius: BorderRadius.circular(12),
//                  child: Image.network(
//                    cartItem.menuItem.image,
//                    width: 60,
//                    height: 60,
//                    fit: BoxFit.cover,
//                    loadingBuilder: (context, child, loadingProgress) {
//                      if (loadingProgress == null) return child;
//                      return Container(
//                        width: 60,
//                        height: 60,
//                        child: Center(
//                          child: SizedBox(
//                            width: 20,
//                            height: 20,
//                            child: CircularProgressIndicator(
//                              strokeWidth: 2,
//                              color: AppColors.primary,
//                              value:
//                                  loadingProgress.expectedTotalBytes != null
//                                      ? loadingProgress.cumulativeBytesLoaded /
//                                          loadingProgress.expectedTotalBytes!
//                                      : null,
//                            ),
//                          ),
//                        ),
//                      );
//                    },
//                    errorBuilder: (context, error, stackTrace) {
//                      return Container(
//                        width: 60,
//                        height: 60,
//                        decoration: BoxDecoration(
//                          color: Colors.grey.shade200,
//                          borderRadius: BorderRadius.circular(12),
//                        ),
//                        child: Icon(
//                          Icons.restaurant_menu,
//                          color: Colors.grey.shade400,
//                          size: 28,
//                        ),
//                      );
//                    },
//                  ),
//                ),
//              ),
//              SizedBox(width: 16),
//              // Información del producto
//              Expanded(
//                child: Column(
//                  crossAxisAlignment: CrossAxisAlignment.start,
//                  mainAxisAlignment: MainAxisAlignment.center,
//                  children: [
//                    Text(
//                      cartItem.menuItem.name,
//                      style: TextStyle(
//                        fontSize: 16,
//                        fontWeight: FontWeight.w600,
//                        color: AppColors.textPrimary,
//                      ),
//                      maxLines: 2,
//                      overflow: TextOverflow.ellipsis,
//                    ),
//                    SizedBox(height: 4),
//                    Text(
//                      'Cantidad: ${cartItem.quantity}',
//                      style: TextStyle(
//                        fontSize: 14,
//                        color: AppColors.textSecondary,
//                      ),
//                    ),
//                    SizedBox(height: 4),
//                    Text(
//                      '\$${cartItem.totalPrice.toStringAsFixed(2)}',
//                      style: TextStyle(
//                        fontSize: 16,
//                        fontWeight: FontWeight.bold,
//                        color: AppColors.primary,
//                      ),
//                    ),
//                  ],
//                ),
//              ),
//              // Botones de cantidad (opcional)
//              Column(
//                mainAxisAlignment: MainAxisAlignment.center,
//                children: [
//                  Container(
//                    width: 32,
//                    height: 32,
//                    decoration: BoxDecoration(
//                      color: AppColors.primary.withOpacity(0.1),
//                      borderRadius: BorderRadius.circular(16),
//                    ),
//                    child: Center(
//                      child: Text(
//                        '${cartItem.quantity}',
//                        style: TextStyle(
//                          fontSize: 14,
//                          fontWeight: FontWeight.bold,
//                          color: AppColors.primary,
//                        ),
//                      ),
//                    ),
//                  ),
//                ],
//              ),
//            ],
//          ),
//        ),
//      ),
//    );
//  }
//}
//