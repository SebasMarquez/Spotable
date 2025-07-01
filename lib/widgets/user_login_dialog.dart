import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../models/user_data.dart';
import '../utils/app_colors.dart';
// Se eliminó la importación de 'restaurant_list_screen.dart'

class UserLoginDialog extends StatefulWidget {
  const UserLoginDialog({Key? key}) : super(key: key);

  @override
  State<UserLoginDialog> createState() => _UserLoginDialogState();
}

class _UserLoginDialogState extends State<UserLoginDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false; // Estado para el indicador de carga

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

  // --- Lógica de validación (sin cambios) ---
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese su nombre';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(value)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  String? _validateCedula(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese su cédula';
    final cedula = int.tryParse(value);
    if (cedula == null || cedula <= 0 || cedula > 40000000) {
      return 'Cédula inválida';
    }
    return null;
  }

  // --- Widget Principal (sin cambios) ---
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: const Text('Acceso de Usuario', textAlign: TextAlign.center),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Ingresar'),
                Tab(text: 'Registrarse'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 210, // Altura ajustada
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(context),
                  _buildRegisterTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child:
              const Text('Cancelar', style: TextStyle(color: AppColors.primary)),
        )
      ],
    );
  }

  // --- Pestaña de Registro (CORREGIDA) ---
  Widget _buildRegisterTab(BuildContext context) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
              validator: _validateName,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: idController,
              decoration: const InputDecoration(labelText: 'Cédula de Identidad'),
              keyboardType: TextInputType.number,
              validator: _validateCedula,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.cardBackground,
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);

                        final nombre = nameController.text.trim();
                        final cedula = idController.text.trim();

                        await FirebaseService.saveUser(
                            idUsuario: cedula, nombre: nombre, cedula: cedula);

                        Provider.of<UserProvider>(context, listen: false)
                            .setUser(UserData(nombre: nombre, cedula: cedula));
                        
                        // Si el widget sigue montado, cerramos el diálogo
                        if (mounted) {
                          Navigator.of(context).pop();
                        } else {
                           setState(() => _isLoading = false);
                        }
                      }
                    },
              child: _isLoading
                  ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Registrarse y Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Pestaña de Inicio de Sesión (CORREGIDA) ---
  Widget _buildLoginTab(BuildContext context) {
    final idController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: idController,
              decoration: const InputDecoration(labelText: 'Cédula de Identidad'),
              keyboardType: TextInputType.number,
              validator: _validateCedula,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.cardBackground,
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);
                        final cedula = idController.text.trim();
                        final userDoc =
                            await FirebaseService.getUserByCedula(cedula);
                        
                        if (!mounted) return;

                        if (userDoc != null) {
                          Provider.of<UserProvider>(context, listen: false)
                              .setUser(UserData(
                            nombre: userDoc['nombre'],
                            cedula: userDoc['cedula'],
                          ));
                          Navigator.of(context).pop();
                        } else {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Cédula no encontrada. Por favor, regístrese.')),
                          );
                        }
                      }
                    },
              child: _isLoading
                  ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Ingresar'),
            ),
            const SizedBox(height: 16),
            const Text(
              "Si ya tienes cuenta, ingresa tu cédula. Si no, ve a la pestaña 'Registrarse'.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}