import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../services/firebase_service.dart';

class EditMenuItemScreen extends StatefulWidget {
  final MenuItem menuItem;
  final String restaurantId;

  const EditMenuItemScreen({
    Key? key,
    required this.menuItem,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late String _selectedCategory;
  late bool _isAvailable;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.menuItem.name);
    _descriptionController = TextEditingController(text: widget.menuItem.description);
    _priceController = TextEditingController(text: widget.menuItem.price.toString());
    _imageUrlController = TextEditingController(text: widget.menuItem.image);
    _selectedCategory = widget.menuItem.category;
    _isAvailable = widget.menuItem.available;

    // Agregar listeners para detectar cambios
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _priceController.addListener(_onFieldChanged);
    _imageUrlController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Plato'),
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_hasChanges)
              TextButton.icon(
                onPressed: _isLoading ? null : _saveChanges,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Guardar', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con información del plato
            _buildHeader(),
            const SizedBox(height: 24),

            // Nombre del plato
            _buildTextField(
              controller: _nameController,
              label: 'Nombre del plato',
              icon: Icons.restaurant,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción',
              icon: Icons.description,
              maxLines: 3,
              required: false,
            ),
            const SizedBox(height: 16),

            // Precio
            _buildTextField(
              controller: _priceController,
              label: 'Precio',
              icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El precio es obligatorio';
                }
                final price = double.tryParse(value);
                if (price == null) {
                  return 'Ingresa un precio válido';
                }
                if (price <= 0) {
                  return 'El precio debe ser mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoría
            _buildCategorySelector(),
            const SizedBox(height: 16),

            // URL de imagen
            _buildTextField(
              controller: _imageUrlController,
              label: 'URL de imagen',
              icon: Icons.image,
              required: false,
              helperText: 'Opcional - Deja vacío si no tienes imagen',
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
            _buildAvailabilityCard(),
            const SizedBox(height: 24),

            // Vista previa de imagen
            _buildImagePreview(),
            const SizedBox(height: 100), // Espacio para el bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Imagen actual
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.menuItem.image.isNotEmpty
                  ? Image.network(
                      widget.menuItem.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 16),
            
            // Información básica
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.menuItem.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Categoría: ${widget.menuItem.category}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.menuItem.available ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.menuItem.available ? 'Disponible' : 'No disponible',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: widget.menuItem.available ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${widget.menuItem.price.toStringAsFixed(2)}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
    String? helperText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon),
        helperText: helperText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildCategorySelector() {
    return StreamBuilder<List<String>>(
      stream: FirebaseService.getCategories(widget.restaurantId),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        
        // Asegurar que la categoría actual esté en la lista
        if (!categories.contains(_selectedCategory)) {
          categories.add(_selectedCategory);
        }
        
        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Categoría *',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
                _hasChanges = true;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Selecciona una categoría';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isAvailable ? Icons.visibility : Icons.visibility_off,
              color: _isAvailable ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Disponibilidad del plato',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                  _hasChanges = true;
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final imageUrl = _imageUrlController.text.trim();
    if (imageUrl.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vista previa de imagen:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Error al cargar imagen',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildBottomBar() {
    if (!_hasChanges) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _discardChanges,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Descartar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir sin guardar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _discardChanges() {
    setState(() {
      _nameController.text = widget.menuItem.name;
      _descriptionController.text = widget.menuItem.description;
      _priceController.text = widget.menuItem.price.toString();
      _imageUrlController.text = widget.menuItem.image;
      _selectedCategory = widget.menuItem.category;
      _isAvailable = widget.menuItem.available;
      _hasChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios descartados'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedData = {
        'Nombre': _nameController.text.trim(),
        'Descripción': _descriptionController.text.trim(),
        'Precio': double.parse(_priceController.text.trim()),
        'Categoria': _selectedCategory,
        'Imagen': _imageUrlController.text.trim(),
        'available': _isAvailable,
      };

      await FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(widget.restaurantId)
          .collection('Menu')
          .doc(widget.menuItem.id)
          .update(updatedData);

      setState(() {
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡${_nameController.text.trim()} actualizado exitosamente!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Cerrar',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(true); // Indicar que se guardaron cambios
            },
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar plato: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}