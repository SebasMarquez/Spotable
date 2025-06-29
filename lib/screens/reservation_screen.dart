// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:provider/provider.dart';
// import '../providers/user_provider.dart';
// import '../widgets/orders_footer.dart';
// import 'dart:async';
// import 'package:rxdart/rxdart.dart';

// final Color primaryColor = const Color(0xFF1E88E5); // Azul principal
// final Color accentColor = const Color(0xFFFFC107); // Amarillo/acento
// final Color backgroundColor = const Color(0xFFF5F5F5); // Fondo claro
// final Color availableColor = const Color(0xFF43A047); // Verde para disponible
// final Color reservedColor = const Color(0xFFE53935); // Rojo para reservada

// // Modelo de Mesa
// class Mesa {
//   final String id; // Added field to store the document ID
//   final int numero;
//   final bool Estado;
//   final Map<String, dynamic>? datosCliente;

//   const Mesa({
//     required this.id, // Added id to constructor
//     required this.numero,
//     required this.Estado,
//     this.datosCliente,
//   });

//   String? get nombreCliente => datosCliente?['nombreCliente'];
//   int? get contactoCliente => datosCliente?['contactoCliente'];
//   Timestamp? get fecha_HoraReservacion =>
//       datosCliente?['fecha_HoraReservacion'];

//   factory Mesa.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return Mesa(
//       id: doc.id, // Store the actual document ID from Firestore
//       numero: data['numero'] ?? 0,
//       Estado: data['Estado'] ?? false,
//       datosCliente: data['datosCliente'] as Map<String, dynamic>?,
//     );
//   }
// }

// class Reserva {
//   final String id;
//   final String cedulaCliente;
//   final String contactoCliente;
//   final Timestamp fechaHoraReservacion;
//   final String idMesa;
//   final String nombreCliente;

//   const Reserva({
//     required this.id,
//     required this.cedulaCliente,
//     required this.contactoCliente,
//     required this.fechaHoraReservacion,
//     required this.idMesa,
//     required this.nombreCliente,
//   });

//   factory Reserva.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return Reserva(
//       id: doc.id,
//       cedulaCliente: data['cedulaCliente'] ?? '',
//       contactoCliente: data['contactoCliente'] ?? '',
//       fechaHoraReservacion: data['fecha_HoraReservacion'] ?? Timestamp.now(),
//       idMesa: data['id_mesa'] ?? '',
//       nombreCliente: data['nombreCliente'] ?? '',
//     );
//   }
// }

// // Pantalla principal de reservaciones con selección de fecha y hora
// class ReservationScreen extends StatefulWidget {
//   final String restauranteId;
//   const ReservationScreen({super.key, required this.restauranteId});

//   @override
//   State<ReservationScreen> createState() => _ReservationScreenState();
// }

// class _ReservationScreenState extends State<ReservationScreen> {
//   DateTime? _fechaHoraDeseada;
//   bool _fechaSeleccionada = false;

//   // Función para verificar si una mesa está ocupada en el horario seleccionado
//   bool _mesaEstaOcupada(
//     String mesaId,
//     DateTime fechaHoraDeseada,
//     List<Reserva> reservas,
//   ) {
//     // Buscar reservas para esta mesa específica
//     final reservasMesa = reservas.where((reserva) => reserva.idMesa == mesaId);

//     for (final reserva in reservasMesa) {
//       final fechaReserva = reserva.fechaHoraReservacion.toDate();
//       final finReserva = fechaReserva.add(const Duration(hours: 2));

//       // Verificar si la fecha deseada está dentro del período de reserva (2 horas)
//       if (fechaHoraDeseada.isAfter(
//             fechaReserva.subtract(const Duration(minutes: 1)),
//           ) &&
//           fechaHoraDeseada.isBefore(
//             finReserva.add(const Duration(minutes: 1)),
//           )) {
//         return true;
//       }
//     }
//     return false;
//   }

//   Future<void> _seleccionarFechaHora() async {
//     final fecha = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );

//     if (fecha != null) {
//       final hora = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.now(),
//       );

