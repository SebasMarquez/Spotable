import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/auth_dialog.dart';
import '../widgets/create_restaurant_dialog.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import 'restaurant_dashboard_screen.dart';
import 'client_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedRole = 'client';
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    _firebaseService.authStateChanges.listen((User? user) {
      if (user != null) {
        _handleAuthenticatedUser();
      }
    });
  }

  Future<void> _handleAuthenticatedUser() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('Manejando usuario autenticado...');
      final userData = await _firebaseService.getCurrentUserData();
      
      if (userData != null) {
        print('Usuario encontrado: ${userData.name}, Email: ${userData.email}');
        print('Datos del usuario: role=${userData.role}, isEmployee=${userData.isEmployee}');
        
        if (userData.role == 'restaurant' && userData.restaurantId == null) {
          // Restaurant owner without restaurant, show create restaurant dialog
          if (mounted) {
            _showCreateRestaurantDialog();
          }
        } else {
          // Navigate to appropriate screen based on role
          if (mounted) {
            _navigateToAppropriateScreen(userData);
          }
        }
      } else {
        print('No se encontraron datos del usuario');
      }
    } catch (e) {
      print('Error handling authenticated user: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAppropriateScreen(dynamic userData) {
    // Verificar si es empleado usando el campo isEmployee
    bool isEmployee = userData.isEmployee == true;
    
    if (isEmployee) {
      // Navigate to restaurant dashboard for employees
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RestaurantDashboardScreen(),
        ),
      );
    } else {
      // Navigate to client dashboard for clients
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ClientDashboardScreen(),
        ),
      );
    }
  }

  void _showAuthDialog(bool isLogin, {bool forceRestaurant = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AuthDialog(
        isLogin: isLogin,
        selectedRole: forceRestaurant ? 'restaurant' : 'client',
        onSuccess: _handleAuthenticatedUser,
      ),
    );
  }

  void _showCreateRestaurantDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateRestaurantDialog(
        onSuccess: () {
          // Restaurant created successfully
        },
      ),
    );
  }

  void _showCreateTestUserDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateTestUserDialog(),
    );
  }

  void _showRestaurantLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RestaurantLoginDialog(
        onSuccess: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const RestaurantDashboardScreen(),
            ),
          );
        },
      ),
    );
  }

  void _toggleRole() {
    setState(() {
      _selectedRole = _selectedRole == 'client' ? 'restaurant' : 'client';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_spotable_mobile.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final padding = isMobile ? 20.0 : 40.0;
                final buttonHeight = isMobile ? 50.0 : 56.0;
                final buttonTextSize = isMobile ? 16.0 : 18.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Logo and Title
                      Center(
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;
                                final logoSize = isMobile
                                    ? MediaQuery.of(context).size.width * 0.6
                                    : MediaQuery.of(context).size.width * 0.25;
                                return Image.asset(
                                  'assets/images/Logo_spotable.png',
                                  height: logoSize.clamp(140, 260),
                                  width: logoSize.clamp(140, 260),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Tu plataforma de restaurantes favorita',
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Login/Register form for clients and employees
                      _LoginGeneralForm(
                        onSuccess: _handleAuthenticatedUser,
                        isLogin: _isLogin,
                        selectedRole: _selectedRole,
                        onRoleChanged: (role) => setState(() => _selectedRole = role),
                      ),
                      const SizedBox(height: 12),
                      // Botón para alternar entre login y registro de usuario
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? '¿No tienes cuenta? Regístrate aquí'
                              : '¿Ya tienes cuenta? Inicia sesión',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Login Restaurant button
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: OutlinedButton.icon(
                          onPressed: _showRestaurantLoginDialog,
                          icon: Icon(Icons.restaurant, color: Color(0xFF388e3c)),
                          label: Text(
                            'Login Restaurant',
                            style: TextStyle(
                              color: Color(0xFF388e3c),
                              fontSize: buttonTextSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF388e3c), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Crear un restaurante (siempre visible)
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed: _showCreateRestaurantDialog,
                          icon: Icon(Icons.store, color: Colors.white),
                          label: Text(
                            'Crear un restaurante',
                            style: TextStyle(
                              fontSize: buttonTextSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF9800),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Features (opcional, puedes dejarlo igual)
                      if (!isMobile) ...[
                        Text(
                          'Características principales',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFeatureCard(
                              icon: Icons.restaurant_menu,
                              title: 'Menús Digitales',
                              description: 'Explora menús completos con fotos y descripciones',
                            ),
                            _buildFeatureCard(
                              icon: Icons.delivery_dining,
                              title: 'Pedidos Online',
                              description: 'Realiza pedidos desde la comodidad de tu hogar',
                            ),
                            _buildFeatureCard(
                              icon: Icons.table_restaurant,
                              title: 'Reservas',
                              description: 'Reserva tu mesa con solo unos clics',
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.green.shade700,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CreateTestUserDialog extends StatefulWidget {
  @override
  State<_CreateTestUserDialog> createState() => _CreateTestUserDialogState();
}

class _CreateTestUserDialogState extends State<_CreateTestUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'restaurant';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createTestUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user document directly in Firestore
      final userData = {
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'role': _selectedRole,
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'isActive': true,
        'profileImageUrl': null,
        'preferences': {},
        'addresses': [],
        'paymentMethods': [],
        'permissions': [],
        'restaurantId': null,
      };

      // Generate a random ID for the user
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      userData['id'] = userId;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(userData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario de prueba creado exitosamente\nEmail: ${_emailController.text.trim()}\nID: $userId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
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
    return AlertDialog(
      title: const Text('Crear Usuario de Prueba'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el email';
                }
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} $').hasMatch(value.trim()) && !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
                  return 'Por favor ingresa un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'client', child: Text('Cliente')),
                DropdownMenuItem(value: 'restaurant', child: Text('Restaurante')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
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
          onPressed: _isLoading ? null : _createTestUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear Usuario'),
        ),
      ],
    );
  }
}

class _LoginGeneralForm extends StatefulWidget {
  final VoidCallback onSuccess;
  final bool isLogin;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  const _LoginGeneralForm({
    required this.onSuccess,
    required this.isLogin,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  State<_LoginGeneralForm> createState() => _LoginGeneralFormState();
}

class _LoginGeneralFormState extends State<_LoginGeneralForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _handleLoginOrRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (widget.isLogin) {
        await _firebaseService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          widget.selectedRole,
        );
        widget.onSuccess();
      } else {
        // REGISTRO
        final userId = _idController.text.trim();
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        if (userId.isEmpty || name.isEmpty || phone.isEmpty) {
          setState(() {
            _errorMessage = 'Todos los campos son obligatorios';
          });
          return;
        }
        await _firebaseService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          name,
          widget.selectedRole,
          phone: phone,
          personalId: userId,
        );
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Color(0xFFE57373), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Color(0xFFE57373)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<String>(
            value: widget.selectedRole,
            items: [
              DropdownMenuItem(value: 'client', child: Text('Cliente')),
              DropdownMenuItem(value: 'restaurant', child: Text('Restaurante')),
            ],
            onChanged: (value) {
              if (value != null) widget.onRoleChanged(value);
            },
            decoration: InputDecoration(labelText: 'Tipo de usuario', border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecciona el tipo de usuario';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Color(0xFFCFD8DC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Color(0xFFCFD8DC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Color(0xFF388e3c), width: 2),
              ),
              prefixIcon: Icon(Icons.email, color: Color(0xFF424242)),
              contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa tu email';
              }
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} $').hasMatch(value.trim()) && !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
                return 'Por favor ingresa un email válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'Contraseña',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Color(0xFFCFD8DC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Color(0xFFCFD8DC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Color(0xFF388e3c), width: 2),
              ),
              prefixIcon: Icon(Icons.lock, color: Color(0xFF424242)),
              contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              return null;
            },
          ),
          if (!widget.isLogin) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Nombre y apellido',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFFCFD8DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFFCFD8DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFF388e3c), width: 2),
                ),
                prefixIcon: Icon(Icons.person, color: Color(0xFF424242)),
                contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa tu nombre y apellido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Teléfono',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFFCFD8DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFFCFD8DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFF388e3c), width: 2),
                ),
                prefixIcon: Icon(Icons.phone, color: Color(0xFF424242)),
                contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa tu teléfono';
                }
                final phone = value.trim();
                if (!RegExp(r'^(04|02)[0-9]{9} $').hasMatch(phone) && !RegExp(r'^(04|02)[0-9]{9}$').hasMatch(phone)) {
                  return 'El teléfono debe ser venezolano, 11 dígitos y empezar en 04 o 02';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _idController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Cédula de identidad',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFFCFD8DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFFCFD8DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFF388e3c), width: 2),
                ),
                prefixIcon: Icon(Icons.badge, color: Color(0xFF424242)),
                contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa tu cédula';
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
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLoginOrRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF388e3c),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  : Text(widget.isLogin ? 'Iniciar Sesión' : 'Registrarse'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantLoginDialog extends StatefulWidget {
  final VoidCallback? onSuccess;
  const _RestaurantLoginDialog({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<_RestaurantLoginDialog> createState() => _RestaurantLoginDialogState();
}

class _RestaurantLoginDialogState extends State<_RestaurantLoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idOrNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _idOrNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginRestaurant() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Buscar restaurante solo por ID
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_idOrNameController.text.trim())
          .get();
      if (!doc.exists) {
        setState(() {
          _errorMessage = 'Restaurante no encontrado';
        });
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      if (data['password'] != _passwordController.text.trim()) {
        setState(() {
          _errorMessage = 'Contraseña incorrecta';
        });
        return;
      }
      // Guardar sesión localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('restaurant_id', doc.id);
      await prefs.setString('restaurant_name', data['name'] ?? '');
      await prefs.setString('restaurant_logo', data['logoUrl'] ?? '');
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
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
    final dialogWidth = isMobile ? double.infinity : 400.0;
    final dialogHeight = isMobile ? null : 320.0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: isMobile ? const BoxConstraints(maxHeight: 340) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
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
                  const Icon(Icons.restaurant, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Login Restaurante',
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _idOrNameController,
                        decoration: const InputDecoration(
                          labelText: 'ID del restaurante',
                          prefixIcon: Icon(Icons.restaurant),
                          border: OutlineInputBorder(),
                          helperText: 'El ID aparece al crear el restaurante o en la administración',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el ID del restaurante';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa la contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _loginRestaurant,
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
                                'Iniciar Sesión',
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