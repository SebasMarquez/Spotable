import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class CreateRestaurantDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const CreateRestaurantDialog({
    Key? key,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<CreateRestaurantDialog> createState() => _CreateRestaurantDialogState();
}

class _CreateRestaurantDialogState extends State<CreateRestaurantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseService = FirebaseService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _selectedCategories = [];
  String _logoUrl = '';
  
  final List<String> _availableCategories = [
    'Italiana',
    'Mexicana',
    'China',
    'Japonesa',
    'Americana',
    'Venezolana',
    'Mediterránea',
    'India',
    'Thai',
    'Francesa',
    'Española',
    'Árabe',
    'Vegetariana',
    'Vegana',
    'Sin Gluten',
    'Mariscos',
    'Carnes',
    'Pizza',
    'Hamburguesas',
    'Sushi',
    'Pasta',
    'Ensaladas',
    'Postres',
    'Café',
    'Bebidas',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createRestaurant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      setState(() {
        _errorMessage = 'Selecciona al menos una categoría';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Determine logo URL
      String finalLogoUrl = _logoUrl.trim();

      final restaurant = Restaurant(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty 
            ? null 
            : _websiteController.text.trim(),
        logoUrl: finalLogoUrl.isEmpty ? null : finalLogoUrl,
        categories: _selectedCategories,
        rating: 0.0,
        totalReviews: 0,
        totalOrders: 0,
        isActive: true,
        isOpen: true,
        openingHours: {
          'monday': {'open': '08:00', 'close': '22:00'},
          'tuesday': {'open': '08:00', 'close': '22:00'},
          'wednesday': {'open': '08:00', 'close': '22:00'},
          'thursday': {'open': '08:00', 'close': '22:00'},
          'friday': {'open': '08:00', 'close': '23:00'},
          'saturday': {'open': '09:00', 'close': '23:00'},
          'sunday': {'open': '09:00', 'close': '21:00'},
        },
        deliveryOptions: ['pickup', 'delivery'],
        paymentMethods: ['cash', 'card', 'transfer'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        password: _passwordController.text.trim(),
      );

      // Create restaurant directly in Firestore without authentication
      final docRef = await FirebaseFirestore.instance.collection('restaurants').add(restaurant.toMap());
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restaurante creado exitosamente con ID: ${docRef.id}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dialogWidth = isMobile ? double.infinity : 500.0;
    final dialogHeight = isMobile ? null : 700.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: isMobile 
            ? const BoxConstraints(maxHeight: 700)
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Crear Restaurante',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del restaurante *',
                          prefixIcon: Icon(Icons.restaurant),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre del restaurante';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Address field
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Dirección *',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa la dirección';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña *',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa una contraseña';
                          }
                          if (value.length < 4) {
                            return 'La contraseña debe tener al menos 4 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Phone field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el teléfono';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Website field
                      TextFormField(
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Sitio web (opcional)',
                          prefixIcon: Icon(Icons.web),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Logo section
                      const Text(
                        'Logo del restaurante (URL de imagen)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        onChanged: (value) => _logoUrl = value,
                        decoration: const InputDecoration(
                          labelText: 'URL de la imagen',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa la URL de la imagen del logo';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Categories section
                      const Text(
                        'Categorías *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: _availableCategories.length,
                          itemBuilder: (context, index) {
                            final category = _availableCategories[index];
                            final isSelected = _selectedCategories.contains(category);
                            
                            return CheckboxListTile(
                              title: Text(category),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedCategories.add(category);
                                  } else {
                                    _selectedCategories.remove(category);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Create button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createRestaurant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Crear Restaurante',
                                style: TextStyle(fontSize: 16),
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
    );
  }
} 