//       if (hora != null) {
//         setState(() {
//           _fechaHoraDeseada = DateTime(
//             fecha.year,
//             fecha.month,
//             fecha.day,
//             hora.hour,
//             hora.minute,
//           );
//           _fechaSeleccionada = true;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reservaciones'),
//         backgroundColor: Colors.white,
//         leading:
//             Navigator.of(context).canPop()
//                 ? IconButton(
//                   icon: const Icon(Icons.arrow_back),
//                   onPressed: () => Navigator.of(context).pop(),
//                 )
//                 : null,
//       ),
//       body: !_fechaSeleccionada ? _buildSeleccionFecha() : _buildListaMesas(),
//       bottomNavigationBar: const OrdersFooter(), // Added OrdersFooter here
//     );
//   }

//   Widget _buildSeleccionFecha() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.calendar_today, size: 80, color: Colors.blue),
//             const SizedBox(height: 24),
//             const Text(
//               'Seleccione la fecha y hora deseada para su reservación',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 32),
//             if (_fechaHoraDeseada != null) ...[
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Fecha y hora seleccionada:',
//                       style: TextStyle(fontSize: 14, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${_fechaHoraDeseada!.day}/${_fechaHoraDeseada!.month}/${_fechaHoraDeseada!.year} - ${_fechaHoraDeseada!.hour.toString().padLeft(2, '0')}:${_fechaHoraDeseada!.minute.toString().padLeft(2, '0')}',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//             ],
//             ElevatedButton.icon(
//               onPressed: _seleccionarFechaHora,
//               icon: const Icon(Icons.schedule),
//               label: Text(
//                 _fechaHoraDeseada == null
//                     ? 'Seleccionar Fecha y Hora'
//                     : 'Cambiar Fecha y Hora',
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//               ),
//             ),
//             if (_fechaHoraDeseada != null) ...[
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _fechaSeleccionada = true;
//                   });
//                 },
//                 child: const Text('Ver Mesas Disponibles'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildListaMesas() {
//     return Column(
//       children: [
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(16.0),
//           color: Colors.blue.withOpacity(0.1),
//           child: Column(
//             children: [
//               const Text(
//                 'Consulta para:',
//                 style: TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 '${_fechaHoraDeseada!.day}/${_fechaHoraDeseada!.month}/${_fechaHoraDeseada!.year} - ${_fechaHoraDeseada!.hour.toString().padLeft(2, '0')}:${_fechaHoraDeseada!.minute.toString().padLeft(2, '0')}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               TextButton.icon(
//                 onPressed: () {
//                   setState(() {
//                     _fechaSeleccionada = false;
//                   });
//                 },
//                 icon: const Icon(Icons.edit, size: 16),
//                 label: const Text('Cambiar fecha/hora'),
//                 style: TextButton.styleFrom(foregroundColor: Colors.blue),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: StreamBuilder<List<QuerySnapshot>>(
//             stream: _getCombinedStream(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (!snapshot.hasData || snapshot.data!.length < 2) {
//                 return const Center(child: Text('Error al cargar datos.'));
//               }

//               final mesasSnapshot = snapshot.data![0];
//               final reservasSnapshot = snapshot.data![1];

//               if (mesasSnapshot.docs.isEmpty) {
//                 return const Center(child: Text('No hay mesas disponibles.'));
//               }

//               final mesas =
//                   mesasSnapshot.docs
//                       .map((doc) => Mesa.fromFirestore(doc))
//                       .toList();

//               final reservas =
//                   reservasSnapshot.docs
//                       .map((doc) => Reserva.fromFirestore(doc))
//                       .toList();

//               // Calcular disponibilidad basada en las reservas
//               final mesasDisponibles =
//                   mesas
//                       .where(
//                         (mesa) =>
//                             !_mesaEstaOcupada(
//                               mesa.id,
//                               _fechaHoraDeseada!,
//                               reservas,
//                             ),
//                       )
//                       .length;

