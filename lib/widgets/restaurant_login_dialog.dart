import 'package:flutter/material.dart';
import '../services/firebase_service.dart'; // Asegúrate que la ruta sea correcta
import '../utils/app_colors.dart';

class RestaurantLoginDialog extends StatefulWidget {
  const RestaurantLoginDialog({Key? key}) : super(key: key);

  @override
  State<RestaurantLoginDialog> createState() => _RestaurantLoginDialogState();
}

class _RestaurantLoginDialogState extends State<RestaurantLoginDialog> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final id = _controller.text.trim();
    final exists = await FirebaseService().restaurantExists(id);

    // Si el widget sigue montado en el árbol, procedemos.
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (exists) {
      // Si el ID es correcto, cerramos el diálogo y devolvemos el ID.
      Navigator.of(context).pop(id);
    } else {
      setState(() {
        _error = 'ID de restaurante no encontrado.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ingreso de Restaurante'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Introduce el ID proporcionado para acceder al panel.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'ID del restaurante',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, ingresa un ID.';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: Colors.white,
                  ),
                )
              : const Text('Ingresar'),
        ),
      ],
    );
  }
}