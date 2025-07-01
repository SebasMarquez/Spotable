// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as OrderModel;
import '../models/reservation.dart';
import '../models/restaurant.dart';

class FirebaseService {
  // Unificamos la instancia de Firestore para que sea estática y accesible por todos los métodos.
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones
  static const String _restauranteCollection = 'Restaurante';
  static const String _menuSubCollection = 'Menu';
  static const String _ordersSubCollection = 'Order';
  static const String _usuarioCollection = 'Usuario';

   // =================================================
  // === NUEVOS MÉTODOS PARA EL PERFIL DE USUARIO ===
  // =================================================

  /// Obtiene todos los pedidos de un usuario a través de todas las tiendas.
  static Stream<List<OrderModel.Order>> getOrdersByUser(String cedula) {
    return _firestore
        .collectionGroup(_ordersSubCollection) // Busca en todas las subcolecciones 'Order'
        .where('cedulaCliente', isEqualTo: cedula)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.Order.fromFirestore(doc))
            .toList());
  }

  /// Obtiene todas las reservas de un usuario.
  static Stream<List<Reservation>> getReservationsByUser(String cedula) {
    return _firestore
        .collection(_usuarioCollection)
        .doc(cedula)
        .collection('ReservasActivas') // Usamos la colección que ya tienes
        .orderBy('hora_reservacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reservation.fromFirestore(doc))
            .toList());
  }


  // --- MÉTODOS DE GESTIÓN DE MENÚ ---

  static Future<void> _updateRestaurantCategories(String restaurantId) async {
    final menuCollection = _firestore.collection(_restauranteCollection).doc(restaurantId).collection(_menuSubCollection);
    final restaurantRef = _firestore.collection(_restauranteCollection).doc(restaurantId);
    final menuSnapshot = await menuCollection.get();
    final allCategories = <String>{};
    for (var doc in menuSnapshot.docs) {
      final menuItem = MenuItem.fromFirestore(doc);
      allCategories.addAll(menuItem.category);
    }
    await restaurantRef.set({'categories': allCategories.toList()}, SetOptions(merge: true));
  }

  static Future<void> saveMenuItem({
    required String restaurantId,
    required Map<String, dynamic> newMenuItemData,
    String? menuItemId,
  }) async {
    final menuCollection = _firestore.collection(_restauranteCollection).doc(restaurantId).collection(_menuSubCollection);
    if (menuItemId == null) {
      await menuCollection.add(newMenuItemData);
    } else {
      await menuCollection.doc(menuItemId).update(newMenuItemData);
    }
    await _updateRestaurantCategories(restaurantId);
  }

  static Future<void> deleteMenuItem({
    required String restaurantId,
    required String menuItemId,
  }) async {
    if (menuItemId.isEmpty) return;
    final menuDoc = _firestore.collection(_restauranteCollection).doc(restaurantId).collection(_menuSubCollection).doc(menuItemId);
    await menuDoc.delete();
    await _updateRestaurantCategories(restaurantId);
  }

  // --- MÉTODOS DE LECTURA DE DATOS ---

  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _firestore.collection(_restauranteCollection).get();
    return snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Obtiene solo los restaurantes que pertenecen a una categoría específica.
  Future<List<Restaurant>> getRestaurantsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_restauranteCollection)
          .where('categories', arrayContains: category)
          .get();
          
      return snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("****************************************************");
      print("Error al obtener restaurantes por categoría: $e");
      if (e.toString().contains('requires an index')) {
          print("POSIBLE SOLUCIÓN: Parece que necesitas crear un índice en Firestore.");
          print("Revisa la consola de debug de Flutter. Usualmente Firebase te da un link directo para crearlo con un solo clic.");
      }
      print("****************************************************");
      return [];
    }
  }
  
  static Stream<List<MenuItem>> getMenuItemsByCategory(String id_cantina, String category) {
    return _firestore
        .collection(_restauranteCollection)
        .doc(id_cantina)
        .collection(_menuSubCollection)
        .where("available", isEqualTo: true)
        .where("Categoria", arrayContains: category)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList());
  }
  
  static Future<String> createOrder(String idCantina, Map<String, dynamic> orderData) async {
    final restaurantDoc = await _firestore.collection(_restauranteCollection).doc(idCantina).get();
    if (!restaurantDoc.exists) {
      throw Exception('Restaurante no encontrado');
    }
    final docRef = await _firestore.collection(_restauranteCollection).doc(idCantina).collection(_ordersSubCollection).add(orderData);
    return docRef.id;
  }
  
  static Stream<List<MenuItem>> getMenuItems(String id_cantina) {
    return _firestore.collection(_restauranteCollection).doc(id_cantina).collection(_menuSubCollection).where("available", isEqualTo: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList());
  }

  static Stream<List<MenuItem>> getAllMenuItems(String id_cantina) {
    return _firestore.collection(_restauranteCollection).doc(id_cantina).collection(_menuSubCollection).snapshots().map((snapshot) => snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList());
  }

  static Stream<List<OrderModel.Order>> getOrdersByRestaurante(String idCantina) {
    return _firestore.collection(_restauranteCollection).doc(idCantina).collection(_ordersSubCollection).orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => OrderModel.Order.fromFirestore(doc)).toList());
  }

  Future<bool> restaurantExists(String id) async {
    final doc = await _firestore.collection(_restauranteCollection).doc(id).get();
    return doc.exists;
  }

  Future<Map<String, dynamic>?> fetchRestaurantInfo(String restaurantId) async {
    final doc = await _firestore.collection(_restauranteCollection).doc(restaurantId).get();
    return doc.data();
  }

  static Stream<List<String>> getCategories(String id_cantina) {
    return _firestore.collection(_restauranteCollection).doc(id_cantina).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return [];
      final data = snapshot.data()!;
      final categories = data['categories'] as List<dynamic>? ?? [];
      return List<String>.from(categories.map((c) => c.toString()));
    });
  }

  static Future<void> saveUser({required String idUsuario, required String nombre, required String cedula}) async {
    await _firestore.collection(_usuarioCollection).doc(idUsuario).set({'nombre': nombre, 'cedula': cedula, 'mesa': {'id_mesa': '', 'nombre_restaurante': '', 'hora_reservacion': ''}});
  }

  static Future<Map<String, dynamic>?> getUserByCedula(String cedula) async {
    final doc = await _firestore.collection(_usuarioCollection).doc(cedula).get();
    return doc.exists ? doc.data() : null;
  }
  
  static Future<void> updateOrderEstado({required String restaurantId, required String orderId, required String nuevoEstado}) async {
    await _firestore.collection(_restauranteCollection).doc(restaurantId).collection(_ordersSubCollection).doc(orderId).update({'estado': nuevoEstado});
  }

  static Future<void> updateOrderDeliveryType({
    required String restaurantId,
    required String orderId,
    required String newDeliveryType,
    String? newDeliveryAddress,
    String? newTableId,
  }) async {
    final updateData = <String, dynamic>{
      'deliveryType': newDeliveryType,
    };

    if (newDeliveryType == 'delivery') {
      updateData['deliveryAddress'] = newDeliveryAddress;
      updateData['idMesa'] = FieldValue.delete(); // Elimina el ID de la mesa si se cambia a domicilio
    } else if (newDeliveryType == 'dineIn') {
      updateData['idMesa'] = newTableId;
      updateData['deliveryAddress'] = FieldValue.delete(); // Elimina la dirección si se cambia a comer en local
    }
    await _firestore.collection(_restauranteCollection).doc(restaurantId).collection(_ordersSubCollection).doc(orderId).update(updateData);
  }

  static Future<void> updateTableStatus({required String restaurantId, required String tableId, required bool isOccupied}) async {
    await _firestore.collection(_restauranteCollection).doc(restaurantId).collection('Mesas').doc(tableId).update({'Estado': isOccupied});
  }
  
  static Future<void> setTableAsAvailableAndClearReservation({required String restaurantId, required String tableId}) async {
    final batch = _firestore.batch();
    final tableRef = _firestore.collection(_restauranteCollection).doc(restaurantId).collection('Mesas').doc(tableId);
    batch.update(tableRef, {'Estado': false, 'datosCliente': FieldValue.delete()});
    await batch.commit();
  }
}
