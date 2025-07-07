import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_user;

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth methods
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      print('Intentando login con email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Login exitoso en Firebase Auth, UID: ${credential.user!.uid}');
      // Verify user role
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      print('Documento encontrado en Firestore: ${userDoc.exists}');
      if (!userDoc.exists) {
        print('Usuario no encontrado en Firestore');
        throw Exception('Usuario no encontrado');
      }
      final userData = userDoc.data()!;
      print('Datos del usuario: $userData');
      // Ya no se valida el rol aquí, solo se retorna el credential
      return credential;
    } catch (e) {
      print('Error en signInWithEmailAndPassword: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
    {String? phone, String? personalId}
  ) async {
    if (!['client', 'restaurant'].contains(role)) {
      throw Exception('Solo puedes registrarte como Cliente o Restaurante. Los empleados solo pueden ser invitados.');
    }
    try {
      print('Creando usuario con email: $email, role: $role, name: $name');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Usuario creado en Firebase Auth, UID: ${credential.user!.uid}');

      // Create user document
      final user = app_user.User(
        id: credential.user!.uid, // Usar el ID autogenerado por Firebase Auth
        email: email,
        name: name,
        role: role,
        phone: phone,
        password: password, // Guardar contraseña en texto plano para desarrollo
        personalId: personalId, // Guardar cédula de identidad
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        profileImageUrl: null,
        preferences: {},
        addresses: [],
        paymentMethods: [],
        permissions: [],
        isEmployee: false, // Los usuarios registrados por email no son empleados inicialmente
      );

      final userId = credential.user!.uid;
      print('Guardando documento en Firestore con ID: $userId');
      print('Datos del usuario: ${user.toMap()}');

      await _firestore
          .collection('users')
          .doc(userId)
          .set(user.toMap());

      print('Documento guardado exitosamente en Firestore');
      return credential;
    } catch (e) {
      print('Error en createUserWithEmailAndPassword: $e');
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential> signInWithGoogle(String role) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Sign in cancelled');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Check if user exists and verify role
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        print('Usuario existente encontrado: ${userData['email']}');
        
        // Verificar si es empleado usando el campo isEmployee
        final isEmployee = userData['isEmployee'] == true;
        print('Es empleado: $isEmployee, Rol seleccionado: $role');
        
        // Lógica de verificación:
        // - Si el usuario es empleado (isEmployee: true), debe seleccionar 'restaurant'
        // - Si el usuario no es empleado (isEmployee: false o null), debe seleccionar 'client'
        if (isEmployee && role != 'restaurant') {
          print('Usuario es empleado pero seleccionó rol: $role');
          await _auth.signOut();
          throw Exception('Este usuario es un empleado. Selecciona "Restaurante" para acceder.');
        } else if (!isEmployee && role != 'client') {
          print('Usuario no es empleado pero seleccionó rol: $role');
          await _auth.signOut();
          throw Exception('Este usuario es un cliente. Selecciona "Cliente" para acceder.');
        }
        
        print('Login exitoso con rol correcto');
      } else {
        // Create new user document
        final user = app_user.User(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? 'Usuario',
          role: role,
          phone: userCredential.user!.phoneNumber,
          password: null, // Google users don't have password
          personalId: null, // Google users don't have personalId initially
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          profileImageUrl: userCredential.user!.photoURL,
          preferences: {},
          addresses: [],
          paymentMethods: [],
          permissions: [],
          isEmployee: false, // Los usuarios de Google no son empleados inicialmente
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(user.toMap());
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Iniciando proceso de logout...');
      
      // Cerrar sesión de Google Sign-In
      try {
        await _googleSignIn.signOut();
        print('Google Sign-In cerrado exitosamente');
      } catch (e) {
        // Ignorar errores de Google Sign-In (especialmente en web sin ClientID configurado)
        print('Google Sign-In signOut error (ignored): $e');
      }
      
      // Cerrar sesión de Firebase Auth
      await _auth.signOut();
      print('Firebase Auth cerrado exitosamente');
      
      // Verificar que no hay usuario activo
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Logout completado: No hay usuario activo');
      } else {
        print('ADVERTENCIA: Usuario aún activo después del logout: ${currentUser.email}');
      }
    } catch (e) {
      print('Error durante el logout: $e');
      rethrow;
    }
  }

  // Get current user data
  Future<app_user.User?> getCurrentUserData() async {
    if (currentUser == null) {
      print('No hay usuario autenticado en Firebase Auth');
      return null;
    }
    
    print('Obteniendo datos del usuario: ${currentUser!.uid}');
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        print('Documento encontrado en Firestore');
        final userData = app_user.User.fromMap(doc.data()!, doc.id);
        print('Usuario cargado: [33m[1m[4m${userData.name}[0m, Email: ${userData.email}, ID: ${userData.id}');
        return userData;
      } else {
        print('Documento no encontrado en Firestore para UID: ${currentUser!.uid}');
        return null;
      }
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUser == null) throw Exception('Usuario no autenticado');
    
    updates['updatedAt'] = DateTime.now();
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .update(updates);
  }

  // Restaurant Management
  Future<String> createRestaurant(Map<String, dynamic> restaurantData) async {
    if (currentUser == null) throw Exception('Usuario no autenticado');
    
    final docRef = await _firestore.collection('restaurants').add(restaurantData);
    
    // Update user with restaurant reference
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .update({
          'restaurantId': docRef.id,
          'updatedAt': DateTime.now(),
        });
    
    return docRef.id;
  }

  Future<Map<String, dynamic>?> getRestaurant(String restaurantId) async {
    final doc = await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .get();
    
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getRestaurantsByCategory(String category) async {
    final querySnapshot = await _firestore
        .collection('restaurants')
        .where('categories', arrayContains: category)
        .where('isActive', isEqualTo: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => doc.data())
        .toList();
  }

  Future<void> updateRestaurant(String restaurantId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = DateTime.now();
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .update(updates);
  }

  // Employee Management Methods
  Future<String> inviteEmployee(
    String restaurantId,
    String email,
    String name,
    String role,
    List<String> permissions,
    String password, // Contraseña para el empleado
  ) async {
    if (currentUser == null) throw Exception('Usuario no autenticado');
    
    // Create employee user
    final employeeUser = app_user.User(
      id: '', // Will be set after creation
      email: email,
      name: name,
      role: 'restaurant', // All employees are restaurant role
      phone: null,
      password: password, // Guardar contraseña en texto plano para desarrollo
      personalId: null, // Los empleados no necesitan cédula
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      profileImageUrl: null,
      preferences: {},
      addresses: [],
      paymentMethods: [],
      restaurantId: restaurantId,
      employeeRole: role,
      permissions: permissions,
      invitedBy: currentUser!.uid,
      hiredDate: DateTime.now(),
      isEmployee: true, // Los empleados invitados sí son empleados
    );

    // Create user document (employee will complete registration later)
    final docRef = await _firestore.collection('users').add(employeeUser.toMap());
    
    // Update the user with the correct ID
    await _firestore
        .collection('users')
        .doc(docRef.id)
        .update({'id': docRef.id});

    return docRef.id;
  }

  Future<List<app_user.User>> getRestaurantEmployees(String restaurantId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('employeeRole', isNull: false)
        .where('isActive', isEqualTo: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => app_user.User.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateEmployeePermissions(
    String employeeId,
    List<String> permissions,
  ) async {
    await _firestore
        .collection('users')
        .doc(employeeId)
        .update({
          'permissions': permissions,
          'updatedAt': DateTime.now(),
        });
  }

  Future<void> deactivateEmployee(String employeeId) async {
    await _firestore
        .collection('users')
        .doc(employeeId)
        .update({
          'isActive': false,
          'updatedAt': DateTime.now(),
        });
  }

  Future<void> activateEmployee(String employeeId) async {
    await _firestore
        .collection('users')
        .doc(employeeId)
        .update({
          'isActive': true,
          'updatedAt': DateTime.now(),
        });
  }

  // Employee Metrics
  Future<String> createEmployeeMetric(Map<String, dynamic> metricData) async {
    final docRef = await _firestore.collection('employee_metrics').add(metricData);
    return docRef.id;
  }

  Future<List<Map<String, dynamic>>> getEmployeeMetrics(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await _firestore
        .collection('employee_metrics')
        .where('employeeId', isEqualTo: employeeId)
        .where('periodStart', isGreaterThanOrEqualTo: startDate)
        .where('periodEnd', isLessThanOrEqualTo: endDate)
        .orderBy('periodStart', descending: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => doc.data())
        .toList();
  }

  Future<void> updateEmployeeMetric(
    String metricId,
    Map<String, dynamic> updates,
  ) async {
    updates['lastUpdated'] = DateTime.now();
    await _firestore
        .collection('employee_metrics')
        .doc(metricId)
        .update(updates);
  }

  // Table Management Methods
  Future<String> createTable(Map<String, dynamic> tableData) async {
    if (currentUser == null) throw Exception('Usuario no autenticado');
    
    final docRef = await _firestore.collection('tables').add(tableData);
    return docRef.id;
  }

  Future<List<Map<String, dynamic>>> getRestaurantTables(String restaurantId) async {
    final querySnapshot = await _firestore
        .collection('tables')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('tableName')
        .get();
    
    return querySnapshot.docs
        .map((doc) => doc.data())
        .toList();
  }

  Future<void> updateTable(String tableId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('tables')
        .doc(tableId)
        .update(updates);
  }

  Future<void> deleteTable(String tableId) async {
    await _firestore
        .collection('tables')
        .doc(tableId)
        .delete();
  }

  Future<Map<String, dynamic>?> getTableByJoinCode(String joinCode, String restaurantId) async {
    final querySnapshot = await _firestore
        .collection('tables')
        .where('joinCode', isEqualTo: joinCode)
        .where('restaurantId', isEqualTo: restaurantId)
        .limit(1)
          .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  Future<void> assignTableToUser(String tableId, String userId, String userName) async {
    await _firestore
        .collection('tables')
        .doc(tableId)
        .update({
          'status': 'ocupada',
          'currentUserId': userId,
          'currentUserName': userName,
        });
  }

  Future<void> freeTable(String tableId) async {
    await _firestore
        .collection('tables')
        .doc(tableId)
        .update({
          'status': 'disponible',
          'currentUserId': null,
          'currentUserName': null,
        });
  }
} 