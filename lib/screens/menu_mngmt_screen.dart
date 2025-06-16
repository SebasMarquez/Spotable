import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/menu_item.dart';
import 'edit_menu_items_screen.dart';
import 'add_menu_item_screen.dart'; // Nueva importación

class MenuManagementScreen extends StatefulWidget {
  final String restaurantId;

  const MenuManagementScreen({Key? key, required this.restaurantId})
      : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  String _selectedCategory = 'Todos';
  bool _showOnlyAvailable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Menú'),
        backgroundColor: Colors.red[600],
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddMenuItem(),
        backgroundColor: Colors.red[600],
        icon: const Icon(Icons.add),
        label: const Text('Agregar Plato'),
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltersSection(),
          // Lista de platos
          Expanded(
            child: StreamBuilder<List<MenuItem>>(
              stream: FirebaseService.getAllMenuItems(widget.restaurantId),
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
      ),
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
                child: _buildCategoryFilterImproved(),
              ),
              const SizedBox(width: 16),
              _buildAvailabilityFilter(),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildCategoryFilterImproved() {
  return StreamBuilder<List<String>>(
    stream: FirebaseService.getCategories(widget.restaurantId),
    builder: (context, snapshot) {
      // Manejar estados de carga y error
      if (snapshot.connectionState == ConnectionState.waiting) {
        return DropdownButtonFormField<String>(
          value: 'Todos',
          decoration: InputDecoration(
            labelText: 'Categoría',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem<String>(
              value: 'Todos',
              child: Text('Cargando...'),
            ),
          ],
          onChanged: null, // Deshabilitado mientras carga
        );
      }

      if (snapshot.hasError) {
        return DropdownButtonFormField<String>(
          value: 'Todos',
          decoration: InputDecoration(
            labelText: 'Categoría',
            prefixIcon: Icon(Icons.error, color: Colors.red[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem<String>(
              value: 'Todos',
              child: Text('Error al cargar'),
            ),
          ],
          onChanged: null,
        );
      }

      // Procesar las categorías
      final streamCategories = snapshot.data ?? [];
      final uniqueCategories = <String>{'Todos'};
      
      // Agregar categorías válidas (no vacías)
      for (final category in streamCategories) {
        if (category.trim().isNotEmpty) {
          uniqueCategories.add(category.trim());
        }
      }
      
      final categoryList = uniqueCategories.toList()..sort();
      
      // Verificar y corregir el valor seleccionado
      String currentValue = _selectedCategory;
      if (!categoryList.contains(currentValue)) {
        currentValue = 'Todos';
        // Programar la actualización del estado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedCategory = 'Todos';
            });
          }
        });
      }
      
      return DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: 'Categoría',
          prefixIcon: const Icon(Icons.category),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: categoryList.map<DropdownMenuItem<String>>((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(
              category,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null && mounted && categoryList.contains(value)) {
            setState(() {
              _selectedCategory = value;
            });
          }
        },
        isExpanded: true,
        hint: const Text('Selecciona una categoría'),
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
            'Agrega tu primer plato presionando el botón "+"',
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

  Future<void> _navigateToAddMenuItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMenuItemScreen(
          restaurantId: widget.restaurantId,
        ),
      ),
    );

    // Si se agregó un plato exitosamente, mostrar mensaje
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Plato agregado exitosamente!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
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

  void _editMenuItem(MenuItem item) async {
    final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditMenuItemScreen(
        menuItem: item,
        restaurantId: widget.restaurantId,
      ),
    ),
  );

  // Si se guardaron cambios, mostrar un mensaje de confirmación
  if (result == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} actualizado correctamente'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  }
}