//               return Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _buildEstadisticaCard(
//                           'Disponibles',
//                           mesasDisponibles.toString(),
//                           Colors.green,
//                           Icons.event_seat,
//                         ),
//                         _buildEstadisticaCard(
//                           'Ocupadas',
//                           (mesas.length - mesasDisponibles).toString(),
//                           Colors.red,
//                           Icons.lock,
//                         ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: ListView.builder(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       itemCount: mesas.length,
//                       itemBuilder: (context, index) {
//                         final mesa = mesas[index];
//                         final estaOcupada = _mesaEstaOcupada(
//                           mesa.id,
//                           _fechaHoraDeseada!,
//                           reservas,
//                         );

//                         // Encontrar la reserva específica para mostrar información adicional
//                         Reserva? reservaActual;
//                         if (estaOcupada) {
//                           reservaActual = reservas.firstWhere(
//                             (reserva) =>
//                                 reserva.idMesa == mesa.id &&
//                                 _mesaEstaOcupada(mesa.id, _fechaHoraDeseada!, [
//                                   reserva,
//                                 ]),
//                             orElse:
//                                 () => reservas.firstWhere(
//                                   (reserva) => reserva.idMesa == mesa.id,
//                                 ),
//                           );
//                         }

//                         return Card(
//                           margin: const EdgeInsets.only(bottom: 8),
//                           child: ListTile(
//                             leading: CircleAvatar(
//                               backgroundColor:
//                                   estaOcupada ? Colors.red : Colors.green,
//                               child: Text(
//                                 mesa.numero.toString(),
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                             title: Text('Mesa ${mesa.numero}'),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   estaOcupada ? 'Ocupada' : 'Disponible',
//                                   style: TextStyle(
//                                     color:
//                                         estaOcupada ? Colors.red : Colors.green,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 if (estaOcupada && reservaActual != null) ...[
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     'Reservada por: ${reservaActual.nombreCliente}',
//                                     style: const TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                   Text(
//                                     'Hasta: ${_formatearFechaHora(reservaActual.fechaHoraReservacion.toDate().add(const Duration(hours: 2)))}',
//                                     style: const TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                             trailing: Icon(
//                               estaOcupada ? Icons.lock : Icons.event_seat,
//                               color: estaOcupada ? Colors.red : Colors.green,
//                             ),
//                             enabled: !estaOcupada,
//                             onTap:
//                                 estaOcupada
//                                     ? null
//                                     : () {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder:
//                                               (_) => FormularioReservaScreen(
//                                                 mesa: mesa,
//                                                 fechaHoraPreseleccionada:
//                                                     _fechaHoraDeseada,
//                                               ),
//                                           settings: RouteSettings(
//                                             arguments: widget.restauranteId,
//                                           ),
//                                         ),
//                                       );
//                                     },
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEstadisticaCard(
//     String titulo,
//     String valor,
//     Color color,
//     IconData icon,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(height: 8),
//           Text(
//             valor,
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           Text(
//             titulo,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//       // bottomNavigationBar: const OrdersFooter(), // Removed from here
//     );
//   }

//   String _formatearFechaHora(DateTime fechaHora) {
//     return '${fechaHora.day}/${fechaHora.month}/${fechaHora.year} ${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}';
//   }

//   Stream<List<QuerySnapshot>> _getCombinedStream() {
//     final mesasStream =
//         FirebaseFirestore.instance
//             .collection('Restaurante')
//             .doc(widget.restauranteId)
//             .collection('Mesas')
//             .snapshots();

//     final reservasStream =
//         FirebaseFirestore.instance
//             .collection('Restaurante')
//             .doc(widget.restauranteId)
//             .collection('Reservas')
//             .snapshots();

//     return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<QuerySnapshot>>(
//       mesasStream,
//       reservasStream,
//       (mesas, reservas) => [mesas, reservas],
//     );
//   }
// }

// ThemeData buildReservationTheme() {
//   return ThemeData(
//     primaryColor: primaryColor,
//     colorScheme: ColorScheme.fromSeed(
//       seedColor: primaryColor,
//       primary: Colors.red,
//       secondary: Colors.white,
//       background: Colors.white,
//     ),
//     scaffoldBackgroundColor: backgroundColor,
//     appBarTheme: AppBarTheme(
//       backgroundColor: Colors.red,
//       foregroundColor: Colors.white,
//       elevation: 2,
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: accentColor,
//         foregroundColor: Colors.black,
//         textStyle: const TextStyle(fontWeight: FontWeight.bold),
//       ),
//     ),
//     listTileTheme: ListTileThemeData(
//       tileColor: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//     ),
//   ); // Changed from }; to );
// }

// // Formulario de reserva
// class FormularioReservaScreen extends StatefulWidget {
//   final Mesa mesa;
//   final DateTime? fechaHoraPreseleccionada;

//   const FormularioReservaScreen({
//     super.key,
//     required this.mesa,
//     this.fechaHoraPreseleccionada,
//   });

//   @override
//   State<FormularioReservaScreen> createState() =>
//       _FormularioReservaScreenState();
// }

// class _FormularioReservaScreenState extends State<FormularioReservaScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _contactoController = TextEditingController();
//   DateTime? _fechaHoraSeleccionada;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     // Preseleccionar la fecha y hora si se proporciona
//     _fechaHoraSeleccionada = widget.fechaHoraPreseleccionada;
//   }

//   @override
//   void dispose() {
//     _contactoController.dispose();
//     super.dispose();
//   }

//   Future<void> _reservarMesa() async {
//     if (!_formKey.currentState!.validate() || _fechaHoraSeleccionada == null)
//       return;
//     setState(() => _isLoading = true);

//     try {
//       final restauranteIdArgs =
//           ModalRoute.of(context)?.settings.arguments as String?;
//       if (restauranteIdArgs == null || restauranteIdArgs.isEmpty) {
//         throw Exception('restauranteId no proporcionado en argumentos de ruta');
//       }

//       // Obtener nombre y cedula del provider
//       final userProvider = Provider.of<UserProvider>(context, listen: false);
//       final nombreCliente = userProvider.user?.nombre ?? '';
//       final cedulaCliente = userProvider.user?.cedula ?? '';

//       // 1. Crear el nuevo documento de reserva
//       final reservasCollection = FirebaseFirestore.instance
//           .collection('Restaurante')
//           .doc(restauranteIdArgs)
//           .collection('Reservas');

//       final newReservationData = {
//         'contactoCliente': _contactoController.text,
//         'fecha_HoraReservacion': Timestamp.fromDate(_fechaHoraSeleccionada!),
//         'id_mesa': widget.mesa.id, // ID of the Mesa document
//         'nombreCliente': nombreCliente,
//         'cedulaCliente': cedulaCliente,
//       };
//       // Firestore will auto-generate an ID for the new reservation document
//       DocumentReference reservationDocRef = await reservasCollection.add(
//         newReservationData,
//       ); // Store the reference

//       // 2. Actualizar el documento de la Mesa
//       final mesaDoc = FirebaseFirestore.instance
//           .collection('Restaurante')
//           .doc(restauranteIdArgs)
//           .collection('Mesas')
//           .doc(widget.mesa.id);

//       await mesaDoc.update({
//         'Estado': true,
//         'datosCliente': {
//           'fecha_HoraReservacion': Timestamp.fromDate(_fechaHoraSeleccionada!),
//           'reservationId':
//               reservationDocRef
//                   .id, // Optionally store reservation ID for linking
//         },
//       });

//       // 3. Guardar la información de la reserva en la subcolección del usuario
//       if (userProvider.user != null && userProvider.user!.cedula.isNotEmpty) {
//         final restauranteDocSnapshot =
//             await FirebaseFirestore.instance
//                 .collection('Restaurante')
//                 .doc(restauranteIdArgs)
//                 .get();
//         final nombreRestaurante =
//             restauranteDocSnapshot.data()?['nombre'] ?? 'Nombre no encontrado';

//         final userReservationData = {
//           'id_mesa': widget.mesa.id,
//           'nombre_restaurante': nombreRestaurante,
//           'hora_reservacion': Timestamp.fromDate(
//             _fechaHoraSeleccionada!,
//           ), // Store as Timestamp
//           'id_restaurante': restauranteIdArgs,
//           'id_reserva_restaurante':
//               reservationDocRef
//                   .id, // Link to the reservation in Restaurante/Reservas
//           'estado': 'activa', // Estado de la reserva
//           'createdAt':
//               FieldValue.serverTimestamp(), // Para ordenar o identificar la más reciente
//         };

//         await FirebaseFirestore.instance
//             .collection('Usuario')
//             .doc(cedulaCliente)
//             .collection('ReservasActivas')
//             .add(userReservationData);

//         // Ya no se actualiza el campo 'mesa' en el documento 'Usuario' ni en UserProvider directamente.
//         // El modelo UserData se modificará para eliminar el campo 'mesa'.
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Mesa reservada exitosamente')),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error al reservar: $e')));
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _seleccionarFechaHora() async {
//     final fecha = await showDatePicker(
//       context: context,
//       initialDate: _fechaHoraSeleccionada ?? DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (fecha != null) {
//       final hora = await showTimePicker(
//         context: context,
//         initialTime:
//             _fechaHoraSeleccionada != null
//                 ? TimeOfDay.fromDateTime(_fechaHoraSeleccionada!)
//                 : TimeOfDay.now(),
//       );
//       if (hora != null) {
//         setState(() {
//           _fechaHoraSeleccionada = DateTime(
//             fecha.year,
//             fecha.month,
//             fecha.day,
//             hora.hour,
//             hora.minute,
//           );
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//     final nombreCliente = userProvider.user?.nombre ?? '';
//     final cedulaCliente = userProvider.user?.cedula ?? '';
//     return Theme(
//       data: buildReservationTheme(),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('Reservar Mesa ${widget.mesa.numero}'),
//           leading:
//               Navigator.of(context).canPop()
//                   ? IconButton(
//                     icon: const Icon(Icons.arrow_back),
//                     onPressed: () => Navigator.of(context).pop(),
//                   )
//                   : null,
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child:
//               _isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : Form(
//                     key: _formKey,
//                     child: ListView(
//                       children: [
//                         Card(
//                           color: Colors.grey[100],
//                           child: ListTile(
//                             leading: const Icon(Icons.person),
//                             title: Text('Nombre: $nombreCliente'),
//                             subtitle: Text('Cédula: $cedulaCliente'),
//                           ),
//                         ),

//                         const SizedBox(height: 16),

//                         TextFormField(
//                           controller: _contactoController,
//                           decoration: const InputDecoration(
//                             labelText: 'Contacto (teléfono)',
//                             prefixIcon: Icon(Icons.phone),
//                           ),
//                           keyboardType: TextInputType.number,
//                           validator:
//                               (value) =>
//                                   value == null || value.isEmpty
//                                       ? 'Ingrese el contacto'
//                                       : null,
//                         ),
//                         const SizedBox(height: 16),
//                         Card(
//                           child: ListTile(
//                             leading: const Icon(Icons.calendar_today),
//                             title: Text(
//                               _fechaHoraSeleccionada == null
//                                   ? 'Seleccione fecha y hora'
//                                   : 'Fecha: ${_fechaHoraSeleccionada!.day}/${_fechaHoraSeleccionada!.month}/${_fechaHoraSeleccionada!.year}',
//                             ),
//                             subtitle:
//                                 _fechaHoraSeleccionada != null
//                                     ? Text(
//                                       'Hora: ${_fechaHoraSeleccionada!.hour.toString().padLeft(2, '0')}:${_fechaHoraSeleccionada!.minute.toString().padLeft(2, '0')}',
//                                     )
//                                     : null,
//                             trailing: const Icon(Icons.arrow_forward_ios),
//                             onTap: _seleccionarFechaHora,
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                         ElevatedButton.icon(
//                           onPressed: _reservarMesa,
//                           icon: const Icon(Icons.book_online),
//                           label: const Text('Confirmar Reservación'),
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//         ),
//       ),
//     );
//   }
// }
