import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../utils/app_colors.dart';
import 'order_detail_row.dart';

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 24),
            _buildDeliveryInfo(),
            const Divider(height: 24),
            _buildOrderItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido de: ${order.cedulaCliente}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            _getStatusChip(order.estado),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    final isDelivery = order.deliveryType == 'delivery';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrderDetailRow(
          icon: isDelivery ? Icons.delivery_dining : Icons.restaurant_menu,
          text: isDelivery ? 'A Domicilio' : 'Para Comer en Local',
          iconColor: AppColors.primary,
        ),
        if (isDelivery && order.deliveryAddress != null)
          OrderDetailRow(
            icon: Icons.location_on_outlined,
            text: order.deliveryAddress!,
          ),
        if (!isDelivery && order.idMesa != null && order.idMesa!.isNotEmpty)
          OrderDetailRow(
            icon: Icons.table_restaurant_outlined,
            text: 'Mesa: ${order.idMesa}',
          ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: order.items.map((item) {
        return Text('• ${item.quantity}x ${item.name}');
      }).toList(),
    );
  }

  Widget _getStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'generado':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.receipt_long_outlined;
        break;
      case 'en preparación':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.kitchen_outlined;
        break;
      case 'completado':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        break;
      case 'cancelado':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        icon = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(icon, color: textColor, size: 18),
      label: Text(
        status,
        style:
            TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}