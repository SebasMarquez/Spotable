import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/cart_item_widget.dart';
import '../utils/app_colors.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mi Carrito',
        showBackButton: true,
      ),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.cartItems.isEmpty) {
            return _buildEmptyCart();
          }

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartService.cartItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: CartItemCard(
                          cartItem: cartService.cartItems[index],
                        ),
                      );
                    },
                  ),
                ),
                _buildOrderSummary(cartService),
                SizedBox(height: 16),
                _buildPlaceOrderButton(context, cartService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartService cartService) {
    return Card(
      elevation: 2,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Pedido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total de items:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${cartService.totalItems}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '\$${cartService.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton(BuildContext context, CartService cartService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          cartService.placeOrder();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Orden realizada con éxito!'),
              backgroundColor: AppColors.secondary,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check),
            SizedBox(width: 8),
            Text(
              'Realizar Pedido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}