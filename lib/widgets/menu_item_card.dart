import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/app_colors.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback onTap;

  const MenuItemCard({
    Key? key,
    required this.menuItem,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                menuItem.image,
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(height: 8),
              Text(
                menuItem.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                '\$${menuItem.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                menuItem.category,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}