import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant.dart';

class FirebaseService {
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
}
