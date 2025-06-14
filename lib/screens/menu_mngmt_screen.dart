import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/menu_item.dart';

class MenuManagementScreen extends StatefulWidget {
  final String restaurantId;

  const MenuManagementScreen({Key? key, required this.restaurantId})
      : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Todos';
  bool _showOnlyAvailable = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Menú'),
        backgroundColor: Colors.red[600],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Platos Actuales', icon: Icon(Icons.restaurant_menu)),
            Tab(text: 'Agregar Plato', icon: Icon(Icons.add_circle_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentMenuTab(),
          _buildAddMenuItemTab(),
        ],
      ),
    );
  }

  Widget _buildCurrentMenuTab() {
    return Column(
      children: [
        // Filtros
        _buildFiltersSection(),
        // Lista de platos
        Expanded(
          child: StreamBuilder<List<MenuItem>>(
            stream: FirebaseService.getMenuItems(widget.restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyMenuState();
              }

              var menuItems = snapshot.data!;
              
              // Aplicar filtros
              menuItems = _applyFilters(menuItems);

              if (menuItems.isEmpty) {
                return _buildNoResultsState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: menuItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildMenuItemCard(menuItems[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCategoryFilter(),
              ),
              const SizedBox(width: 16),
              _buildAvailabilityFilter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return StreamBuilder<List<String>>(
      stream: FirebaseService.getCategories(widget.restaurantId),
      builder: (context, snapshot) {
        final categories = ['Todos', ...(snapshot.data ?? [])];
        
        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Categoría',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: categories.map<DropdownMenuItem<String>>((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value ?? 'Todos';
            });
          },
        );
      },
    );
  }

  Widget _buildAvailabilityFilter() {
    return FilterChip(
      label: const Text('Solo disponibles'),
      selected: _showOnlyAvailable,
      onSelected: (selected) {
        setState(() {
          _showOnlyAvailable = selected;
        });
      },
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[700],
    );
  }

  List<MenuItem> _applyFilters(List<MenuItem> items) {
    var filtered = items;

    // Filtrar por categoría
    if (_selectedCategory != 'Todos') {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Filtrar por disponibilidad
    if (_showOnlyAvailable) {
      filtered = filtered.where((item) => item.available).toList();
    }

    return filtered;
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Imagen del plato
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.image.isNotEmpty
                  ? Image.network(
                      item.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 16),
            
            // Información del plato
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.available 
                              ? Colors.green[100] 
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.available ? 'Disponible' : 'No disponible',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: item.available 
                                ? Colors.green[700] 
                                : Colors.red[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Botones de acción
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _toggleAvailability(item),
                  icon: Icon(
                    item.available ? Icons.toggle_on : Icons.toggle_off,
                    color: item.available ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                  tooltip: item.available 
                      ? 'Marcar como no disponible' 
                      : 'Marcar como disponible',
                ),
                IconButton(
                  onPressed: () => _editMenuItem(item),
                  icon: Icon(Icons.edit, color: Colors.blue[600]),
                  tooltip: 'Editar plato',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.restaurant,
        color: Colors.grey[400],
        size: 30,
      ),
    );
  }

  Widget _buildAddMenuItemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _AddMenuItemForm(restaurantId: widget.restaurantId),
    );
  }

  Widget _buildEmptyMenuState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay platos en el menú',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer plato usando la pestaña "Agregar Plato"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron platos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba ajustando los filtros',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(MenuItem item) async {
      try {
        // Nuevo estado (opuesto al actual)
        final newAvailabilityState = !item.available;

        await FirebaseFirestore.instance
            .collection('Restaurante')
            .doc(widget.restaurantId)
            .collection('Menu')
            .doc(item.id)
            .update({'available': newAvailabilityState});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newAvailabilityState 
                  ? '${item.name} marcado como disponible'
                  : '${item.name} marcado como no disponible',
            ),
            backgroundColor: newAvailabilityState ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar disponibilidad: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
  }

  void _editMenuItem(MenuItem item) {
    // Aquí puedes implementar la navegación a una pantalla de edición
    // o mostrar un diálogo de edición
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de edición próximamente'),
      ),
    );
  }
}

class _AddMenuItemForm extends StatefulWidget {
  final String restaurantId;

  const _AddMenuItemForm({required this.restaurantId});

  @override
  State<_AddMenuItemForm> createState() => _AddMenuItemFormState();
}

class _AddMenuItemFormState extends State<_AddMenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = '';
  bool _isAvailable = true;
  bool _isLoading = false;

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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Agregar Nuevo Plato',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Nombre del plato
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre del plato *',
              prefixIcon: const Icon(Icons.restaurant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Descripción
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Descripción',
              prefixIcon: const Icon(Icons.description),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
            validator: (value) => null, // Opcional
          ),
          const SizedBox(height: 16),

          // Precio
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Precio *',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El precio es obligatorio';
              }
              if (double.tryParse(value) == null) {
                return 'Ingresa un precio válido';
              }
              if (double.parse(value) <= 0) {
                return 'El precio debe ser mayor a 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Categoría
          StreamBuilder<List<String>>(
            stream: FirebaseService.getCategories(widget.restaurantId),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];
              
              return DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Categoría *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: categories.map((category) {
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
                    return 'Selecciona una categoría';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // URL de imagen
          TextFormField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              labelText: 'URL de imagen (opcional)',
              prefixIcon: const Icon(Icons.image),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              helperText: 'Deja vacío si no tienes imagen',
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final uri = Uri.tryParse(value);
                if (uri == null || !uri.hasAbsolutePath) {
                  return 'Ingresa una URL válida';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Disponibilidad
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.visibility),
                  const SizedBox(width: 12),
                  const Text(
                    'Disponibilidad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Switch(
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
          const SizedBox(height: 24),

          // Vista previa de imagen
          if (_imageUrlController.text.trim().isNotEmpty) ...[
            const Text(
              'Vista previa:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageUrlController.text.trim(),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Error al cargar imagen',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Botón de agregar
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _addMenuItem,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(_isLoading ? 'Agregando...' : 'Agregar Plato'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón para limpiar formulario
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _clearForm,
            icon: const Icon(Icons.clear),
            label: const Text('Limpiar Formulario'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final menuItemData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'Categoria': _selectedCategory,
        'imageUrl': _imageUrlController.text.trim(),
        'available': _isAvailable,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(widget.restaurantId)
          .collection('Menu')
          .add(menuItemData);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡${_nameController.text.trim()} agregado exitosamente!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Ver menú',
            textColor: Colors.white,
            onPressed: () {
              // Cambiar a la pestaña del menú actual
              DefaultTabController.of(context)?.animateTo(0);
            },
          ),
        ),
      );

      // Limpiar formulario
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar plato: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _imageUrlController.clear();
    setState(() {
      _selectedCategory = '';
      _isAvailable = true;
    });
  }
}