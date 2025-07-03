import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;
import '../models/restaurant.dart';
import '../services/firebase_service.dart';
import '../widgets/employee_list_widget.dart';
import '../widgets/table_management_dialog.dart';
import '../utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart' as order_model;
import '../models/reservation.dart';
import '../models/table.dart';
import '../models/dish.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ScrollController _scrollController = ScrollController();
  app_user.User? _currentUser;
  Restaurant? _restaurant;
  bool _isLoading = true;
  int _selectedIndex = 0;
  
  // GlobalKeys para las secciones
  final GlobalKey _ordersKey = GlobalKey();
  final GlobalKey _reservationsKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _tablesKey = GlobalKey();
  final GlobalKey _employeesKey = GlobalKey();

  // Nuevas listas para los datos
  List<order_model.Order> _orders = [];
  List<Reservation> _reservations = [];
  List<RestaurantTable> _tables = [];
  List<Dish> _dishes = [];
  List<app_user.User> _employees = [];
  
  // Filtros para el menú
  Set<String> _selectedCategories = {};
  List<String> _availableCategories = [];

  String _orderFilter = 'recent'; // 'recent' o 'status'

  @override
  void initState() {
    super.initState();
    _loadUserAndRestaurantData();
    _restoreRestaurantSession();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndRestaurantData() async {
    setState(() => _isLoading = true);
    try {
      // Get current user data
      final userData = await _firebaseService.getCurrentUserData();
      String? restaurantId;
      
      if (userData == null) {
        // Si no hay usuario, intentar cargar restaurante desde sesión local
        final prefs = await SharedPreferences.getInstance();
        restaurantId = prefs.getString('restaurant_id');
        final restaurantName = prefs.getString('restaurant_name');
        final restaurantLogo = prefs.getString('restaurant_logo');
        if (restaurantId != null && restaurantName != null) {
          setState(() {
            _restaurant = Restaurant(
              id: restaurantId!,
              name: restaurantName,
              description: '',
              address: '',
              phone: '',
              website: null,
              logoUrl: restaurantLogo,
              categories: [],
              rating: 0.0,
              totalReviews: 0,
              totalOrders: 0,
              isActive: true,
              isOpen: true,
              openingHours: {},
              deliveryOptions: [],
              paymentMethods: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              password: '',
            );
          });
        }
      } else {
        setState(() => _currentUser = userData);
        
        // Obtener restaurantId del usuario
        restaurantId = userData.restaurantId;
        print('Usuario: ${userData.name}, Role: ${userData.role}, RestaurantId: $restaurantId, isEmployee: ${userData.isEmployee}');
        
        if (restaurantId != null && restaurantId.isNotEmpty) {
          try {
            final restaurantData = await _firebaseService.getRestaurant(restaurantId);
            if (restaurantData != null) {
              setState(() => _restaurant = Restaurant.fromMap(restaurantData, restaurantId));
              print('Restaurante cargado: ${_restaurant?.name}');
            } else {
              print('No se encontró el restaurante con ID: $restaurantId');
            }
          } catch (e) {
            print('Error cargando restaurante: $e');
          }
        } else {
          print('No hay restaurantId en el usuario');
        }
      }
      
      // Cargar datos de pedidos, reservaciones, mesas, platos y empleados si hay restaurante
      if (restaurantId != null && restaurantId.isNotEmpty) {
        print('Cargando datos para restaurante: $restaurantId');
        await _loadOrders(restaurantId);
        await _loadReservations(restaurantId);
        await _loadTables(restaurantId);
        await _loadDishes(restaurantId);
        await _loadEmployees(restaurantId);
      } else {
        print('No se pueden cargar datos sin restaurantId');
      }
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOrders(String restaurantId) async {
    print('Cargando pedidos para restaurantId: ' + restaurantId);
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .get();
    print('Pedidos encontrados: ' + snapshot.docs.length.toString());
    setState(() {
      _orders = snapshot.docs
          .map((doc) => order_model.Order.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> _loadReservations(String restaurantId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('reservationTime')
        .get();
    setState(() {
      _reservations = snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> _loadTables(String restaurantId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tables')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('tableName')
        .get();
    setState(() {
      _tables = snapshot.docs
          .map((doc) => RestaurantTable.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> _loadDishes(String restaurantId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('dishes')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('name')
        .get();
    
    final dishes = snapshot.docs
        .map((doc) => Dish.fromMap(doc.data(), doc.id))
        .toList();
    
    setState(() {
      _dishes = dishes;
      // Extraer categorías únicas
      _availableCategories = dishes.map((dish) => dish.category).toSet().toList()..sort();
      // Si no hay categorías seleccionadas, seleccionar todas
      if (_selectedCategories.isEmpty) {
        _selectedCategories = _availableCategories.toSet();
      }
    });
  }

  Future<void> _loadEmployees(String restaurantId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isEmployee', isEqualTo: true)
        .orderBy('name')
        .get();
    
    final employees = snapshot.docs
        .map((doc) => app_user.User.fromMap(doc.data(), doc.id))
        .toList();
    
    setState(() {
      _employees = employees;
    });
  }

  Future<void> _restoreRestaurantSession() async {
    final prefs = await SharedPreferences.getInstance();
    final restaurantId = prefs.getString('restaurant_id');
    if (restaurantId != null && _currentUser == null) {
      // Aquí podrías restaurar la sesión si lo deseas
      // Por ahora, solo para referencia
    }
  }

  void _handleLogout() async {
    try {
      // Cerrar sesión de Firebase si hay usuario autenticado
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firebaseService.signOut();
      }
      // Limpiar sesión local de restaurante
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('restaurant_id');
      await prefs.remove('restaurant_name');
      await prefs.remove('restaurant_logo');
      
      // Verificar que el widget aún esté montado antes de navegar
      if (mounted) {
        // Usar pushReplacementNamed para evitar problemas de navegación
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      print('Error during logout: $e');
      // Aún intentar navegar de vuelta a la pantalla de bienvenida en caso de error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Centrar la columna correspondiente
    _scrollToSection(index);
  }

  void _scrollToSection(int sectionIndex) {
    GlobalKey? targetKey;
    
    switch (sectionIndex) {
      case 0: // Dashboard (inicio)
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        return;
      case 1: // Pedidos
        targetKey = _ordersKey;
        break;
      case 2: // Mesas (según el bottom navigation bar)
        targetKey = _tablesKey;
        break;
      case 3: // Menú
        targetKey = _menuKey;
        break;
      case 4: // Empleados
        targetKey = _employeesKey;
        break;
      case 5: // Reportes (aún no implementado)
        // Por ahora, ir al inicio
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        return;
    }
    
    if (targetKey != null && targetKey.currentContext != null) {
      final RenderBox renderBox = targetKey.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final scrollPosition = position.dy - 100; // Offset para centrar mejor
      
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null && _restaurant == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: Text('Error: Usuario o restaurante no encontrado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: _restaurant?.logoUrl != null && _restaurant!.logoUrl!.isNotEmpty
              ? Image.network(
                  _restaurant!.logoUrl!,
                  height: 40,
                  fit: BoxFit.contain,
                )
              : const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'Cerrar sesión',
              onPressed: _handleLogout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensaje de bienvenida y logo grande
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido,',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      Text(
                        _restaurant?.name ?? 'Restaurante',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_restaurant?.logoUrl != null && _restaurant!.logoUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Image.network(
                      _restaurant!.logoUrl!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Indicadores y columnas (resto del dashboard)
            _buildDashboardContent(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Extraer el contenido principal del dashboard (indicadores y columnas)
  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicadores
        Row(
          children: [
            Expanded(child: _buildStatCard('Pedidos Hoy', _orders.length.toString(), Icons.receipt)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Mesas Ocupadas', _tables.where((t) => t.isOccupied).length.toString() + '/' + _tables.length.toString(), Icons.table_restaurant)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Reservas Pendientes', _reservations.where((r) => r.status == 'pendiente').length.toString(), Icons.calendar_today)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Empleados', _employees.length.toString(), Icons.people)),
          ],
        ),
        const SizedBox(height: 24),
        // Responsive columns - ahora con 3 columnas
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1200;
            final isMedium = constraints.maxWidth > 800;
            
            if (isWide) {
              // Desktop: 5 columnas lado a lado
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pedidos recientes
                  Expanded(
                    child: _buildOrdersColumn(),
                  ),
                  const SizedBox(width: 8),
                  // Reservaciones
                  Expanded(
                    child: _buildReservationsColumn(),
                  ),
                  const SizedBox(width: 8),
                  // Menú
                  Expanded(
                    child: _buildMenuColumn(),
                  ),
                  const SizedBox(width: 8),
                  // Mesas del restaurante
                  Expanded(
                    child: _buildTablesColumn(),
                  ),
                  const SizedBox(width: 8),
                  // Empleados
                  Expanded(
                    child: _buildEmployeesColumn(),
                  ),
                ],
              );
            } else if (isMedium) {
              // Tablet: 3 columnas
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pedidos y Reservaciones
                  Expanded(
                    child: Column(
                      children: [
                        _buildOrdersColumn(),
                        const SizedBox(height: 24),
                        _buildReservationsColumn(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Menú y Mesas
                  Expanded(
                    child: Column(
                      children: [
                        _buildMenuColumn(),
                        const SizedBox(height: 24),
                        _buildTablesColumn(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Empleados
                  Expanded(
                    child: _buildEmployeesColumn(),
                  ),
                ],
              );
            } else {
              // Mobile: una debajo de la otra
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrdersColumn(),
                  const SizedBox(height: 24),
                  _buildReservationsColumn(),
                  const SizedBox(height: 24),
                  _buildMenuColumn(),
                  const SizedBox(height: 24),
                  _buildTablesColumn(),
                  const SizedBox(height: 24),
                  _buildEmployeesColumn(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildOrdersColumn() {
    return Column(
      key: _ordersKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedidos recientes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Filtrar:'),
            const SizedBox(width: 8),
            ToggleButtons(
              isSelected: [_orderFilter == 'recent', _orderFilter == 'status'],
              onPressed: (index) {
                setState(() {
                  _orderFilter = index == 0 ? 'recent' : 'status';
                });
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Recientes'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Por estado'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _orders.isEmpty
            ? const Center(
                child: Text('No hay pedidos registrados.'),
              )
            : SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    final cardColor = _getOrderStatusColor(order.status);
                    return Card(
                      color: cardColor.withOpacity(0.15),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.receipt, color: cardColor),
                        title: Text('Pedido #${order.orderId} - ${order.status}', style: TextStyle(color: cardColor, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cliente: ${order.userName}'),
                            Text('Total: Bs. ${order.totalAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: Text(order.createdAt.toLocal().toString().substring(0, 16)),
                        onTap: () => _advanceOrderStatus(order),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildReservationsColumn() {
    final pendingReservations = _reservations.where((r) => r.status == 'pendiente').toList();
    final completedReservations = _reservations.where((r) => r.status == 'completada' || r.status == 'cancelada').toList();
    
    return Column(
      key: _reservationsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reservaciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        
        // Reservaciones pendientes
        Text(
          'Pendientes (${pendingReservations.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 8),
        pendingReservations.isEmpty
            ? const Center(
                child: Text('No hay reservaciones pendientes.'),
              )
            : SizedBox(
                height: 150,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pendingReservations.length,
                  itemBuilder: (context, index) {
                    final reservation = pendingReservations[index];
                    return Card(
                      color: Colors.orange.withOpacity(0.15),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.schedule, color: Colors.orange[700]),
                        title: Text('Reserva #${reservation.reservationId}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700])),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cliente: ${reservation.userName}'),
                            Text('Mesa: ${reservation.tableId}'),
                            Text('Fecha: ${reservation.reservationTime.toLocal().toString().substring(0, 16)}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _completeReservation(reservation),
                          tooltip: 'Marcar como completada',
                        ),
                      ),
                    );
                  },
                ),
              ),
        
        const SizedBox(height: 16),
        
        // Reservaciones antiguas
        Text(
          'Historial (${completedReservations.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        completedReservations.isEmpty
            ? const Center(
                child: Text('No hay reservaciones en el historial.'),
              )
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: completedReservations.length,
                  itemBuilder: (context, index) {
                    final reservation = completedReservations[index];
                    final isCompleted = reservation.status == 'completada';
                    final cardColor = isCompleted ? Colors.green : Colors.red;
                    return Card(
                      color: cardColor.withOpacity(0.1),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        leading: Icon(
                          isCompleted ? Icons.check_circle : Icons.cancel,
                          color: cardColor,
                          size: 20,
                        ),
                        title: Text(
                          'Reserva #${reservation.reservationId}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cardColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cliente: ${reservation.userName}', style: TextStyle(fontSize: 11)),
                            Text('Fecha: ${reservation.reservationTime.toLocal().toString().substring(0, 16)}', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildTablesColumn() {
    return Column(
      key: _tablesKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título y botón de agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mesas del restaurante',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              onPressed: _showAddTableDialog,
              tooltip: 'Agregar mesa',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _tables.isEmpty
            ? const Center(child: Text('No hay mesas registradas.'))
            : SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _tables.length,
                  itemBuilder: (context, index) {
                    final table = _tables[index];
                    IconData icon;
                    Color color;
                    String statusText;
                    if (table.isAvailable) {
                      icon = Icons.event_seat;
                      color = Colors.green;
                      statusText = 'Disponible';
                    } else if (table.isOccupied) {
                      icon = Icons.people;
                      color = Colors.orange;
                      statusText = 'Ocupada';
                    } else if (table.isReserved) {
                      icon = Icons.event_busy;
                      color = Colors.blue;
                      statusText = 'Reservada';
                    } else {
                      icon = Icons.help;
                      color = Colors.grey;
                      statusText = table.status;
                    }
                    return Card(
                      color: color.withOpacity(0.12),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(icon, color: color),
                        title: Text('Mesa: ${table.tableName}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Capacidad: ${table.capacity}'),
                            if (table.currentUserName != null && table.currentUserName!.isNotEmpty)
                              Text('Ocupada por: ${table.currentUserName}'),
                          ],
                        ),
                        trailing: Text(statusText, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        onTap: () => _editTable(table),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildEmployeesColumn() {
    return Column(
      key: _employeesKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título y botón de agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Empleados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              onPressed: _showInviteEmployeeDialog,
              tooltip: 'Invitar empleado',
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Lista de empleados
        _employees.isEmpty
            ? const Center(
                child: Text('No hay empleados registrados.'),
              )
            : SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final employee = _employees[index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          employee.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(employee.email),
                            if (employee.phone != null) Text(employee.phone!),
                            Text(
                              'Rol: ${_getRoleDisplayName(employee.employeeRole ?? '')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.grey[600]),
                          onPressed: () => _editEmployee(employee),
                          tooltip: 'Editar empleado',
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildMenuColumn() {
    final filteredDishes = _dishes.where((dish) => _selectedCategories.contains(dish.category)).toList();
    
    return Column(
      key: _menuKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título y botón de agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Menú del restaurante',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              onPressed: _showAddDishDialog,
              tooltip: 'Agregar plato',
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Filtros de categorías
        if (_availableCategories.isNotEmpty) ...[
          Text(
            'Filtrar por categoría:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Botón "Todos"
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('Todos'),
                      selected: _selectedCategories.length == _availableCategories.length,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories = _availableCategories.toSet();
                          } else {
                            _selectedCategories.clear();
                          }
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                    ),
                  ),
                  // Categorías individuales
                  ..._availableCategories.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategories.contains(category),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Lista de platos
        filteredDishes.isEmpty
            ? const Center(
                child: Text('No hay platos en esta categoría.'),
              )
            : SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredDishes.length,
                  itemBuilder: (context, index) {
                    final dish = filteredDishes[index];
                    return Card(
                      color: dish.isAvailable ? Colors.white : Colors.grey[100],
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: dish.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  dish.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.restaurant, color: Colors.grey[600]),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.restaurant, color: Colors.grey[600]),
                              ),
                        title: Text(
                          dish.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: dish.isAvailable ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dish.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: dish.isAvailable ? Colors.grey[700] : Colors.grey[500],
                              ),
                            ),
                            Text(
                              'Bs. ${dish.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: dish.isAvailable ? AppColors.primary : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dish.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              dish.isAvailable ? Icons.check_circle : Icons.cancel,
                              color: dish.isAvailable ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: () => _editDish(dish),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(child: Text('No hay pedidos registrados.'));
    }
    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return ListTile(
          leading: const Icon(Icons.receipt),
          title: Text('Pedido #${order.orderId} - ${order.status}'),
          subtitle: Text('Cliente: ${order.userName}\nTotal: Bs. ${order.totalAmount.toStringAsFixed(2)}'),
          trailing: Text(order.createdAt.toLocal().toString().substring(0, 16)),
        );
      },
    );
  }

  Widget _buildTablesTab() {
    if (_tables.isEmpty) {
      return const Center(child: Text('No hay mesas registradas.'));
    }
    return ListView.builder(
      itemCount: _tables.length,
      itemBuilder: (context, index) {
        final table = _tables[index];
        return ListTile(
          leading: Icon(
            table.isAvailable
                ? Icons.event_seat
                : (table.isOccupied ? Icons.people : Icons.event_busy),
            color: table.isAvailable
                ? Colors.green
                : (table.isOccupied ? Colors.orange : Colors.red),
          ),
          title: Text('Mesa: ${table.tableName}'),
          subtitle: Text('Capacidad: ${table.capacity}'),
          trailing: table.currentUserName != null
              ? Text('Ocupada por: ${table.currentUserName}')
              : null,
        );
      },
    );
  }

  Widget _buildReservationsTab() {
    if (_reservations.isEmpty) {
      return const Center(child: Text('No hay reservaciones pendientes.'));
    }
    return ListView.builder(
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        return ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text('Reserva #${reservation.reservationId} - ${reservation.status}'),
          subtitle: Text('Cliente: ${reservation.userName}\nMesa: ${reservation.tableId}\nFecha: ${reservation.reservationTime.toLocal().toString().substring(0, 16)}'),
        );
      },
    );
  }

  Widget _buildEmployeesTab() {
    // Mostrar demo o mensaje si no hay usuario
    return const Center(
      child: Text(
        'Gestión de Empleados - En desarrollo',
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildReportsTab() {
    // Mostrar demo o mensaje si no hay usuario
    return const Center(
      child: Text(
        'Reportes y Estadísticas',
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt),
        label: 'Pedidos',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.table_restaurant),
        label: 'Mesas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.restaurant_menu),
        label: 'Menú',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'Empleados',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.analytics),
        label: 'Reportes',
      ),
    ];
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[600],
      onTap: _onItemTapped,
      items: items,
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mi Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentUser != null) ...[
              Text('Nombre: ${_currentUser!.name}'),
              Text('Email: ${_currentUser!.email}'),
              if (_currentUser!.phone != null)
                Text('Teléfono: ${_currentUser!.phone}'),
              if (_currentUser!.isEmployee)
                Text('Rol: ${_getRoleDisplayName(_currentUser!.employeeRole ?? '')}'),
            ],
            if (_restaurant != null)
              Text('Restaurante: ${_restaurant!.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'waiter': return 'Mesero';
      case 'cook': return 'Cocinero';
      case 'manager': return 'Gerente';
      case 'cashier': return 'Cajero';
      case 'host': return 'Anfitrión';
      default: return role;
    }
  }

  List<order_model.Order> get _filteredOrders {
    if (_orderFilter == 'recent') {
      return List.from(_orders);
    } else {
      // Ordenar por status (revision, en_cocina, listo, entregado), luego por fecha descendente
      final statusOrder = ['revision', 'en_cocina', 'listo', 'entregado'];
      final ordersCopy = List<order_model.Order>.from(_orders);
      ordersCopy.sort((a, b) {
        final statusCmp = statusOrder.indexOf(a.status).compareTo(statusOrder.indexOf(b.status));
        if (statusCmp != 0) return statusCmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return ordersCopy;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'revision':
        return Colors.blueGrey;
      case 'en_cocina':
        return Colors.orange;
      case 'listo':
        return Colors.green;
      case 'entregado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _advanceOrderStatus(order_model.Order order) async {
    final statusOrder = ['revision', 'en_cocina', 'listo', 'entregado'];
    final currentIndex = statusOrder.indexOf(order.status);
    if (currentIndex == -1 || currentIndex == statusOrder.length - 1) {
      // Ya está en el último estado o estado desconocido
      return;
    }
    final nextStatus = statusOrder[currentIndex + 1];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Avanzar estado del pedido'),
        content: Text('¿Deseas avanzar el pedido #${order.orderId} de "${order.status}" a "$nextStatus"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.orderId)
          .update({'status': nextStatus});
      setState(() {
        order.status = nextStatus;
      });
    }
  }

  void _completeReservation(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Completar reservación'),
        content: Text('¿Deseas marcar la reservación #${reservation.reservationId} como completada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservation.reservationId)
            .update({'status': 'completada'});
        
        setState(() {
          reservation.status = 'completada';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservación #${reservation.reservationId} marcada como completada'),
            backgroundColor: Colors.green[600],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar la reservación: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _showAddDishDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddDishDialog(
        restaurantId: _restaurant?.id ?? '',
        onDishAdded: () {
          _loadDishes(_restaurant?.id ?? '');
        },
      ),
    );
  }

  void _editDish(Dish dish) {
    showDialog(
      context: context,
      builder: (context) => _AddDishDialog(
        restaurantId: _restaurant?.id ?? '',
        dish: dish,
        onDishAdded: () {
          _loadDishes(_restaurant?.id ?? '');
        },
      ),
    );
  }

  void _showAddTableDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTableDialog(
        restaurantId: _restaurant?.id ?? '',
        onTableAdded: () {
          _loadTables(_restaurant?.id ?? '');
        },
      ),
    );
  }

  void _editTable(RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => _AddTableDialog(
        restaurantId: _restaurant?.id ?? '',
        table: table,
        onTableAdded: () {
          _loadTables(_restaurant?.id ?? '');
        },
      ),
    );
  }

  void _showInviteEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteEmployeeDialog(
        restaurantId: _restaurant?.id ?? '',
        restaurantName: _restaurant?.name ?? '',
        onEmployeeAdded: () {
          _loadEmployees(_restaurant?.id ?? '');
        },
      ),
    );
  }

  void _editEmployee(app_user.User employee) {
    showDialog(
      context: context,
      builder: (context) => _InviteEmployeeDialog(
        restaurantId: _restaurant?.id ?? '',
        restaurantName: _restaurant?.name ?? '',
        employee: employee,
        onEmployeeAdded: () {
          _loadEmployees(_restaurant?.id ?? '');
        },
      ),
    );
  }
}

class _AddDishDialog extends StatefulWidget {
  final String restaurantId;
  final Dish? dish;
  final VoidCallback onDishAdded;

  const _AddDishDialog({
    required this.restaurantId,
    this.dish,
    required this.onDishAdded,
  });

  @override
  State<_AddDishDialog> createState() => _AddDishDialogState();
}

class _AddDishDialogState extends State<_AddDishDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = '';
  bool _isAvailable = true;
  bool _isLoading = false;

  final List<String> _categories = [
    'Entradas',
    'Platos Principales',
    'Postres',
    'Bebidas',
    'Ensaladas',
    'Sopas',
    'Carnes',
    'Pescados',
    'Pasta',
    'Pizza',
    'Hamburguesas',
    'Sushi',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.dish != null) {
      _nameController.text = widget.dish!.name;
      _descriptionController.text = widget.dish!.description;
      _priceController.text = widget.dish!.price.toString();
      _imageUrlController.text = widget.dish!.imageUrl;
      _selectedCategory = widget.dish!.category;
      _isAvailable = widget.dish!.isAvailable;
    } else {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dish != null ? 'Editar Plato' : 'Agregar Plato'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del plato',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre del plato';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio (Bs.)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingresa un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de la imagen (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'https://ejemplo.com/imagen.jpg',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Disponible'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDish,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.dish != null ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dishData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'imageUrl': _imageUrlController.text.trim(),
        'category': _selectedCategory,
        'restaurantId': widget.restaurantId,
        'isAvailable': _isAvailable,
        'salesCount': widget.dish?.salesCount ?? 0,
        'averageRating': widget.dish?.averageRating ?? 0.0,
        'totalRatings': widget.dish?.totalRatings ?? 0,
      };

      if (widget.dish != null) {
        // Actualizar plato existente
        await FirebaseFirestore.instance
            .collection('dishes')
            .doc(widget.dish!.id)
            .update(dishData);
      } else {
        // Crear nuevo plato
        await FirebaseFirestore.instance
            .collection('dishes')
            .add(dishData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onDishAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.dish != null ? 'Plato actualizado exitosamente' : 'Plato agregado exitosamente'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _AddTableDialog extends StatefulWidget {
  final String restaurantId;
  final RestaurantTable? table;
  final VoidCallback onTableAdded;

  const _AddTableDialog({
    required this.restaurantId,
    this.table,
    required this.onTableAdded,
  });

  @override
  State<_AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<_AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tableNameController = TextEditingController();
  final _capacityController = TextEditingController();
  String _selectedStatus = 'disponible';
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'disponible',
    'ocupada',
    'reservada',
    'mantenimiento',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _tableNameController.text = widget.table!.tableName;
      _capacityController.text = widget.table!.capacity.toString();
      _selectedStatus = widget.table!.status;
    }
  }

  @override
  void dispose() {
    _tableNameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.table != null ? 'Editar Mesa' : 'Agregar Mesa'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tableNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la mesa',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Mesa 1, Terraza A, etc.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre de la mesa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacidad (personas)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la capacidad';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingresa un número válido';
                  }
                  final capacity = int.parse(value);
                  if (capacity <= 0 || capacity > 20) {
                    return 'La capacidad debe estar entre 1 y 20 personas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Estado inicial',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions.map((status) {
                  String displayName;
                  switch (status) {
                    case 'disponible':
                      displayName = 'Disponible';
                      break;
                    case 'ocupada':
                      displayName = 'Ocupada';
                      break;
                    case 'reservada':
                      displayName = 'Reservada';
                      break;
                    case 'mantenimiento':
                      displayName = 'Mantenimiento';
                      break;
                    default:
                      displayName = status;
                  }
                  return DropdownMenuItem(
                    value: status,
                    child: Text(displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value ?? 'disponible';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona un estado';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTable,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.table != null ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tableData = {
        'tableName': _tableNameController.text.trim(),
        'capacity': int.parse(_capacityController.text),
        'status': _selectedStatus,
        'restaurantId': widget.restaurantId,
        'joinCode': RestaurantTable.generateJoinCode(),
        'currentUserId': null,
        'currentUserName': null,
      };

      if (widget.table != null) {
        // Actualizar mesa existente
        await FirebaseFirestore.instance
            .collection('tables')
            .doc(widget.table!.id)
            .update(tableData);
      } else {
        // Crear nueva mesa
        await FirebaseFirestore.instance
            .collection('tables')
            .add(tableData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onTableAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.table != null ? 'Mesa actualizada exitosamente' : 'Mesa agregada exitosamente'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _InviteEmployeeDialog extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final app_user.User? employee;
  final VoidCallback onEmployeeAdded;

  const _InviteEmployeeDialog({
    required this.restaurantId,
    required this.restaurantName,
    this.employee,
    required this.onEmployeeAdded,
  });

  @override
  State<_InviteEmployeeDialog> createState() => _InviteEmployeeDialogState();
}

class _InviteEmployeeDialogState extends State<_InviteEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _personalIdController = TextEditingController();
  String _selectedRole = 'waiter';
  bool _isLoading = false;

  final List<String> _roles = [
    'waiter',
    'cook',
    'manager',
    'cashier',
    'host',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _phoneController.text = widget.employee!.phone ?? '';
      _usernameController.text = widget.employee!.email.split('@')[0];
      _selectedRole = widget.employee!.employeeRole ?? 'waiter';
      _personalIdController.text = widget.employee!.personalId ?? '';
    } else {
      // No inicializar la contraseña por defecto
      _passwordController.text = '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _personalIdController.dispose();
    super.dispose();
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'waiter': return 'Mesero';
      case 'cook': return 'Cocinero';
      case 'manager': return 'Gerente';
      case 'cashier': return 'Cajero';
      case 'host': return 'Anfitrión';
      default: return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workEmail = '${_usernameController.text}@${widget.restaurantName.toLowerCase().replaceAll(' ', '')}.com';
    
    return AlertDialog(
      title: Text(widget.employee != null ? 'Editar Empleado' : 'Invitar Empleado'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _personalIdController,
                decoration: const InputDecoration(
                  labelText: 'Cédula de identidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa la cédula de identidad';
                  }
                  final cedula = value.trim();
                  if (cedula.length < 6) {
                    return 'La cédula debe tener al menos 6 dígitos';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(cedula)) {
                    return 'La cédula debe contener solo números';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario (email sin @)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(_getRoleDisplayName(role)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value ?? 'waiter';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona un rol';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveEmployee,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.employee != null ? 'Actualizar' : 'Invitar'),
        ),
      ],
    );
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final workEmail = '${_usernameController.text}@${widget.restaurantName.toLowerCase().replaceAll(' ', '')}.com';
      final personalId = _personalIdController.text.trim();
      if (widget.employee != null) {
        // Actualizar empleado existente
        final employeeData = {
          'name': _nameController.text.trim(),
          'email': workEmail,
          'phone': _phoneController.text.trim(),
          'personalId': personalId,
          'restaurantId': widget.restaurantId,
          'isEmployee': true,
          'employeeRole': _selectedRole,
          'updatedAt': DateTime.now(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.employee!.id)
            .update(employeeData);
      } else {
        // Crear nuevo empleado
        final password = _passwordController.text;
        // Crear usuario en Firebase Auth
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: workEmail,
          password: password,
        );
        // Guardar datos adicionales en Firestore
        final employeeData = {
          'name': _nameController.text.trim(),
          'email': workEmail,
          'phone': _phoneController.text.trim(),
          'personalId': personalId,
          'password': password, // Guardar contraseña en texto plano para desarrollo
          'restaurantId': widget.restaurantId,
          'isEmployee': true,
          'employeeRole': _selectedRole,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(employeeData);
        // Mostrar información de credenciales al usuario
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Empleado Creado Exitosamente'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('El empleado ha sido registrado con las siguientes credenciales:'),
                  const SizedBox(height: 16),
                  Text('Email: $workEmail'),
                  Text('Contraseña: $password'),
                  const SizedBox(height: 8),
                  Text(
                    'El empleado debe cambiar su contraseña en su primer inicio de sesión.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onEmployeeAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.employee != null ? 'Empleado actualizado exitosamente' : 'Empleado invitado exitosamente'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 