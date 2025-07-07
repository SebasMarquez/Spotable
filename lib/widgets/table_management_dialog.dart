import 'package:flutter/material.dart';
import '../models/table.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../models/user.dart' as app_user;

class TableManagementDialog extends StatefulWidget {
  final String restaurantId;

  const TableManagementDialog({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<TableManagementDialog> createState() => _TableManagementDialogState();
}

class _TableManagementDialogState extends State<TableManagementDialog> {
  final FirebaseService _firebaseService = FirebaseService();
  List<RestaurantTable> _tables = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'todos';
  List<app_user.User> _employees = [];
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _loadEmployees();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final tablesData = await _firebaseService.getRestaurantTables(widget.restaurantId);
      setState(() {
        _tables = tablesData
            .map((data) => RestaurantTable.fromMap(data, data['id'] ?? ''))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar mesas: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _loadEmployees() async {
    final service = FirebaseService();
    final employees = await service.getRestaurantEmployees(widget.restaurantId);
    if (mounted) setState(() => _employees = employees);
  }

  List<RestaurantTable> get _filteredTables {
    if (_selectedStatusFilter == 'todos') return _tables;
    return _tables.where((table) => table.status == _selectedStatusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.table_restaurant, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gestión de Mesas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Filters and Actions
                    Row(
                      children: [
                        // Status Filter
                        DropdownButton<String>(
                          value: _selectedStatusFilter,
                          items: [
                            const DropdownMenuItem(value: 'todos', child: Text('Todas')),
                            const DropdownMenuItem(value: 'disponible', child: Text('Disponibles')),
                            const DropdownMenuItem(value: 'ocupada', child: Text('Ocupadas')),
                            const DropdownMenuItem(value: 'reservada', child: Text('Reservadas')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatusFilter = value!;
                            });
                          },
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tables List
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredTables.isEmpty
                              ? _buildEmptyState()
                              : _buildTablesList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay mesas registradas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera mesa para comenzar',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showCreateTableDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear Primera Mesa'),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesList() {
    return ListView.builder(
      itemCount: _filteredTables.length,
      itemBuilder: (context, index) {
        final table = _filteredTables[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(table.status),
              child: Text(
                table.tableName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Mesa ${table.tableName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Capacidad: ${table.capacity} personas'),
                Text('Código: ${table.joinCode}'),
                if (table.currentUserName != null)
                  Text('Ocupada por: ${table.currentUserName}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón limpiar mesa con confirmación
                IconButton(
                  icon: const Icon(Icons.cleaning_services),
                  tooltip: 'Limpiar Mesa',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar limpieza'),
                        content: Text('¿Seguro que deseas limpiar la mesa ${table.tableName}? Esto la dejará disponible.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Limpiar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) _freeTable(table);
                  },
                ),
                // Botón eliminar mesa con confirmación
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar Mesa',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar eliminación'),
                        content: Text('¿Seguro que deseas eliminar la mesa ${table.tableName}? Esta acción no se puede deshacer.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) _deleteTable(table);
                  },
                ),
                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(table.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(table.status),
                    style: TextStyle(
                      color: _getStatusColor(table.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'disponible':
        return Colors.green;
      case 'ocupada':
        return Colors.red;
      case 'reservada':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'disponible':
        return 'Disponible';
      case 'ocupada':
        return 'Ocupada';
      case 'reservada':
        return 'Reservada';
      default:
        return status;
    }
  }

  void _handleTableAction(String action, RestaurantTable table) {
    switch (action) {
      case 'edit':
        _showEditTableDialog(table);
        break;
      case 'occupy':
        _occupyTable(table);
        break;
      case 'free':
        _freeTable(table);
        break;
      case 'delete':
        _deleteTable(table);
        break;
    }
  }

  void _showCreateTableDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateTableDialog(
        restaurantId: widget.restaurantId,
        onSuccess: _loadTables,
      ),
    );
  }

  void _showEditTableDialog(RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => _CreateTableDialog(
        restaurantId: widget.restaurantId,
        table: table,
        onSuccess: _loadTables,
      ),
    );
  }

  Future<void> _occupyTable(RestaurantTable table) async {
    try {
      await _firebaseService.updateTable(table.id, {
        'status': 'ocupada',
        'currentUserName': 'Usuario',
        'currentUserId': 'temp_user',
      });
      _loadTables();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesa ${table.tableName} marcada como ocupada'),
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
    }
  }

  Future<void> _freeTable(RestaurantTable table) async {
    try {
      await _firebaseService.freeTable(table.id);
      _loadTables();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesa ${table.tableName} liberada'),
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
    }
  }

  Future<void> _deleteTable(RestaurantTable table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar la mesa ${table.tableName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseService.deleteTable(table.id);
        _loadTables();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mesa ${table.tableName} eliminada'),
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
      }
    }
  }
}

class _CreateTableDialog extends StatefulWidget {
  final String restaurantId;
  final RestaurantTable? table;
  final VoidCallback onSuccess;

  const _CreateTableDialog({
    required this.restaurantId,
    this.table,
    required this.onSuccess,
  });

  @override
  State<_CreateTableDialog> createState() => _CreateTableDialogState();
}

class _CreateTableDialogState extends State<_CreateTableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _firebaseService = FirebaseService();
  
  bool _isLoading = false;
  int _capacity = 4;
  String _joinCode = '';
  List<app_user.User> _employees = [];
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _nameController.text = widget.table!.tableName;
      _capacity = widget.table!.capacity;
      _joinCode = widget.table!.joinCode;
      _selectedEmployeeId = widget.table!.assignedEmployeeId;
      _selectedEmployeeName = widget.table!.assignedEmployeeName;
    } else {
      _joinCode = RestaurantTable.generateJoinCode();
    }
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final service = FirebaseService();
    final employees = await service.getRestaurantEmployees(widget.restaurantId);
    if (mounted) setState(() => _employees = employees);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.table != null ? 'Editar Mesa' : 'Nueva Mesa'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Mesa',
                hintText: 'Ej: Mesa 1',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre de la mesa';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Capacidad: '),
                Expanded(
                  child: Slider(
                    value: _capacity.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: _capacity.toString(),
                    onChanged: (value) {
                      setState(() {
                        _capacity = value.round();
                      });
                    },
                  ),
                ),
                Text('$_capacity'),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _joinCode,
              decoration: const InputDecoration(
                labelText: 'Código de Unión',
                hintText: 'Código de 6 dígitos',
              ),
              onChanged: (value) => _joinCode = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el código';
                }
                if (value.length != 6) {
                  return 'El código debe tener 6 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedEmployeeId,
              decoration: const InputDecoration(
                labelText: 'Empleado asignado (opcional)',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Ninguno')),
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
                      email: '',
                      name: '',
                      role: '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      isActive: false,
                      isEmployee: false,
                      preferences: {},
                      addresses: [],
                      paymentMethods: [],
                    ),
                  ).name;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTable,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.table != null ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) return;
    if (_capacity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La capacidad debe ser al menos 1'),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tableData = {
        'restaurantId': widget.restaurantId,
        'tableName': _nameController.text.trim(),
        'capacity': _capacity,
        'joinCode': _joinCode,
        'status': 'disponible',
        'currentUserName': <String>[],
        'currentUserId': <String>[],
        'assignedEmployeeId': _selectedEmployeeId,
        'assignedEmployeeName': _selectedEmployeeName,
      };

      if (widget.table != null) {
        await _firebaseService.updateTable(widget.table!.id, tableData);
      } else {
        await _firebaseService.createTable(tableData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.table != null 
                ? 'Mesa actualizada exitosamente'
                : 'Mesa creada exitosamente'),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
} 