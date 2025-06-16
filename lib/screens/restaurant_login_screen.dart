import 'package:flutter/material.dart';

class RestaurantLoginScreen extends StatefulWidget {
  final Function(String) onLogin;

  const RestaurantLoginScreen({Key? key, required this.onLogin})
    : super(key: key);

  @override
  State<RestaurantLoginScreen> createState() => _RestaurantLoginScreenState();
}

class _RestaurantLoginScreenState extends State<RestaurantLoginScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  void _submit() {
    final id = _controller.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Por favor, ingresa un ID.');
      return;
    }
    widget.onLogin(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ingresar como Restaurante',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFFB71C1C), // Rojo oscuro como en el menú
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFFB71C1C)),
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
      ),
      body: Container(
        color: Colors.white, // Fondo blanco
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Introduce el ID del restaurante:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'ID del restaurante',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ingresar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
