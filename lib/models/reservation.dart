import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar una reserva desde la perspectiva del usuario.
///
/// Contiene la información esencial de una reserva que se muestra en el perfil del usuario.
class Reservation {
  final String id;
  final String restaurantName;
  final String tableId;
  final Timestamp reservationTime;

  Reservation({
    required this.id,
    required this.restaurantName,
    required this.tableId,
    required this.reservationTime,
  });

  /// Crea una instancia de [Reservation] desde un [DocumentSnapshot] de Firestore.
  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      restaurantName: data['nombre_restaurante'] ?? 'Restaurante no encontrado',
      tableId: data['id_mesa'] ?? 'N/A',
      reservationTime: data['hora_reservacion'] ?? Timestamp.now(),
    );
  }
}