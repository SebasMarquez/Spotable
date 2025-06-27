import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class OrderDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const OrderDetailRow({
    Key? key,
    required this.icon,
    required this.text,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}