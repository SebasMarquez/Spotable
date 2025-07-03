class RestaurantTable {
  final String id;
  final String restaurantId;
  final String tableName;
  final String joinCode; // Código de 6 dígitos para unirse a la mesa
  final int capacity; // Número de personas que caben
  final String status; // 'disponible', 'ocupada', 'reservada'
  final String? currentUserName;
  final String? currentUserId;

  RestaurantTable({
    required this.id,
    required this.restaurantId,
    required this.tableName,
    required this.joinCode,
    required this.capacity,
    required this.status,
    this.currentUserName,
    this.currentUserId,
  });

  factory RestaurantTable.fromMap(Map<String, dynamic> data, String id) {
    return RestaurantTable(
      id: id,
      restaurantId: data['restaurantId'] ?? '',
      tableName: data['tableName'] ?? '',
      joinCode: data['joinCode'] ?? '',
      capacity: data['capacity'] ?? 4,
      status: data['status'] ?? 'disponible',
      currentUserName: data['currentUserName'],
      currentUserId: data['currentUserId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'tableName': tableName,
      'joinCode': joinCode,
      'capacity': capacity,
      'status': status,
      'currentUserName': currentUserName,
      'currentUserId': currentUserId,
    };
  }

  // Método para generar un código de unión aleatorio de 6 dígitos
  static String generateJoinCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return random.toString();
  }

  // Método para verificar si la mesa está disponible
  bool get isAvailable => status == 'disponible';
  
  // Método para verificar si la mesa está ocupada
  bool get isOccupied => status == 'ocupada';
  
  // Método para verificar si la mesa está reservada
  bool get isReserved => status == 'reservada';
} 