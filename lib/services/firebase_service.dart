// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as OrderModel;
import '../models/restaurant.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones
  static const String _restauranteCollection = 'Restaurante';
  static const String _menuSubCollection = 'Menu';
  static const String _ordersSubCollection =
      'Order'; // Cambia a 'ordenes' si ese es el nombre en tu Firebase
  static const String _categoriesCollection = 'categories';

  // ========== ÓRDENES ==========

  /// Crear una orden en la subcolección orders del restaurante específico
  static Future<String> createOrder(
    String idCantina,
    Map<String, dynamic> orderData,
  ) async {
    print('=== 🔥 CREANDO ORDEN EN FIRESTORE ===');
    print('🏪 Restaurante ID: $idCantina');
    print(
      '📍 Ruta completa: $_restauranteCollection/$idCantina/$_ordersSubCollection',
    );
    print('📋 Datos de la orden:');
    orderData.forEach((key, value) {
      print('   $key: $value');
    });

    try {
      // Verificar que el restaurante existe
      final restaurantDoc =
          await _firestore
              .collection(_restauranteCollection)
              .doc(idCantina)
              .get();

      if (!restaurantDoc.exists) {
        print('❌ El restaurante $idCantina NO EXISTE en Firestore');
        throw Exception('Restaurante no encontrado');
      }

      print('✅ Restaurante existe, procediendo a crear la orden...');

      // Crear la orden
      final docRef = await _firestore
          .collection(_restauranteCollection)
          .doc(idCantina)
          .collection(_ordersSubCollection)
          .add(orderData);

      print('✅ ¡ORDEN CREADA EXITOSAMENTE!');
      print('🆔 ID de la orden: ${docRef.id}');
      print(
        '🔗 Ruta completa: $_restauranteCollection/$idCantina/$_ordersSubCollection/${docRef.id}',
      );
      print('=======================================');

      return docRef.id;
    } catch (e) {
      print('❌ ERROR AL CREAR ORDEN:');
      print('   Tipo de error: ${e.runtimeType}');
      print('   Mensaje: $e');
      print('   Restaurante ID: $idCantina');
      print(
        '   Ruta intentada: $_restauranteCollection/$idCantina/$_ordersSubCollection',
      );
      print('=======================================');
      throw e;
    }
  }

  /// Verificar la estructura de Firebase para debugging
  static Future<void> debugFirebaseStructure(String idCantina) async {
    print('=== 🔍 DEBUG: ESTRUCTURA DE FIREBASE ===');

    try {
      // 1. Verificar colección principal
      final restaurantesSnapshot =
          await _firestore.collection(_restauranteCollection).limit(5).get();

      print('📚 Documentos en colección "$_restauranteCollection":');
      for (var doc in restaurantesSnapshot.docs) {
        print('   - ${doc.id}');
      }

      // 2. Verificar documento específico
      final restaurantDoc =
          await _firestore
              .collection(_restauranteCollection)
              .doc(idCantina)
              .get();

      print('🏪 Restaurante "$idCantina" existe: ${restaurantDoc.exists}');

      if (restaurantDoc.exists) {
        // 3. Verificar subcolecciones
        print('📋 Verificando subcolecciones...');

        // Menu
        final menuSnapshot =
            await _firestore
                .collection(_restauranteCollection)
                .doc(idCantina)
                .collection(_menuSubCollection)
                .limit(3)
                .get();
        print('   Menu: ${menuSnapshot.docs.length} documentos');

        // Orders
        final ordersSnapshot =
            await _firestore
                .collection(_restauranteCollection)
                .doc(idCantina)
                .collection(_ordersSubCollection)
                .limit(3)
                .get();
        print('   Orders: ${ordersSnapshot.docs.length} documentos');

        // Intentar obtener todas las subcolecciones (Firebase no lo permite directamente,
        // pero podemos probar nombres comunes)
        final commonNames = [
          'orders',
          'ordenes',
          'Orders',
          'Ordenes',
          'pedidos',
          'Pedidos',
        ];
        for (String name in commonNames) {
          try {
            final snapshot =
                await _firestore
                    .collection(_restauranteCollection)
                    .doc(idCantina)
                    .collection(name)
                    .limit(1)
                    .get();
            if (snapshot.docs.isNotEmpty) {
              print(
                '   ✅ Subcolección "$name" existe y tiene ${snapshot.docs.length} documento(s)',
              );
            }
          } catch (e) {
            // Silently ignore
          }
        }
      }
    } catch (e) {
      print('❌ Error en debug: $e');
    }

    print('=========================================');
  }

  // ========== MÉTODOS EXISTENTES (sin cambios) ==========

  /// Obtener todos los items del menú
  static Stream<List<MenuItem>> getMenuItems(String id_cantina) {
    return _firestore
        .collection(_restauranteCollection)
        .doc(id_cantina)
        .collection(_menuSubCollection)
        .where("available", isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          print('Documentos encontrados: ${snapshot.docs.length}');

          final items =
              snapshot.docs
                  .map((doc) {
                    try {
                      final item = MenuItem.fromFirestore(doc);
                      print('Item creado exitosamente: ${item.name}');
                      return item;
                    } catch (e) {
                      print('Error creando item desde documento ${doc.id}: $e');
                      return null;
                    }
                  })
                  .where((item) => item != null)
                  .cast<MenuItem>()
                  .toList();

          print('Items finales: ${items.length}');
          return items;
        });
  }

  static Stream<List<MenuItem>> getAllMenuItems(String id_cantina) {
    return _firestore
        .collection(_restauranteCollection)
        .doc(id_cantina)
        .collection(_menuSubCollection)
        .snapshots()
        .map((snapshot) {
          print('Documentos encontrados (todos): ${snapshot.docs.length}');

          final items =
              snapshot.docs
                  .map((doc) {
                    try {
                      final item = MenuItem.fromFirestore(doc);
                      print(
                        'Item creado exitosamente: ${item.name} (${item.available ? "Disponible" : "No disponible"})',
                      );
                      return item;
                    } catch (e) {
                      print('Error creando item desde documento ${doc.id}: $e');
                      return null;
                    }
                  })
                  .where((item) => item != null)
                  .cast<MenuItem>()
                  .toList();

          print('Items finales (todos): ${items.length}');
          return items;
        });
  }

  /// Obtener items por categoría de un restaurante especifico
  static Stream<List<MenuItem>> getMenuItemsByCategory(
    String id_cantina,
    String categoria,
  ) {
    return _firestore
        .collection(_restauranteCollection)
        .doc(id_cantina)
        .collection(_menuSubCollection)
        .where('Categoria', isEqualTo: categoria)
        .where("available", isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MenuItem.fromFirestore(doc))
              .toList();
        });
  }

  /// Verificar si el documento del restaurante existe
  static Future<bool> checkRestaurantExists(String id_cantina) async {
    try {
      final doc =
          await _firestore
              .collection(_restauranteCollection)
              .doc(id_cantina)
              .get();

      return doc.exists;
    } catch (e) {
      print('Error verificando restaurante: $e');
      return false;
    }
  }

  /// Obtener todas las órdenes de un restaurante específico
  static Stream<List<OrderModel.Order>> getOrdersByRestaurante(
    String idCantina,
  ) {
    return _firestore
        .collection(_restauranteCollection)
        .doc(idCantina)
        .collection(_ordersSubCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Órdenes encontradas: ${snapshot.docs.length}');
          return snapshot.docs
              .map((doc) {
                try {
                  return OrderModel.Order.fromFirestore(doc);
                } catch (e) {
                  print('Error procesando orden ${doc.id}: $e');
                  return null;
                }
              })
              .where((order) => order != null)
              .cast<OrderModel.Order>()
              .toList();
        });
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _db.collection('Restaurante').get();
    return snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<bool> restaurantExists(String id) async {
    final doc = await _db.collection('Restaurante').doc(id).get();
    return doc.exists;
  }

  Future<Map<String, dynamic>?> fetchRestaurantInfo(String restaurantId) async {
    final doc = await _db.collection('Restaurante').doc(restaurantId).get();
    return doc.data();
  }

  Stream<QuerySnapshot> ordersStream(String restaurantId) {
    return _db
        .collection('Restaurante')
        .doc(restaurantId)
        .collection('Order')
        .snapshots();
  }

  static Stream<List<String>> getCategories(String id_cantina) {
    return _firestore
        .collection(_restauranteCollection)
        .doc(id_cantina)
        .collection(_menuSubCollection)
        .snapshots()
        .map((snapshot) {
          // Usar un Set para evitar duplicados
          final categories = <String>{};

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              // Buscar tanto 'category' como 'Categoria' para compatibilidad
              final category =
                  data['category'] as String? ??
                  data['Categoria'] as String? ??
                  data['categoria']
                      as String?; // Añadir más variantes si es necesario

              if (category != null && category.trim().isNotEmpty) {
                categories.add(category.trim()); // Eliminar espacios en blanco
              }
            } catch (e) {
              print('Error procesando documento ${doc.id}: $e');
              // Continuar con el siguiente documento
            }
          }

          // Convertir Set a List y ordenar alfabéticamente
          final sortedCategories = categories.toList()..sort();

          print('Categorías encontradas: $sortedCategories'); // Para debug

          return sortedCategories;
        });
  }

  /// Guardar usuario en la colección Usuario
  static Future<void> saveUser({
    required String idUsuario,
    required String nombre,
    required String cedula,
  }) async {
    await _firestore.collection('Usuario').doc(idUsuario).set({
      'nombre': nombre,
      'cedula': cedula,
      'mesa': {
        // Nuevo mapa 'mesa'
        'id_mesa': '',
        'nombre_restaurante': '',
        'hora_reservacion': '', // O podrías usar null si prefieres
      },
    });
  }

  /// Obtener usuario por cédula
  static Future<Map<String, dynamic>?> getUserByCedula(String cedula) async {
    try {
      final doc = await _firestore.collection('Usuario').doc(cedula).get();
      if (doc.exists) {
        return doc.data();
      } else {
        return null;
      }
    } catch (e) {
      print('Error buscando usuario por cédula: $e');
      return null;
    }
  }

  /// Actualizar el estado de una orden
  static Future<void> updateOrderEstado({
    required String restaurantId,
    required String orderId,
    required String nuevoEstado,
  }) async {
    await _firestore
        .collection(_restauranteCollection)
        .doc(restaurantId)
        .collection(_ordersSubCollection)
        .doc(orderId)
        .update({'estado': nuevoEstado});
  }

  // NUEVO: Actualizar el tipo de entrega de una orden
  static Future<void> updateOrderDeliveryType({
    required String restaurantId,
    required String orderId,
    required String newDeliveryType,
    String? newDeliveryAddress, // Para 'delivery'
    String? newTableId, // Para 'dineIn'
  }) async {
    final updateData = <String, dynamic>{
      'deliveryType': newDeliveryType,
      'deliveryAddress': null, // Clear if changing to dineIn
      'idMesa': null, // Clear if changing to delivery
    };

    if (newDeliveryType == 'delivery' && newDeliveryAddress != null) {
      updateData['deliveryAddress'] = newDeliveryAddress;
    } else if (newDeliveryType == 'dineIn' && newTableId != null) {
      updateData['idMesa'] = newTableId;
    }

    try {
      await _firestore
          .collection(_restauranteCollection)
          .doc(restaurantId)
          .collection(_ordersSubCollection)
          .doc(orderId)
          .update(updateData);
      print('DEBUG: Tipo de entrega de orden $orderId actualizado a $newDeliveryType');
    } catch (e) {
      print('ERROR: Al actualizar tipo de entrega de orden $orderId: $e');
      rethrow; // Re-lanzar el error para que la UI lo maneje
    }
  }
}