import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

final Color primaryColor = const Color(0xFF1E88E5); // Azul principal
final Color accentColor = const Color(0xFFFFC107); // Amarillo/acento
final Color backgroundColor = const Color(0xFFF5F5F5); // Fondo claro
final Color availableColor = const Color(0xFF43A047); // Verde para disponible
final Color reservedColor = const Color(0xFFE53935); // Rojo para reservada

// Modelo de Mesa (reutilizado de tu pantalla de reservaciones)
class Mesa {
  final String id;
  final int numero;
  final bool Estado;

  const Mesa({
    required this.id,
    required this.numero,
    required this.Estado,
  });

  factory Mesa.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Mesa(
      id: doc.id,
      numero: data['numero'] ?? 0,
      Estado: data['Estado'] ?? false,
    );
  }
}

class Reserva {
  final String id;
  final String cedulaCliente;
  final String contactoCliente;
  final Timestamp fechaHoraReservacion;
  final String idMesa;
  final String nombreCliente;

  const Reserva({
    required this.id,
    required this.cedulaCliente,
    required this.contactoCliente,
    required this.fechaHoraReservacion,
    required this.idMesa,
    required this.nombreCliente,
  });

  factory Reserva.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reserva(
      id: doc.id,
      cedulaCliente: data['cedulaCliente'] ?? '',
      contactoCliente: data['contactoCliente'] ?? '',
      fechaHoraReservacion: data['fecha_HoraReservacion'] ?? Timestamp.now(),
      idMesa: data['id_mesa'] ?? '',
      nombreCliente: data['nombreCliente'] ?? '',
    );
  }
}

// Diálogo de Reservaciones
class ReservationDialog extends StatefulWidget {
  final String restauranteId;
  const ReservationDialog({super.key, required this.restauranteId});

