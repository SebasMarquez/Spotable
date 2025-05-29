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
      appBar: CustomAppBar(
        title: 'Detalle del Plato',
        showBackButton: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.menuItem.image,
                  style: TextStyle(fontSize: 64),
                ),
                SizedBox(height: 16),
                Text(
                  widget.menuItem.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  widget.menuItem.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Text(
                  '\$${widget.menuItem.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 24),
                _buildQuantitySelector(),
                SizedBox(height: 24),
                _buildAddToCartButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            if (quantity > 1) {
              setState(() {
                quantity--;
              });
            }
          },
          icon: Icon(Icons.remove),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            shape: CircleBorder(),
          ),
        ),
        SizedBox(width: 16),
        Text(
          '$quantity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 16),
        IconButton(
          onPressed: () {
            setState(() {
              quantity++;
            });
          },
          icon: Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            shape: CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Provider.of<CartService>(context, listen: false)
              .addToCart(widget.menuItem, quantity);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.menuItem.name} agregado al carrito'),
              backgroundColor: AppColors.secondary,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart),
            SizedBox(width: 8),
            Text(
              'Agregar al Carrito - \$${(widget.menuItem.price * quantity).toStringAsFixed(2)}',
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