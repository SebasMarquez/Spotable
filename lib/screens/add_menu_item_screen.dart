import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class AddMenuItemScreen extends StatefulWidget {
  final String restaurantId;

  const AddMenuItemScreen({Key? key, required this.restaurantId})
      : super(key: key);

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Nuevo Plato'),
        backgroundColor: Colors.red[600],
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _clearForm,
            child: const Text(
              'Limpiar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información adicional
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Completa los campos obligatorios (*) para agregar un nuevo plato a tu menú.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => null, // Opcional
              ),
              const SizedBox(height: 20),

              // Precio
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Precio *',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffix: const Text('USD'),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              const SizedBox(height: 20),

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
                        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 20),

              // URL de imagen
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL de imagen (opcional)',
                  prefixIcon: const Icon(Icons.image),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  helperText: 'Pega aquí la URL de la imagen del plato',
                ),
                onChanged: (value) {
                  setState(() {}); // Para actualizar la vista previa
                },
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
              const SizedBox(height: 20),

              // Disponibilidad
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuración de Disponibilidad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            _isAvailable ? Icons.visibility : Icons.visibility_off,
                            color: _isAvailable ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isAvailable 
                                  ? 'El plato estará disponible inmediatamente'
                                  : 'El plato se agregará como no disponible',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Vista previa de imagen
              if (_imageUrlController.text.trim().isNotEmpty) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vista previa de la imagen:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrlController.text.trim(),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Error al cargar la imagen',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Verifica que la URL sea correcta',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add_circle),
                label: Text(
                  _isLoading ? 'Agregando plato...' : 'Agregar Plato al Menú',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
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
          .add(menuItemData);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('¡${_nameController.text.trim()} agregado exitosamente!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Volver a la pantalla anterior
      Navigator.pop(context, true);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Error al agregar plato: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulario limpiado'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}