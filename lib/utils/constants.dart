import '../models/menu_item.dart';

class AppConstants {
  static const String appName = 'Restaurant App';
  static final List<MenuItem> menuItems = [
    MenuItem(
      id: 1,
      name: "Hamburguesa Clásica",
      price: 12.99,
      image: "🍔",
      description: "Jugosa hamburguesa con carne 100% res, lechuga, tomate, cebolla y nuestra salsa especial",
      category: "Hamburguesas",
    ),
    MenuItem(
      id: 2,
      name: "Pizza Margherita",
      price: 15.50,
      image: "🍕",
      description: "Pizza tradicional con salsa de tomate, mozzarella fresca y albahaca",
      category: "Pizzas",
    ),
    MenuItem(
      id: 3,
      name: "Tacos al Pastor",
      price: 8.99,
      image: "🌮",
      description: "3 tacos con carne al pastor, piña, cebolla y cilantro",
      category: "Mexicana",
    ),
    MenuItem(
      id: 4,
      name: "Sushi Roll",
      price: 18.75,
      image: "🍣",
      description: "8 piezas de sushi roll con salmón, aguacate y pepino",
      category: "Japonesa",
    ),
    MenuItem(
      id: 5,
      name: "Pasta Carbonara",
      price: 13.25,
      image: "🍝",
      description: "Pasta con salsa carbonara, tocino y queso parmesano",
      category: "Italiana",
    ),
    MenuItem(
      id: 6,
      name: "Ensalada César",
      price: 9.99,
      image: "🥗",
      description: "Lechuga romana, crutones, queso parmesano y aderezo césar",
      category: "Ensaladas",
    ),
  ];
}