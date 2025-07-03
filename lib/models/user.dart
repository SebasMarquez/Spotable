import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'client', 'restaurant', 'employee'
  final String? phone;
  final String? password; // Contraseña en texto plano para desarrollo
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? profileImageUrl;
  final Map<String, dynamic> preferences;
  final List<Map<String, dynamic>> addresses;
  final List<Map<String, dynamic>> paymentMethods;

  // For restaurant owners (role == 'restaurant')
  final String? restaurantId;

  // For employees (role == 'employee')
  final String? employeeRole;     // 'waiter', 'cook', 'manager', etc.
  final List<String>? permissions; // Employee permissions
  final String? invitedBy;        // Who invited this employee
  final DateTime? hiredDate;      // When employee was hired
  final String? worksAtRestaurantId; // Restaurant where employee works

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.password,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.profileImageUrl,
    required this.preferences,
    required this.addresses,
    required this.paymentMethods,
    this.restaurantId,
    this.employeeRole,
    this.permissions,
    this.invitedBy,
    this.hiredDate,
    this.worksAtRestaurantId,
  });

  factory User.fromMap(Map<String, dynamic> data, [String? id]) {
    return User(
      id: id ?? data['id'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'client',
      phone: data['phone'],
      password: data['password'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      profileImageUrl: data['profileImageUrl'],
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      addresses: List<Map<String, dynamic>>.from(data['addresses'] ?? []),
      paymentMethods: List<Map<String, dynamic>>.from(data['paymentMethods'] ?? []),
      restaurantId: data['restaurantId'],
      employeeRole: data['employeeRole'],
      permissions: data['permissions'] != null ? List<String>.from(data['permissions']) : null,
      invitedBy: data['invitedBy'],
      hiredDate: data['hiredDate'] != null 
          ? (data['hiredDate'] as Timestamp).toDate()
          : null,
      worksAtRestaurantId: data['worksAtRestaurantId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'password': password,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'preferences': preferences,
      'addresses': addresses,
      'paymentMethods': paymentMethods,
      'restaurantId': restaurantId,
      'employeeRole': employeeRole,
      'permissions': permissions,
      'invitedBy': invitedBy,
      'hiredDate': hiredDate != null ? Timestamp.fromDate(hiredDate!) : null,
      'worksAtRestaurantId': worksAtRestaurantId,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
    List<Map<String, dynamic>>? addresses,
    List<Map<String, dynamic>>? paymentMethods,
    String? restaurantId,
    String? employeeRole,
    List<String>? permissions,
    String? invitedBy,
    DateTime? hiredDate,
    String? worksAtRestaurantId,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferences: preferences ?? this.preferences,
      addresses: addresses ?? this.addresses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      restaurantId: restaurantId ?? this.restaurantId,
      employeeRole: employeeRole ?? this.employeeRole,
      permissions: permissions ?? this.permissions,
      invitedBy: invitedBy ?? this.invitedBy,
      hiredDate: hiredDate ?? this.hiredDate,
      worksAtRestaurantId: worksAtRestaurantId ?? this.worksAtRestaurantId,
    );
  }

  // Métodos de utilidad para verificar roles
  bool get isClient => role == 'client';
  bool get isRestaurantOwner => role == 'restaurant';
  // El campo isEmployee se maneja directamente desde Firestore
  bool get isEmployee => false; // Se maneja directamente desde Firestore
  bool get isManager => isEmployee && employeeRole == 'manager';
  bool get isWaiter => isEmployee && employeeRole == 'waiter';
  bool get isCook => isEmployee && employeeRole == 'cook';
  bool get isCashier => isEmployee && employeeRole == 'cashier';
  bool get isHost => isEmployee && employeeRole == 'host';

  // Métodos de utilidad para permisos
  bool hasPermission(String permission) {
    return permissions?.contains(permission) == true || permissions?.contains('all') == true;
  }

  bool canManageOrders() {
    return isRestaurantOwner || 
           isManager || 
           hasPermission('manage_orders');
  }

  bool canManageTables() {
    return isRestaurantOwner || 
           isManager || 
           isWaiter || 
           isHost || 
           hasPermission('manage_tables');
  }

  bool canManageMenu() {
    return isRestaurantOwner || 
           isManager || 
           hasPermission('manage_menu');
  }

  bool canViewReports() {
    return isRestaurantOwner || 
           isManager || 
           hasPermission('view_reports');
  }

  bool canManageEmployees() {
    return isRestaurantOwner || 
           isManager || 
           hasPermission('manage_employees');
  }
} 