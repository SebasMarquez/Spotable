import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:rxdart/rxdart.dart';

// Modelo de Mesa (simplificado para este contexto)
class Mesa {
  final String id;
  final int numero;
  final bool isOccupied; // Si está físicamente ocupada
  final bool isReserved; // Si tiene una reserva futura

  const Mesa({
    required this.id,
    required this.numero,
    required this.isOccupied,
    required this.isReserved,
  });

  factory Mesa.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Mesa(
      id: doc.id,
      numero: data['numero'] ?? 0,
      isOccupied: data['Estado'] ?? false,
      isReserved: data['reservaInfo'] != null, // La mesa está reservada si tiene info de reserva
    );
  }
}

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

  Future<void> _seleccionarFechaHora(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
    );

    if (hora != null) {
      setState(() {
        _fechaHoraDeseada = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
      });
    }
  }

  // --- LÓGICA DE RESERVA ACTUALIZADA ---
  Future<void> _reservarMesa() async {
    if (!_formKey.currentState!.validate() || _fechaHoraDeseada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa todos los campos.')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final nombreCliente = userProvider.user?.nombre ?? 'Cliente';
      final cedulaCliente = userProvider.user?.cedula ?? '';

      // Referencia a la colección de reservas
      final reservasCollection = FirebaseFirestore.instance
          .collection('Restaurante').doc(widget.restauranteId).collection('Reservas');
      
      // Creamos la nueva reserva
      final newReservationData = {
        'contactoCliente': _contactoController.text,
        'fecha_HoraReservacion': Timestamp.fromDate(_fechaHoraDeseada!),
        'id_mesa': _selectedMesa!.id,
        'numero_mesa': _selectedMesa!.numero,
        'nombreCliente': nombreCliente,
        'cedulaCliente': cedulaCliente,
      };
      DocumentReference reservationDocRef = await reservasCollection.add(newReservationData);

      // Referencia a la mesa seleccionada
      final mesaDoc = FirebaseFirestore.instance
          .collection('Restaurante').doc(widget.restauranteId).collection('Mesas').doc(_selectedMesa!.id);

      // ¡CAMBIO CLAVE AQUÍ!
      // Ya NO se cambia el campo 'Estado'. Solo se añade la información de la reserva.
      await mesaDoc.update({
        'reservaInfo': {
          'reservaId': reservationDocRef.id,
          'nombreCliente': nombreCliente,
          'fecha_HoraReservacion': Timestamp.fromDate(_fechaHoraDeseada!),
        }
      });

      // (Opcional) Guardar la reserva en el perfil del usuario (tu lógica existente)
      // ...

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesa reservada exitosamente')));
      Navigator.of(context).pop();

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reservar: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_selectedMesa == null ? 'Hacer una Reservación' : 'Confirmar para Mesa ${_selectedMesa!.numero}'),
      content: SizedBox(width: double.maxFinite, child: _buildDialogContent()),
      actions: _buildDialogActions(),
    );
  }

  Widget _buildDialogContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return _selectedMesa == null ? _buildTableSelection() : _buildReservationForm();
  }

  List<Widget> _buildDialogActions() {
    if (_selectedMesa == null) {
      return [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar'))];
    } else {
      return [
        TextButton(onPressed: _isLoading ? null : () => setState(() => _selectedMesa = null), child: const Text('Atrás')),
        ElevatedButton(onPressed: _isLoading ? null : _reservarMesa, child: const Text('Confirmar')),
      ];
    }
  }

  Widget _buildTableSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () => _seleccionarFechaHora(context),
          icon: const Icon(Icons.calendar_today),
          label: Text(_fechaHoraDeseada == null ? 'Seleccionar Fecha y Hora' : 'Cambiar Fecha y Hora'),
        ),
        if (_fechaHoraDeseada != null)
          Expanded(child: _buildTableList()),
      ],
    );
  }

  Widget _buildReservationForm() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('Nombre: ${userProvider.user?.nombre ?? ''}'),
            subtitle: Text('Cédula: ${userProvider.user?.cedula ?? ''}'),
          ),
          TextFormField(
            controller: _contactoController,
            decoration: const InputDecoration(labelText: 'Contacto (teléfono)', prefixIcon: Icon(Icons.phone)),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'Ingrese el contacto' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTableList() {
    return StreamBuilder<QuerySnapshot>(
      // Solo mostramos mesas que no estén físicamente ocupadas
      stream: FirebaseFirestore.instance
          .collection('Restaurante').doc(widget.restauranteId).collection('Mesas')
          .where('Estado', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No hay mesas disponibles.'));
        
        final mesas = snapshot.data!.docs.map((doc) => Mesa.fromFirestore(doc)).toList();

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 16),
          itemCount: mesas.length,
          itemBuilder: (context, index) {
            final mesa = mesas[index];
            final bool isClickable = !mesa.isReserved; // La mesa solo es clickeable si no tiene ya una reserva futura

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isClickable ? Colors.green : Colors.orange,
                  child: Text(mesa.numero.toString(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text('Mesa ${mesa.numero}'),
                subtitle: Text(
                  isClickable ? 'Disponible' : 'Ya reservada',
                  style: TextStyle(color: isClickable ? Colors.green : Colors.orange),
                ),
                onTap: isClickable ? () => setState(() => _selectedMesa = mesa) : null,
              ),
            );
          },
        );
      },
    );
  }
}
