import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../models/order.dart' as order_model;
import '../models/reservation.dart';
import '../services/firebase_service.dart';

class UserProfileScreen extends StatefulWidget {
  /// El índice de la pestaña que se mostrará inicialmente (0 para Pedidos, 1 para Reservas).
  final int initialTabIndex;

  const UserProfileScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil de Usuario')),
        body: const Center(child: Text('Error: No se ha iniciado sesión.')),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          backgroundColor: Colors.red[700],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(icon: Icon(Icons.receipt_long), text: 'Mis Pedidos'),
              Tab(icon: Icon(Icons.event_seat), text: 'Mis Reservas'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildUserInfo(context, user.nombre, user.cedula),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderHistory(user.cedula),
                  _buildReservationHistory(user.cedula),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildUserInfo(BuildContext context, String name, String cedula) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      color: Colors.grey[100],
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.red[600],
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Cédula: $cedula', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildOrderHistory(String cedula) {
    return StreamBuilder<List<order_model.Order>>(
      stream: FirebaseService.getOrdersByUser(cedula),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar pedidos: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tienes pedidos en tu historial.'));
        }

        final orders = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.receipt, color: Colors.blue),
                title: Text(order.restauranteName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Total: \$${order.total.toStringAsFixed(2)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat('dd/MM/yy').format(order.createdAt)),
                    Text(order.estado, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReservationHistory(String cedula) {
    return StreamBuilder<List<Reservation>>(
      stream: FirebaseService.getReservationsByUser(cedula),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar reservas: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tienes reservas en tu historial.'));
        }

        final reservations = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final reservation = reservations[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.event_seat, color: Colors.green),
                title: Text(reservation.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Mesa: ${reservation.tableId}'),
                trailing: Text(DateFormat('dd/MM/yy HH:mm').format(reservation.reservationTime.toDate())),
              ),
            );
          },
        );
      },
    );
  }
}
