class UserData {
  final String? id; // ID del usuario (Firebase UID)
  final String nombre;
  final String cedula;

  UserData({this.id, required this.nombre, required this.cedula});

  // Opcional: Método copyWith por si necesitas actualizar el objeto
  UserData copyWith({
    String? id,
    String? nombre,
    String? cedula,
  }) {
    return UserData(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      cedula: cedula ?? this.cedula,
    );
  }

  // Opcional: Métodos toMap y fromMap si necesitas serializar/deserializar UserData
  // Map<String, dynamic> toMap() {
  //   return {
  //     'id': id,
  //     'nombre': nombre,
  //     'cedula': cedula,
  //   };
  // }

  // static UserData fromMap(Map<String, dynamic> map) {
  //   return UserData(
  //     id: map['id'],
  //     nombre: map['nombre'] ?? '',
  //     cedula: map['cedula'] ?? '',
  //   );
  // }
}
