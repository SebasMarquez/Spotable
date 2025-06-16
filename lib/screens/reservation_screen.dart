import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final Color primaryColor = const Color(0xFF1E88E5); // Azul principal
final Color accentColor = const Color(0xFFFFC107); // Amarillo/acento
final Color backgroundColor = const Color(0xFFF5F5F5); // Fondo claro
final Color availableColor = const Color(0xFF43A047); // Verde para disponible
final Color reservedColor = const Color(0xFFE53935); // Rojo para reservada

// Modelo de Mesa
class Mesa {
  final int numero;
  final bool Estado;
  final Map<String, dynamic>? datosCliente;

  const Mesa({required this.numero, required this.Estado, this.datosCliente});

  String? get nombreCliente => datosCliente?['nombreCliente'];
  int? get contactoCliente => datosCliente?['contactoCliente'];
  Timestamp? get fecha_HoraReservacion =>
      datosCliente?['fecha_HoraReservacion'];

  factory Mesa.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Mesa(
      numero: data['numero'] ?? 0,
      Estado: data['Estado'] ?? false,
      datosCliente: data['datosCliente'] as Map<String, dynamic>?,
    );
  }
}

// Pantalla principal de mesas, ahora recibe el restauranteId
class ReservationScreen extends StatelessWidget {
  final String restauranteId;
  const ReservationScreen({super.key, required this.restauranteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservaciones'),
        backgroundColor: Colors.white,
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Restaurante')
                .doc(restauranteId)
                .collection('Mesas')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay mesas disponibles.'));
          }
          final mesas =
              snapshot.data!.docs
                  .map((doc) => Mesa.fromFirestore(doc))
                  .toList();
          final disponibles = mesas.where((m) => !m.Estado).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Mesas disponibles: $disponibles',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: mesas.length,
                  itemBuilder: (context, index) {
                    final mesa = mesas[index];
                    return ListTile(
                      title: Text('Mesa ${mesa.numero}'),
                      subtitle: Text(mesa.Estado ? 'Reservada' : 'Disponible'),
                      trailing: Icon(
                        mesa.Estado ? Icons.lock : Icons.event_seat,
                        color: mesa.Estado ? Colors.red : Colors.green,
                      ),
                      enabled: !mesa.Estado,
                      onTap:
                          mesa.Estado
                              ? null
                              : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            FormularioReservaScreen(mesa: mesa),
                                    settings: RouteSettings(
                                      arguments: restauranteId,
                                    ),
                                  ),
                                );
                              },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
  );
}

// Para aplicar el tema al formulario de reserva, envuelve el widget en un Theme:
class FormularioReservaScreen extends StatefulWidget {
  final Mesa mesa;
  const FormularioReservaScreen({super.key, required this.mesa});

  @override
  State<FormularioReservaScreen> createState() =>
      _FormularioReservaScreenState();
}

class _FormularioReservaScreenState extends State<FormularioReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  DateTime? _fechaHoraSeleccionada;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  Future<void> _reservarMesa() async {
    if (!_formKey.currentState!.validate() || _fechaHoraSeleccionada == null)
      return;
    setState(() => _isLoading = true);