  @override
  State<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  DateTime? _fechaHoraDeseada;
  Mesa? _selectedMesa;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _contactoController.dispose();
    super.dispose();
  }

  void _resetToTableSelection() {
    setState(() => _selectedMesa = null);
  }

  Future<void> _seleccionarFechaHora(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      final hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (hora != null) {
        setState(() {
          _fechaHoraDeseada = DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
            hora.hour,
            hora.minute,
          );
        });
      }
    }
  }

  Future<void> _reservarMesa() async {
    if (!_formKey.currentState!.validate() || _fechaHoraDeseada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final restauranteId = widget.restauranteId;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final nombreCliente = userProvider.user?.nombre ?? '';
      final cedulaCliente = userProvider.user?.cedula ?? '';

      final reservasCollection = FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(restauranteId)
          .collection('Reservas');

      final newReservationData = {
        'contactoCliente': _contactoController.text,
        'fecha_HoraReservacion': Timestamp.fromDate(_fechaHoraDeseada!),
        'id_mesa': _selectedMesa!.id,
        'nombreCliente': nombreCliente,
        'cedulaCliente': cedulaCliente,
      };
      DocumentReference reservationDocRef =
          await reservasCollection.add(newReservationData);

      final mesaDoc = FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(restauranteId)
          .collection('Mesas')
          .doc(_selectedMesa!.id);

      await mesaDoc.update({
        'Estado': true,
        'datosCliente': {
          'fecha_HoraReservacion': Timestamp.fromDate(_fechaHoraDeseada!),
          'reservationId': reservationDocRef.id,
        },
      });

      if (userProvider.user != null && userProvider.user!.cedula.isNotEmpty) {
        final restauranteDocSnapshot = await FirebaseFirestore.instance
            .collection('Restaurante')
            .doc(restauranteId)
            .get();
        final nombreRestaurante =
            restauranteDocSnapshot.data()?['nombre'] ?? 'Nombre no encontrado';

        final userReservationData = {
          'id_mesa': _selectedMesa!.id,
          'nombre_restaurante': nombreRestaurante,
          'hora_reservacion': Timestamp.fromDate(_fechaHoraDeseada!),
          'id_restaurante': restauranteId,
          'id_reserva_restaurante': reservationDocRef.id,
          'estado': 'activa',
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('Usuario')
            .doc(cedulaCliente)
            .collection('ReservasActivas')
            .add(userReservationData);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesa reservada exitosamente')),
      );
      Navigator.of(context).pop(); // Cierra el diálogo
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al reservar: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_selectedMesa == null
          ? 'Hacer una Reservación'
          : 'Confirmar para Mesa ${_selectedMesa!.numero}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildDialogContent(),
      ),
      actions: _buildDialogActions(),
    );
  }

  Widget _buildSeleccionFecha(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_fechaHoraDeseada != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Fecha y hora seleccionada: ${_fechaHoraDeseada!.day}/${_fechaHoraDeseada!.month}/${_fechaHoraDeseada!.year} ${_fechaHoraDeseada!.hour}:${_fechaHoraDeseada!.minute}',
              ),
            ),
          ElevatedButton(
            onPressed: () => _seleccionarFechaHora(context),
            child: Text(
              _fechaHoraDeseada == null
                  ? 'Seleccionar Fecha y Hora'
                  : 'Cambiar Fecha y Hora',
            ),
          ),
          if (_fechaHoraDeseada != null)
            _buildListaMesas(),
        ],
      ),
    );
  }

  Widget _buildDialogContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Procesando...'),
          ],
        ),
      );
    }
    return _selectedMesa == null
        ? _buildSeleccionFecha(context)
        : _buildFormularioReserva();
  }

  List<Widget> _buildDialogActions() {
    if (_selectedMesa == null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: _isLoading ? null : _resetToTableSelection,
          child: const Text('Atrás'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _reservarMesa,
          child: const Text('Confirmar'),
        ),
      ];
    }
  }

  Widget _buildFormularioReserva() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final nombreCliente = userProvider.user?.nombre ?? '';
    final cedulaCliente = userProvider.user?.cedula ?? '';

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Nombre: $nombreCliente'),
              subtitle: Text('Cédula: $cedulaCliente'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactoController,
              decoration: const InputDecoration(
                labelText: 'Contacto (teléfono)',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Ingrese el contacto' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaMesas() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _getCombinedStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.length < 2) {
          return const Center(child: Text('Error al cargar datos.'));
        }

        final mesasSnapshot = snapshot.data![0];

        if (mesasSnapshot.docs.isEmpty) {
          return const Center(child: Text('No hay mesas disponibles.'));
        }

        final mesas =
            mesasSnapshot.docs.map((doc) => Mesa.fromFirestore(doc)).toList();

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: mesas.length,
          itemBuilder: (context, index) {
            final mesa = mesas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: mesa.Estado ? Colors.red : Colors.green,
                  child: Text(
                    mesa.numero.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('Mesa ${mesa.numero}'),
                subtitle: Text(
                  mesa.Estado ? 'Ocupada' : 'Disponible',
                  style: TextStyle(
                    color: mesa.Estado ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  mesa.Estado ? Icons.lock : Icons.event_seat,
                  color: mesa.Estado ? Colors.red : Colors.green,
                ),
                enabled: !mesa.Estado,
                onTap:
                    mesa.Estado
                        ? null
                        : () {
                            setState(() => _selectedMesa = mesa);
                        },
              ),
            );
          },
        );
      },
    );
  }

  Stream<List<QuerySnapshot>> _getCombinedStream() {
    final mesasStream =
        FirebaseFirestore.instance
            .collection('Restaurante')
            .doc(widget.restauranteId)
            .collection('Mesas')
            .snapshots();

    final reservasStream =
        FirebaseFirestore.instance
            .collection('Restaurante')
            .doc(widget.restauranteId)
            .collection('Reservas')
            .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<QuerySnapshot>>(
      mesasStream,
      reservasStream,
      (mesas, reservas) => [mesas, reservas],
    );
  }
}

ThemeData buildReservationTheme() {
  return ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: Colors.red,
      secondary: Colors.white,
      background: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ); // Changed from }; to );
}