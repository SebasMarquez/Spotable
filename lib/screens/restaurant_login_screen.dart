import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

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
  bool _isLoading = false; // To show a loading indicator

  Future<void> _submit() async {
    final id = _controller.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Por favor, ingresa un ID.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if restaurant ID exists in Firestore
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection(
                'Restaurante',
              ) // Assuming your collection is named 'Restaurante'
              .doc(id)
              .get();

      if (docSnapshot.exists) {
        widget.onLogin(id);
      } else {
        setState(() {
          _error = 'ID de restaurante no encontrado.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al verificar el ID: ${e.toString()}';
      });
    }

    setState(() {
      _isLoading = false;
    });
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
                onSubmitted:
                    (_) =>
                        _isLoading
                            ? null
                            : _submit(), // Disable on submit while loading
                enabled: !_isLoading, // Disable text field while loading
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    _isLoading ? null : _submit, // Disable button while loading
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
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                        : const Text(
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