    try {
      final restauranteId =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (restauranteId == null || restauranteId.isEmpty) {
        throw Exception('restauranteId no proporcionado');
      }
      final mesaDoc = FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(restauranteId)
          .collection('Mesas')
          .doc('Mesa_${widget.mesa.numero.toString()}');

      await mesaDoc.update({
        'Estado': true,
        'datosCliente': {
          'nombreCliente': _nombreController.text,
          'contactoCliente': int.tryParse(_contactoController.text),
          'fecha_HoraReservacion': Timestamp.fromDate(_fechaHoraSeleccionada!),
        },
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesa reservada exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al reservar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFechaHora() async {
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
          _fechaHoraSeleccionada = DateTime(
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

  @override
  Widget build(BuildContext context) {
    final restauranteId = ModalRoute.of(context)?.settings.arguments as String?;
    return Theme(
      data: buildReservationTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reservar Mesa ${widget.mesa.numero}'),
          leading:
              Navigator.of(context).canPop()
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                  : null,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del cliente',
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Ingrese el nombre'
                                      : null,
                        ),
                        TextFormField(
                          controller: _contactoController,
                          decoration: const InputDecoration(
                            labelText: 'Contacto (teléfono)',
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Ingrese el contacto'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(
                            _fechaHoraSeleccionada == null
                                ? 'Seleccione fecha y hora'
                                : 'Reservado para: ${_fechaHoraSeleccionada!.toLocal()}',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _seleccionarFechaHora,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _reservarMesa,
                          child: const Text('Reservar'),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
/*
class FormularioReservaScreen extends StatefulWidget {
  final Mesa mesa;
  const FormularioReservaScreen({super.key, required this.mesa});

  @override
  State<FormularioReservaScreen> createState() =>
      _FormularioReservaScreenState();
}

class _FormularioReservaScreenState extends State<FormularioReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  DateTime? _fechaHoraSeleccionada;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  Future<void> _reservarMesa() async {
    if (!_formKey.currentState!.validate() || _fechaHoraSeleccionada == null)
      return;
    setState(() => _isLoading = true);

    try {
      final restauranteId =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (restauranteId == null || restauranteId.isEmpty) {
        throw Exception('restauranteId no proporcionado');
      }
      final mesaDoc = FirebaseFirestore.instance
          .collection('Restaurante')
          .doc(restauranteId)
          .collection('Mesas')
          .doc('Mesa_${widget.mesa.numero.toString()}');

      await mesaDoc.update({
        'Estado': true,
        'datosCliente': {
          'nombreCliente': _nombreController.text,
          'contactoCliente': int.tryParse(_contactoController.text),
          'fecha_HoraReservacion': Timestamp.fromDate(_fechaHoraSeleccionada!),
        },
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesa reservada exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al reservar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFechaHora() async {
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
          _fechaHoraSeleccionada = DateTime(
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

  @override
  Widget build(BuildContext context) {
    final restauranteId = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(title: Text('Reservar Mesa ${widget.mesa.numero}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del cliente',
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Ingrese el nombre'
                                    : null,
                      ),
                      TextFormField(
                        controller: _contactoController,
                        decoration: const InputDecoration(
                          labelText: 'Contacto (teléfono)',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Ingrese el contacto'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          _fechaHoraSeleccionada == null
                              ? 'Seleccione fecha y hora'
                              : 'Reservado para: ${_fechaHoraSeleccionada!.toLocal()}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _seleccionarFechaHora,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _reservarMesa,
                        child: const Text('Reservar'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}*/

// Asegura que el restauranteId se pase correctamente al formulario de reserva
// y que la actualización en Firestore use la ruta adecuada.

/// Cambia el onTap en ReservationScreen para pasar restauranteId:
/// (Reemplaza el onTap actual en ListTile)
///
/// onTap: mesa.Estado
///   ? null
///   : () {
///       Navigator.push(
///         context,
///         MaterialPageRoute(
///           builder: (_) => FormularioReservaScreen(mesa: mesa),
///           settings: RouteSettings(arguments: restauranteId),
///         ),
///       );
///     },

// Y en FormularioReservaScreen, modifica _reservarMesa para actualizar usando el id del documento de la mesa:
//
// 1. Pasa el id del documento de la mesa al modelo Mesa:

/*
class Mesa {
  final int numero;
  final bool reservada;
  const Mesa({required this.numero, required this.reservada});
}

// Pantalla de formulario de reserva
class FormularioReservaScreen extends StatelessWidget {
  final Mesa mesa;
  const FormularioReservaScreen({super.key, required this.mesa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reservar Mesa ${mesa.numero}')),
      body: Center(
        child: Text('Formulario de reserva para la mesa ${mesa.numero}'),
      ),
    );
  }
}

// Pantalla principal de mesas
class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  static const List<Mesa> mesas = [
    Mesa(numero: 1, reservada: true),
    Mesa(numero: 2, reservada: false),
    Mesa(numero: 3, reservada: false),
    Mesa(numero: 4, reservada: true),
    Mesa(numero: 5, reservada: false),
    Mesa(numero: 6, reservada: false),
    Mesa(numero: 7, reservada: true),
    Mesa(numero: 8, reservada: false),
    Mesa(numero: 9, reservada: false),
    Mesa(numero: 10, reservada: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesas disponibles')),
      body: ListView.builder(
        itemCount: mesas.length,
        itemBuilder: (context, index) {
          final mesa = mesas[index];
          return ListTile(
            title: Text('Mesa ${mesa.numero}'),
            subtitle: Text(mesa.reservada ? 'Reservada' : 'Disponible'),
            trailing: Icon(
              mesa.reservada ? Icons.lock : Icons.event_seat,
              color: mesa.reservada ? Colors.red : Colors.green,
            ),
            enabled: !mesa.reservada,
            onTap:
                mesa.reservada
                    ? null
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormularioReservaScreen(mesa: mesa),
                        ),
                      );
                    },
          );
        },
      ),
    );
  }
}
*/
