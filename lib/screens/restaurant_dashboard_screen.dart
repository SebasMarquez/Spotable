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
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  app_user.User? _currentUser;
  Restaurant? _restaurant;
  bool _isLoading = true;
  int _selectedIndex = 0;

  int? _activeSheetIndex;

  // Listas de datos
  List<order_model.Order> _orders = [];
  List<Reservation> _reservations = [];
  List<RestaurantTable> _tables = [];
  List<Dish> _dishes = [];
  List<app_user.User> _employees = [];

  // Estados para filtros y UI
  Set<String> _selectedCategories = {};
  List<String> _availableCategories = [];
  String _orderFilter = 'recent';
  int? _expandedOrderIndex;
  final Map<String, TextEditingController> _orderDetailControllers = {};
  
  bool _isCategoriesInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndRestaurantData();
  }

  @override
  void dispose() {
    _orderDetailControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadUserAndRestaurantData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _firebaseService.getCurrentUserData();
      String? restaurantId;

      if (userData != null) {
        setState(() => _currentUser = userData);
        restaurantId = userData.restaurantId;
      }

      if (restaurantId == null || restaurantId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        restaurantId = prefs.getString('restaurant_id');
      }

      if (restaurantId != null && restaurantId.isNotEmpty) {
        final restaurantData =
            await _firebaseService.getRestaurant(restaurantId);
        if (restaurantData != null) {
          setState(
              () => _restaurant = Restaurant.fromMap(restaurantData, restaurantId));
        }
        await _loadAllRestaurantData(restaurantId);
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllRestaurantData(String restaurantId) async {
    await Future.wait([
      _loadOrders(restaurantId),
      _loadReservations(restaurantId),
      _loadTables(restaurantId),
      _loadDishes(restaurantId),
      _loadEmployees(restaurantId),
    ]);
  }

  Future<void> _loadOrders(String restaurantId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .get();
    if (mounted) {
      setState(() {
        _orders = snapshot.docs
            .map((doc) => order_model.Order.fromMap(doc.data(), doc.id))
            .toList();
      });
    }
  }

  Future<void> _loadReservations(String restaurantId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('reservationTime')
        .get();
    if (mounted) {
      setState(() {
        _reservations = snapshot.docs
            .map((doc) => Reservation.fromMap(doc.data(), doc.id))
            .toList();
      });
    }
  }

  Future<void> _loadTables(String restaurantId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tables')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('tableName')
        .get();
    if (mounted) {
      setState(() {
        _tables = snapshot.docs
            .map((doc) => RestaurantTable.fromMap(doc.data(), doc.id))
            .toList();
      });
    }
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
    
    if (mounted) {
      setState(() {
        _dishes = dishes;
        _availableCategories = dishes.map((dish) => dish.category).toSet().toList()..sort();

        if (!_isCategoriesInitialized) {
          _selectedCategories = _availableCategories.toSet();
          _isCategoriesInitialized = true;
        } else {
          _selectedCategories.removeWhere((cat) => !_availableCategories.contains(cat));
        }
      });
    }
  }

  Future<void> _loadEmployees(String restaurantId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isEmployee', isEqualTo: true)
        .orderBy('name')
        .get();
    
    if (mounted) {
      setState(() {
        _employees = snapshot.docs
            .map((doc) => app_user.User.fromMap(doc.data(), doc.id))
            .toList();
      });
    }
  }

  void _handleLogout() async {
    try {
      await _firebaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  void _onItemTapped(int index) {
    if (_activeSheetIndex == index) {
      setState(() {
        _activeSheetIndex = null;
        _selectedIndex = 0;
      });
      return;
    }

    if (index == 0) {
      setState(() {
        _activeSheetIndex = null;
        _selectedIndex = 0;
      });
    } else {
      setState(() {
        _activeSheetIndex = index;
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_restaurant == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error: Restaurante no encontrado'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleLogout,
                child: const Text('Volver al inicio'),
              )
            ],
          ),
        ),
      );
    }

    // CORREGIDO: La estructura del layout principal
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: Stack(
        children: [
          // Capa 1: Contenido de fondo (siempre visible)
          _buildHomeContent(),
          
          // Capa 2: Hoja desplegable (se muestra encima del contenido de fondo)
          if (_activeSheetIndex != null) _buildDraggableSheet(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo restaurante
            if (_restaurant?.logoUrl != null && _restaurant!.logoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Image.network(
                  _restaurant!.logoUrl!,
                  height: 56,
                  width: 56,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant, color: AppColors.primary, size: 36),
              ),
            // Bienvenida
            Expanded(
              child: Text(
                '¡Bienvenido, ${_restaurant?.name ?? 'Restaurante'}!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
            // Logo app centrado (absoluto)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 80), // Espacio reservado
                Positioned(
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/Logo_spotable.png',
                    height: 36,
                  ),
                ),
              ],
            ),
            // Logout
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'Cerrar sesión',
              onPressed: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndicators(),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Pedidos Hoy', _orders.length.toString(),
                    Icons.receipt)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                    'Mesas Ocupadas',
                    '${_tables.where((t) => t.isOccupied).length}/${_tables.length}',
                    Icons.table_restaurant)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'Reservas Pendientes',
                    _reservations
                        .where((r) => r.status == 'pendiente')
                        .length
                        .toString(),
                    Icons.calendar_today)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                    'Empleados', _employees.length.toString(), Icons.people)),
          ],
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
                shadows: [
                  Shadow(
                      color: Colors.black26, offset: Offset(0, 0), blurRadius: 2)
                ],
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                shadows: const [
                  Shadow(
                      color: Colors.black26, offset: Offset(0, 0), blurRadius: 2)
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[600],
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Pedidos'),
        BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant), label: 'Mesas'),
        BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu), label: 'Menú'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Empleados'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reportes'),
      ],
    );
  }

  Widget _buildDraggableSheet() {
    final key = ValueKey<int?>(_activeSheetIndex);

    return DraggableScrollableSheet(
      key: key,
      initialChildSize: 0.6,
      minChildSize: 0.2,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                blurRadius: 10.0,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getSheetTitle(),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _activeSheetIndex = null;
                          _selectedIndex = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: _getSheetContent(scrollController),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSheetTitle() {
    switch (_activeSheetIndex) {
      case 1:
        return 'Pedidos';
      case 2:
        return 'Mesas';
      case 3:
        return 'Menú';
      case 4:
        return 'Empleados';
      case 5:
        return 'Reportes';
      default:
        return '';
    }
  }

  Widget _getSheetContent(ScrollController scrollController) {
    switch (_activeSheetIndex) {
      case 1:
        return _buildOrdersContent(scrollController);
      case 2:
        return _buildTablesContent(scrollController);
      case 3:
        return _buildMenuContent(scrollController);
      case 4:
        return _buildEmployeesContent(scrollController);
      case 5:
        return _buildReportsContent(scrollController);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOrdersContent(ScrollController scrollController) {
    final ordersToShow = _filteredOrders;
    if (ordersToShow.isEmpty) {
      return const Center(child: Text('No hay pedidos registrados.'));
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Filtrar:'),
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
        ...ordersToShow.map((order) {
          final index = ordersToShow.indexOf(order);
          return _buildOrderCard(order, index);
        }).toList(),
      ],
    );
  }

  Widget _buildTablesContent(ScrollController scrollController) {
    if (_tables.isEmpty) {
      return const Center(child: Text('No hay mesas registradas.'));
    }
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar Mesa'),
            onPressed: _showAddTableDialog,
          ),
        ),
        const SizedBox(height: 8),
        ..._tables.map((table) {
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
              title: Text('Mesa: ${table.tableName}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      shadows: const [
                        Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 0),
                            blurRadius: 2)
                      ])),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Capacidad: ${table.capacity}',
                      style: const TextStyle(shadows: [
                        Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 0),
                            blurRadius: 2)
                      ])),
                  if (table.currentUserName != null && table.currentUserName!.isNotEmpty)
                    Text(
                      'Ocupada por: ${table.currentUserName!.join(', ')}',
                      style: const TextStyle(shadows: [
                        Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 0),
                            blurRadius: 2)
                      ])),
                ],
              ),
              trailing: Text(statusText,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 0),
                            blurRadius: 2)
                      ])),
              onTap: () => _editTable(table),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmployeesContent(ScrollController scrollController) {
    if (_employees.isEmpty) {
      return const Center(child: Text('No hay empleados registrados.'));
    }
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Invitar Empleado'),
            onPressed: _showInviteEmployeeDialog,
          ),
        ),
        const SizedBox(height: 8),
        ..._employees.map((employee) {
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              title: Text(employee.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 0),
                            blurRadius: 2)
                      ])),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.email,
                      style: const TextStyle(shadows: [
                        Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 0),
                            blurRadius: 2)
                      ])),
                  if (employee.phone != null)
                    Text(employee.phone!,
                        style: const TextStyle(shadows: [
                          Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 0),
                              blurRadius: 2)
                        ])),
                  Text(
                    'Rol: ${_getRoleDisplayName(employee.employeeRole ?? '')}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        shadows: const [
                          Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 0),
                              blurRadius: 2)
                        ]),
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
        }).toList(),
      ],
    );
  }

  Widget _buildMenuContent(ScrollController scrollController) {
    final filteredDishes = _dishes
        .where((dish) => _selectedCategories.contains(dish.category))
        .toList();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar Plato'),
            onPressed: _showAddDishDialog,
          ),
        ),
        const SizedBox(height: 8),
        if (_availableCategories.isNotEmpty) ...[
          const Text('Filtrar por categoría:',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 0),
                        blurRadius: 2)
                  ])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected:
                    _selectedCategories.length == _availableCategories.length,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories = _availableCategories.toSet();
                    } else {
                      _selectedCategories.clear();
                    }
                  });
                },
              ),
              ..._availableCategories.map((category) => FilterChip(
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
                  )),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (filteredDishes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('No hay platos en esta categoría.')),
          )
        else
          ...filteredDishes.map((dish) {
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
                              child: Icon(Icons.restaurant,
                                  color: Colors.grey[600]),
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
                        child:
                            Icon(Icons.restaurant, color: Colors.grey[600]),
                      ),
                title: Text(
                  dish.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: dish.isAvailable ? Colors.black : Colors.grey[600],
                    shadows: const [
                      Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 0),
                          blurRadius: 2)
                    ],
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
                        color: dish.isAvailable
                            ? Colors.grey[700]
                            : Colors.grey[500],
                        shadows: const [
                          Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 0),
                              blurRadius: 2)
                        ],
                      ),
                    ),
                    Text(
                      '\$ ${dish.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: dish.isAvailable
                            ? AppColors.primary
                            : Colors.grey[500],
                        shadows: const [
                          Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 0),
                              blurRadius: 2)
                        ],
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
                        shadows: const [
                          Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 0),
                              blurRadius: 2)
                        ],
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
          }),
      ],
    );
  }

  Widget _buildReportsContent(ScrollController scrollController) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'La sección de Reportes está en desarrollo.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildOrderCard(order_model.Order order, int index) {
    final isExpanded = _expandedOrderIndex == index;
    final cardColor = _getOrderStatusColor(order.status);
    _orderDetailControllers[order.orderId] ??=
        TextEditingController(text: order.detail ?? '');

    return Card(
      color: cardColor.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.receipt, color: cardColor),
            title: Text('Pedido #${order.orderId} - ${order.status}',
                style: TextStyle(
                    color: cardColor, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: ${order.userName}',
                    style: const TextStyle(shadows: [
                      Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 0),
                          blurRadius: 2)
                    ])),
                Text('Total: \$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(shadows: [
                      Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 0),
                          blurRadius: 2)
                    ])),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: cardColor),
                  onPressed: () {
                    setState(() {
                      _expandedOrderIndex = isExpanded ? null : index;
                    });
                  },
                  tooltip: isExpanded ? 'Ocultar detalle' : 'Ver detalle',
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.sync),
                  color: cardColor,
                  tooltip: 'Avanzar estado',
                  onPressed: () => _advanceOrderStatus(order),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text('Platos:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 0),
                                blurRadius: 2)
                          ])),
                  const SizedBox(height: 6),
                  ...order.items.map((item) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                                  '${item.dishName} x${item.quantity}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 0),
                                            blurRadius: 2)
                                      ]))),
                          Text(
                              '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 0),
                                        blurRadius: 2)
                                  ])),
                        ],
                      )),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 0),
                                    blurRadius: 2)
                              ])),
                      Text('\$${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 0),
                                    blurRadius: 2)
                              ])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Tipo de orden:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(
                        order.type == 'dine-in' ? 'Comer en restaurante' : order.type == 'pickup' ? 'Pick Up' : order.type == 'delivery' ? 'Domicilio' : order.type,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (order.type == 'dine-in' && (order.tableName != null && order.tableName!.isNotEmpty)) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.table_restaurant, size: 20),
                        const SizedBox(width: 8),
                        Text('Mesa: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(order.tableName!),
                      ],
                    ),
                  ],
                  if (order.type == 'delivery' && order.shippingAddress != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_shipping, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((order.shippingAddress?['label'] ?? '').toString().isNotEmpty)
                                Text(order.shippingAddress?['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(order.shippingAddress?['address'] ?? ''),
                              if ((order.shippingAddress?['details'] ?? '').toString().isNotEmpty)
                                Text(order.shippingAddress?['details'], style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (order.type == 'dine-in' && order.handledByEmployeeName != null && order.handledByEmployeeName!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20),
                        const SizedBox(width: 8),
                        Text('Atiende: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(order.handledByEmployeeName!),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _orderDetailControllers[order.orderId],
                    decoration: const InputDecoration(
                      labelText: 'Detalle de la orden (visible al personal)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final detail =
                            _orderDetailControllers[order.orderId]?.text ?? '';
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(order.orderId)
                            .update({'detail': detail});
                        setState(() {
                          order.detail = detail;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Detalle guardado'),
                                backgroundColor: Colors.green),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar detalle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    Color cardColor;
    Color iconColor;
    IconData iconData;
    String? tooltip;
    IconData? actionIcon;
    Color? actionColor;
    VoidCallback? onAction;

    switch (reservation.status) {
      case 'pendiente':
        cardColor = Colors.orange.withOpacity(0.15);
        iconColor = Colors.orange[700]!;
        iconData = Icons.schedule;
        actionIcon = Icons.check;
        actionColor = Colors.blue;
        tooltip = 'Confirmar reservación';
        onAction = () => _advanceReservationStatus(reservation);
        break;
      case 'confirmada':
        cardColor = Colors.blue.withOpacity(0.12);
        iconColor = Colors.blue;
        iconData = Icons.check;
        actionIcon = Icons.check_circle;
        actionColor = Colors.green;
        tooltip = 'Marcar como completada';
        onAction = () => _advanceReservationStatus(reservation);
        break;
      case 'completada':
        cardColor = Colors.green.withOpacity(0.1);
        iconColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'cancelada':
        cardColor = Colors.red.withOpacity(0.1);
        iconColor = Colors.red;
        iconData = Icons.cancel;
        break;
      default:
        cardColor = Colors.grey.withOpacity(0.1);
        iconColor = Colors.grey;
        iconData = Icons.help;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(iconData, color: iconColor, size: 28),
        title: Text('Reserva #${reservation.reservationId}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: iconColor,
                shadows: const [
                  Shadow(
                      color: Colors.black26, offset: Offset(0, 0), blurRadius: 2)
                ])),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${reservation.userName}',
                style: const TextStyle(shadows: [
                  Shadow(
                      color: Colors.black26, offset: Offset(0, 0), blurRadius: 2)
                ])),
            Text('Mesa: ${reservation.tableId}',
                style: const TextStyle(shadows: [
                  Shadow(
                      color: Colors.black26, offset: Offset(0, 0), blurRadius: 2)
                ])),
            Text(
                'Fecha: ${reservation.reservationTime.toLocal().toString().substring(0, 16)}',
                style: const TextStyle(shadows: [
                  Shadow(
                      color: Colors.black26, offset: Offset(0, 0), blurRadius: 2)
                ])),
          ],
        ),
        trailing: actionIcon != null
            ? IconButton(
                icon: Icon(actionIcon, color: actionColor, size: 28),
                onPressed: onAction,
                tooltip: tooltip,
              )
            : null,
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'waiter':
        return 'Mesero';
      case 'cook':
        return 'Cocinero';
      case 'manager':
        return 'Gerente';
      case 'cashier':
        return 'Cajero';
      case 'host':
        return 'Anfitrión';
      default:
        return role;
    }
  }

  List<order_model.Order> get _filteredOrders {
    if (_orderFilter == 'recent') {
      return List.from(_orders);
    } else {
      final statusOrder = ['revision', 'en_cocina', 'listo', 'entregado'];
      final ordersCopy = List<order_model.Order>.from(_orders);
      ordersCopy.sort((a, b) {
        final statusCmp =
            statusOrder.indexOf(a.status).compareTo(statusOrder.indexOf(b.status));
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
      return;
    }
    final nextStatus = statusOrder[currentIndex + 1];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avanzar estado del pedido'),
        content: Text(
            '¿Deseas avanzar el pedido #${order.orderId} de "${order.status}" a "$nextStatus"?'),
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
      _loadOrders(_restaurant!.id);
    }
  }

  void _advanceReservationStatus(Reservation reservation) async {
    String? nextStatus;
    String dialogTitle = '';
    String dialogContent = '';
    if (reservation.status == 'pendiente') {
      nextStatus = 'confirmada';
      dialogTitle = 'Confirmar reservación';
      dialogContent =
          '¿Deseas confirmar la reservación #${reservation.reservationId}?';
    } else if (reservation.status == 'confirmada') {
      nextStatus = 'completada';
      dialogTitle = 'Completar reservación';
      dialogContent =
          '¿Deseas marcar la reservación #${reservation.reservationId} como completada?';
    }
    if (nextStatus == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
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
            .update({'status': nextStatus});
        _loadReservations(_restaurant!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Reservación #${reservation.reservationId} marcada como $nextStatus'),
              backgroundColor: Colors.green[600],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar la reservación: $e'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    }
  }

  void _showAddDishDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddDishDialog(
        restaurantId: _restaurant?.id ?? '',
        onDishAdded: () => _loadDishes(_restaurant!.id),
      ),
    );
  }

  void _editDish(Dish dish) {
    showDialog(
      context: context,
      builder: (context) => _AddDishDialog(
        restaurantId: _restaurant?.id ?? '',
        dish: dish,
        onDishAdded: () => _loadDishes(_restaurant!.id),
      ),
    );
  }

  void _showAddTableDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTableDialog(
        restaurantId: _restaurant?.id ?? '',
        onTableAdded: () => _loadTables(_restaurant!.id),
      ),
    );
  }

  void _editTable(RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => _AddTableDialog(
        restaurantId: _restaurant?.id ?? '',
        table: table,
        onTableAdded: () => _loadTables(_restaurant!.id),
      ),
    );
  }

  void _showInviteEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteEmployeeDialog(
        restaurantId: _restaurant?.id ?? '',
        restaurantName: _restaurant?.name ?? '',
        onEmployeeAdded: () => _loadEmployees(_restaurant!.id),
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
        onEmployeeAdded: () => _loadEmployees(_restaurant!.id),
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
    'Entradas', 'Platos Principales', 'Postres', 'Bebidas', 'Ensaladas',
    'Sopas', 'Carnes', 'Pescados', 'Pasta', 'Pizza', 'Hamburguesas', 'Sushi', 'Otros',
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
                decoration: const InputDecoration(labelText: 'Nombre del plato', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Ingresa el nombre del plato' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Ingresa una descripción' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio (Bs.)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa el precio';
                  if (double.tryParse(value) == null) return 'Ingresa un precio válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL de la imagen (opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value ?? ''),
                validator: (value) => value == null || value.isEmpty ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Disponible'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDish,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.dish != null ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

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
        await FirebaseFirestore.instance.collection('dishes').doc(widget.dish!.id).update(dishData);
      } else {
        await FirebaseFirestore.instance.collection('dishes').add(dishData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onDishAdded();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.dish != null ? 'Plato actualizado' : 'Plato agregado'),
          backgroundColor: Colors.green[600],
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red[600]));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _AddTableDialog extends StatefulWidget {
  final String restaurantId;
  final RestaurantTable? table;
  final VoidCallback onTableAdded;

  const _AddTableDialog({required this.restaurantId, this.table, required this.onTableAdded});

  @override
  State<_AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<_AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tableNameController = TextEditingController();
  final _capacityController = TextEditingController();
  String _selectedStatus = 'disponible';
  bool _isLoading = false;
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  List<app_user.User> _employees = [];

  final List<String> _statusOptions = ['disponible', 'ocupada', 'reservada', 'mantenimiento'];

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _tableNameController.text = widget.table!.tableName;
      _capacityController.text = widget.table!.capacity.toString();
      _selectedStatus = widget.table!.status;
      _selectedEmployeeId = widget.table!.assignedEmployeeId;
      _selectedEmployeeName = widget.table!.assignedEmployeeName;
    }
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('restaurantId', isEqualTo: widget.restaurantId)
        .where('isEmployee', isEqualTo: true)
        .orderBy('name')
        .get();
    setState(() {
      _employees = snap.docs.map((doc) => app_user.User.fromMap(doc.data(), doc.id)).toList();
    });
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
                decoration: const InputDecoration(labelText: 'Nombre de la mesa', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Ingresa el nombre de la mesa' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacidad (personas)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa la capacidad';
                  if (int.tryParse(value) == null) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Estado inicial', border: OutlineInputBorder()),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status[0].toUpperCase() + status.substring(1)));
                }).toList(),
                onChanged: (value) => setState(() => _selectedStatus = value ?? 'disponible'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEmployeeId,
                decoration: const InputDecoration(labelText: 'Empleado asignado', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                  ..._employees.map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedEmployeeId = value;
                    _selectedEmployeeName = _employees.firstWhere(
                      (e) => e.id == value,
                      orElse: () => app_user.User(
                        id: '',
                        name: '',
                        email: '',
                        role: '',
                        isEmployee: true,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        isActive: true,
                        preferences: const {},
                        addresses: const [],
                        paymentMethods: const [],
                      ),
                    ).name;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTable,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.table != null ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final tableData = {
        'tableName': _tableNameController.text.trim(),
        'capacity': int.parse(_capacityController.text),
        'status': _selectedStatus,
        'restaurantId': widget.restaurantId,
        'currentUserId': widget.table?.currentUserId,
        'currentUserName': widget.table?.currentUserName,
        'assignedEmployeeId': _selectedEmployeeId,
        'assignedEmployeeName': _selectedEmployeeName,
      };

      if (widget.table != null) {
        await FirebaseFirestore.instance.collection('tables').doc(widget.table!.id).update(tableData);
      } else {
        tableData['joinCode'] = RestaurantTable.generateJoinCode();
        await FirebaseFirestore.instance.collection('tables').add(tableData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onTableAdded();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.table != null ? 'Mesa actualizada' : 'Mesa agregada'),
          backgroundColor: Colors.green[600],
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red[600]));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  final List<String> _roles = ['waiter', 'cook', 'manager', 'cashier', 'host'];

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _phoneController.text = widget.employee!.phone ?? '';
      _usernameController.text = widget.employee!.email.split('@')[0];
      _selectedRole = widget.employee!.employeeRole ?? 'waiter';
      _personalIdController.text = widget.employee!.personalId ?? '';
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
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _personalIdController,
                decoration: const InputDecoration(labelText: 'Cédula de identidad', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa la cédula' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Usuario (email sin @)', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el usuario' : null,
              ),
              const SizedBox(height: 12),
              if (widget.employee == null)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) {
                    if (widget.employee == null && (value == null || value.isEmpty)) return 'Ingresa una contraseña';
                    if (value != null && value.isNotEmpty && value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(_getRoleDisplayName(role)))).toList(),
                onChanged: (value) => setState(() => _selectedRole = value ?? 'waiter'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveEmployee,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.employee != null ? 'Actualizar' : 'Invitar'),
        ),
      ],
    );
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final workEmail = '${_usernameController.text.trim()}@${widget.restaurantName.toLowerCase().replaceAll(' ', '')}.com';
      
      if (widget.employee != null) {
        // Actualizar empleado
        final employeeData = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'personalId': _personalIdController.text.trim(),
          'employeeRole': _selectedRole,
          'updatedAt': DateTime.now(),
        };
        await FirebaseFirestore.instance.collection('users').doc(widget.employee!.id).update(employeeData);
      } else {
        // Crear nuevo empleado
        final password = _passwordController.text;
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: workEmail, password: password);
        
        final employeeData = {
          'name': _nameController.text.trim(),
          'email': workEmail,
          'phone': _phoneController.text.trim(),
          'personalId': _personalIdController.text.trim(),
          'restaurantId': widget.restaurantId,
          'isEmployee': true,
          'employeeRole': _selectedRole,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        };
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(employeeData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onEmployeeAdded();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.employee != null ? 'Empleado actualizado' : 'Empleado invitado'),
          backgroundColor: Colors.green[600],
        ));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error de autenticación: ${e.message}'),
          backgroundColor: Colors.red[600],
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red[600]));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
