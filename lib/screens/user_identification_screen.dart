import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../models/user_data.dart';
import '../utils/app_colors.dart';
import '../screens/restaurant_list_screen.dart'; // Added import

class UserIdentificationScreen extends StatefulWidget {
  const UserIdentificationScreen({Key? key}) : super(key: key);

  @override
  State<UserIdentificationScreen> createState() =>
      _UserIdentificationScreenState();
}

class _UserIdentificationScreenState extends State<UserIdentificationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su nombre';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ]+$').hasMatch(value)) {
      return 'Solo se permiten letras, sin espacios ni números';
    }
    return null;
  }

  String? _validateCedula(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su cédula';
    }
    final cedula = int.tryParse(value);
    if (cedula == null || cedula <= 0) {
      return 'Cédula inválida';
    }
    if (cedula > 40000000) {
      return 'Cédula inválida';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Identificación',
          style: TextStyle(color: AppColors.cardBackground),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.cardBackground),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ingrese su nombre',
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Cédula de Identidad',
                  hintText: 'Ingrese su cédula',
                ),
                keyboardType: TextInputType.number,
                validator: _validateCedula,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.cardBackground,
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final nombre = nameController.text.trim();
                      final cedula = idController.text.trim();
                      await FirebaseService.saveUser(
                        idUsuario: cedula,
                        nombre: nombre,
                        cedula: cedula,
                      );
                      // Guardar globalmente
                      Provider.of<UserProvider>(
                        context,
                        listen: false,
                      ).setUser(UserData(nombre: nombre, cedula: cedula));
                      // Navegar a la pantalla de lista de restaurantes
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RestaurantListScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                  child: const Text(
                    'Continuar',
                    style: TextStyle(color: AppColors.cardBackground),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final cedulaController = TextEditingController();
                  final result = await showDialog<String>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: AppColors.cardBackground,
                          title: const Text(
                            'Ingresar con cédula',
                            style: TextStyle(color: Colors.black),
                          ),
                          content: TextField(
                            controller: cedulaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cédula',
                              hintText: 'Ingrese su cédula',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.of(
                                    context,
                                  ).pop(cedulaController.text.trim()),
                              child: const Text(
                                'Aceptar',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (result != null && result.isNotEmpty) {
                    // Buscar usuario en Firebase
                    final userDoc = await FirebaseService.getUserByCedula(
                      result,
                    );
                    if (userDoc != null) {
                      Provider.of<UserProvider>(context, listen: false).setUser(
                        UserData(
                          nombre: userDoc['nombre'],
                          cedula: userDoc['cedula'],
                        ),
                      );
                      // Navegar a la pantalla de lista de restaurantes
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RestaurantListScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cédula no encontrada.')),
                      );
                    }
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    '¿Ya ingresaste anteriormente? Pulsa aquí',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
