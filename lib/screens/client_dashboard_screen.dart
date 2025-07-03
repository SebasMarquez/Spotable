import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';
import '../models/dish.dart';
import '../models/user.dart' as app_user;
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  app_user.User? _currentUser;
  List<Restaurant> _restaurants = [];
  Map<String, List<Dish>> _menus = {};
  bool _isLoading = true;
  String? _errorMessage;
  String? _expandedRestaurantId;
  List<Map<String, dynamic>> _myReservations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final user = await _firebaseService.getCurrentUserData();
      final restaurantsSnap = await FirebaseFirestore.instance.collection('restaurants').where('isActive', isEqualTo: true).get();
      final restaurants = restaurantsSnap.docs.map((doc) => Restaurant.fromMap(doc.data(), doc.id)).toList();
      final menus = <String, List<Dish>>{};
      for (final r in restaurants) {
        final dishesSnap = await FirebaseFirestore.instance.collection('dishes').where('restaurantId', isEqualTo: r.id).get();
        menus[r.id] = dishesSnap.docs.map((d) => Dish.fromMap(d.data(), d.id)).toList();
      }
      // Cargar reservaciones del usuario
      List<Map<String, dynamic>> myReservations = [];
      if (user != null) {
        final resSnap = await FirebaseFirestore.instance.collection('reservations').where('userId', isEqualTo: user.id).orderBy('reservationTime', descending: true).get();
        myReservations = resSnap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      }
      setState(() {
        _currentUser = user;
        _restaurants = restaurants;
        _menus = menus;
        _myReservations = myReservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  void _showReservationModal(Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ReservationForm(
        restaurant: restaurant,
        user: _currentUser!,
        onReservationMade: () async {
          Navigator.of(context).pop();
          await _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Reservación realizada con éxito!'), backgroundColor: Colors.green[600]),
          );
        },
      ),
    );
  }

  void _showCancelReservationDialog(Map<String, dynamic> reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reservación'),
        content: Text('¿Seguro que deseas cancelar la reservación en ${reservation['restaurantName'] ?? ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('reservations').doc(reservation['id']).delete();
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservación cancelada'), backgroundColor: Colors.orange[700]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Saludo
                        if (_currentUser != null) ...[
                          Text('¡Hola, ${_currentUser!.name.split(' ').first}!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 8),
                        ],
                        Text('Restaurantes disponibles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                        const SizedBox(height: 16),
                        // Lista de restaurantes
                        ..._restaurants.map((r) => Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (r.logoUrl != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(r.logoUrl!, width: 60, height: 60, fit: BoxFit.cover),
                                          ),
                                        if (r.logoUrl == null)
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.restaurant, size: 36, color: AppColors.primary),
                                          ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(r.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(r.categories.join(', '), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.star, color: Colors.amber[700], size: 18),
                                                  const SizedBox(width: 4),
                                                  Text(r.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: r.isOpen ? Colors.green[100] : Colors.red[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(r.isOpen ? 'Abierto' : 'Cerrado', style: TextStyle(color: r.isOpen ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.w600, fontSize: 12)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Botones
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _expandedRestaurantId = _expandedRestaurantId == r.id ? null : r.id;
                                            });
                                          },
                                          icon: Icon(_expandedRestaurantId == r.id ? Icons.expand_less : Icons.restaurant_menu),
                                          label: Text(_expandedRestaurantId == r.id ? 'Ocultar Menú' : 'Ver Menú'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        OutlinedButton.icon(
                                          onPressed: () => _showReservationModal(r),
                                          icon: const Icon(Icons.event_available),
                                          label: const Text('Reservar'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: BorderSide(color: AppColors.primary, width: 2),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Menú expandido
                                    if (_expandedRestaurantId == r.id) ...[
                                      const SizedBox(height: 16),
                                      Text('Menú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      const SizedBox(height: 8),
                                      if ((_menus[r.id]?.isEmpty ?? true))
                                        const Text('Este restaurante aún no tiene platos registrados.'),
                                      if ((_menus[r.id]?.isNotEmpty ?? false))
                                        ..._menus[r.id]!.map((dish) => ListTile(
                                              leading: dish.imageUrl != null
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(dish.imageUrl!, width: 48, height: 48, fit: BoxFit.cover),
                                                    )
                                                  : Container(
                                                      width: 48,
                                                      height: 48,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Icon(Icons.fastfood, color: AppColors.primary),
                                                    ),
                                              title: Text(dish.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              subtitle: Text(dish.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                              trailing: Text('Bs. ${dish.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            )),
                                    ],
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 32),
                        // Reservaciones del usuario
                        if (_myReservations.isNotEmpty) ...[
                          Text('Mis reservaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          ..._myReservations.map((res) => Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: const Icon(Icons.event, color: AppColors.primary),
                                  title: Text(res['restaurantName'] ?? ''),
                                  subtitle: Text('Fecha: ${res['reservationTime'] != null ? (res['reservationTime'] as Timestamp).toDate().toString().substring(0, 16) : ''}\nPersonas: ${res['partySize'] ?? res['people'] ?? ''}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () => _showCancelReservationDialog(res),
                                    tooltip: 'Cancelar reservación',
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
        ),
      );
  }
}

class _ReservationForm extends StatefulWidget {
  final Restaurant restaurant;
  final app_user.User user;
  final VoidCallback onReservationMade;
  const _ReservationForm({required this.restaurant, required this.user, required this.onReservationMade});

  @override
  State<_ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<_ReservationForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDateTime;
  int _people = 2;
  String? _comments;
  bool _isLoading = false;
  late TextEditingController _dateTimeController;
  List<Map<String, dynamic>> _availableTables = [];
  String? _selectedTableId;
  bool _isLoadingTables = false;

  // Configuración de reservaciones
  static const int _reservationDurationHours = 2; // Duración de la reservación
  static const int _cleaningTimeMinutes = 5; // Tiempo de limpieza entre reservaciones

  @override
  void initState() {
    super.initState();
    _dateTimeController = TextEditingController();
  }

  @override
  void dispose() {
    _dateTimeController.dispose();
    super.dispose();
  }

  void _updateDateTimeController() {
    _dateTimeController.text = _selectedDateTime != null
        ? '${_selectedDateTime!.toLocal()}'.substring(0, 16)
        : '';
  }

  Future<void> _loadAvailableTables() async {
    if (_selectedDateTime == null) return;
    
    setState(() {
      _isLoadingTables = true;
      _availableTables = [];
      _selectedTableId = null;
    });

    try {
      // 1. Cargar todas las mesas del restaurante
      final tablesSnap = await FirebaseFirestore.instance
          .collection('tables')
          .where('restaurantId', isEqualTo: widget.restaurant.id)
          .get();
      
      final tables = tablesSnap.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // 2. Cargar reservaciones existentes para el restaurante en ese día
      final startOfDay = DateTime(_selectedDateTime!.year, _selectedDateTime!.month, _selectedDateTime!.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final reservationsSnap = await FirebaseFirestore.instance
          .collection('reservations')
          .where('restaurantId', isEqualTo: widget.restaurant.id)
          .where('reservationTime', isGreaterThanOrEqualTo: startOfDay)
          .where('reservationTime', isLessThan: endOfDay)
          .get();

      final existingReservations = reservationsSnap.docs.map((doc) => doc.data()).toList();

      // 3. Verificar disponibilidad de cada mesa
      final availableTables = <Map<String, dynamic>>[];
      
      for (final table in tables) {
        final tableId = table['id'] as String;
        final capacity = table['capacity'] as int? ?? 4;
        
        // Verificar si la mesa tiene capacidad suficiente
        if (capacity < _people) continue;
        
        // Verificar si hay reservaciones conflictivas
        final isAvailable = _isTableAvailableForTime(
          tableId,
          _selectedDateTime!,
          existingReservations,
        );
        
        if (isAvailable) {
          availableTables.add({
            ...table,
            'available': true,
          });
        }
      }

      setState(() {
        _availableTables = availableTables;
        _isLoadingTables = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTables = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mesas: $e'), backgroundColor: Colors.red[600]),
      );
    }
  }

  bool _isTableAvailableForTime(
    String tableId,
    DateTime requestedTime,
    List<Map<String, dynamic>> existingReservations,
  ) {
    // Calcular ventana de tiempo de la reservación solicitada
    final reservationStart = requestedTime;
    final reservationEnd = requestedTime.add(Duration(hours: _reservationDurationHours));
    
    // Verificar cada reservación existente para esta mesa
    for (final reservation in existingReservations) {
      if (reservation['tableId'] != tableId) continue;
      
      final existingStart = (reservation['reservationTime'] as Timestamp).toDate();
      final existingEnd = existingStart.add(Duration(hours: _reservationDurationHours));
      
      // Verificar si hay conflicto de horarios
      // Incluye tiempo de limpieza
      final existingEndWithCleaning = existingEnd.add(Duration(minutes: _cleaningTimeMinutes));
      final requestedStartWithCleaning = reservationStart.add(Duration(minutes: _cleaningTimeMinutes));
      
      if (reservationStart.isBefore(existingEndWithCleaning) && 
          reservationEnd.isAfter(existingStart)) {
        return false; // Hay conflicto
      }
    }
    
    return true; // Mesa disponible
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reservar en ${widget.restaurant.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Fecha y hora',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                controller: _dateTimeController,
                onTap: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 60)),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _updateDateTimeController();
                        _selectedTableId = null; // Reset mesa seleccionada
                      });
                      // Cargar mesas disponibles
                      await _loadAvailableTables();
                    }
                  }
                },
                validator: (value) {
                  if (_selectedDateTime == null) {
                    return 'Selecciona fecha y hora';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '2',
                decoration: const InputDecoration(
                  labelText: 'Número de personas',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _people = int.tryParse(value) ?? 2;
                    _selectedTableId = null; // Reset mesa seleccionada
                  });
                  // Recargar mesas si ya hay fecha seleccionada
                  if (_selectedDateTime != null) {
                    _loadAvailableTables();
                  }
                },
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  if (n == null || n < 1) {
                    return 'Ingresa un número válido de personas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Selección de mesa
              if (_selectedDateTime != null) ...[
                Text('Mesa disponible', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                if (_isLoadingTables)
                  const Center(child: CircularProgressIndicator())
                else if (_availableTables.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No hay mesas disponibles para ${_people} personas en este horario. Intenta con otro horario o menos personas.',
                            style: TextStyle(color: Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._availableTables.map((table) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: RadioListTile<String>(
                      title: Text('Mesa ${table['tableName']}'),
                      subtitle: Text('Capacidad: ${table['capacity']} personas'),
                      value: table['id'],
                      groupValue: _selectedTableId,
                      onChanged: (value) {
                        setState(() {
                          _selectedTableId = value;
                        });
                      },
                    ),
                  )),
                const SizedBox(height: 16),
              ],
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Comentarios (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 2,
                onChanged: (value) => _comments = value,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || _selectedTableId == null) ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isLoading = true);
                    try {
                      await FirebaseFirestore.instance.collection('reservations').add({
                        'userId': widget.user.id,
                        'userName': widget.user.name,
                        'restaurantId': widget.restaurant.id,
                        'restaurantName': widget.restaurant.name,
                        'tableId': _selectedTableId,
                        'reservationTime': _selectedDateTime,
                        'partySize': _people,
                        'comments': _comments,
                        'createdAt': DateTime.now(),
                        'status': 'pendiente',
                      });
                      widget.onReservationMade();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al reservar: $e'), backgroundColor: Colors.red[600]),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar reserva', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 