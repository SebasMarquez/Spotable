import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/restaurant_screen.dart';
import 'utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'services/cart_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/restaurant_list_screen.dart';
import 'models/restaurant.dart';
import 'screens/restaurant_login_screen.dart';
import 'screens/menu_mngmt_screen.dart';
import 'services/firebase_service.dart';
import 'screens/user_identification_screen.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: AppColors.background,
      ),
      debugShowCheckedModeBanner: false,
      home: _RootNavigator(),
    );
  }
}

enum AppScreen {
  welcome,
  userIdentification,
  restaurantList,
  menu,
  restaurantLogin,
  restaurant,
}

class _RootNavigator extends StatefulWidget {
  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  AppScreen _currentScreen = AppScreen.welcome;
  String? _selectedRestaurantId;

  void showWelcomeScreen() {
    setState(() {
      _currentScreen = AppScreen.welcome;
      _selectedRestaurantId = null;
    });
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case AppScreen.welcome:
        return WelcomeScreen(
          onUserTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserIdentificationScreen(),
              ),
            );
            if (result != null &&
                result is Map &&
                result['nombre'] != null &&
                result['cedula'] != null) {
              setState(() {
                _currentScreen = AppScreen.restaurantList;
              });
            }
          },
          onRestaurantTap: () {
            setState(() {
              _currentScreen = AppScreen.restaurantLogin;
            });
          },
        );
      case AppScreen.userIdentification:
        return const SizedBox.shrink();
      case AppScreen.restaurantList:
        return RestaurantListScreen(
          onRestaurantSelected: (Restaurant restaurant) {
            setState(() {
              _selectedRestaurantId = restaurant.id;
              _currentScreen = AppScreen.menu;
            });
          },
        );
      case AppScreen.menu:
        return MenuScreen(restaurantId: _selectedRestaurantId!);
      case AppScreen.restaurantLogin:
        return RestaurantLoginScreen(
          onLogin: (String id) async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => const Center(child: CircularProgressIndicator()),
            );
            final exists = await FirebaseService().restaurantExists(id);
            Navigator.of(context).pop(); // Cierra el loader
            if (exists) {
              setState(() {
                _currentScreen = AppScreen.restaurant;
                _selectedRestaurantId = id;
              });
            } else {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('ID incorrecto'),
                      content: const Text(
                        'No existe un restaurante con ese ID.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            }
          },
        );
      case AppScreen.restaurant:
        return RestaurantScreen(restaurantId: _selectedRestaurantId!);
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildScreen();
  }

  @override
  void initState() {
    super.initState();
    showWelcomeScreen();
  }
}

// Modelo de datos para los platos del menú
//class MenuItem {
//  final int id;
//  final String name;
//  final double price;
//  final String image;
//  final String description;
//  final String category;
//
//  MenuItem({
//    required this.id,
//    required this.name,
//    required this.price,
//    required this.image,
//    required this.description,
//    required this.category,
//  });
//}
//
//// Modelo para items del carrito
//class CartItem {
//  final MenuItem menuItem;
//  int quantity;
//
//  CartItem({required this.menuItem, required this.quantity});
//}
//
//class RestaurantApp extends StatefulWidget {
//  const RestaurantApp({super.key});
//
//  @override
//  State<RestaurantApp> createState() => _RestaurantAppState();
//}
//
//class _RestaurantAppState extends State<RestaurantApp> {
//  String currentScreen = 'menu';
//  MenuItem? selectedItem;
//  List<CartItem> cart = [];
//  int quantity = 1;
//
//  // Datos de ejemplo de platos
//  final List<MenuItem> menuItems = [
//    MenuItem(
//      id: 1,
//      name: "Hamburguesa Clásica",
//      price: 12.99,
//      image: "🍔",
//      description: "Jugosa hamburguesa con carne 100% res, lechuga, tomate, cebolla y nuestra salsa especial",
//      category: "Hamburguesas",
//    ),
//    MenuItem(
//      id: 2,
//      name: "Pizza Margherita",
//      price: 15.50,
//      image: "🍕",
//      description: "Pizza tradicional con salsa de tomate, mozzarella fresca y albahaca",
//      category: "Pizzas",
//    ),
//    MenuItem(
//      id: 3,
//      name: "Tacos al Pastor",
//      price: 8.99,
//      image: "🌮",
//      description: "3 tacos con carne al pastor, piña, cebolla y cilantro",
//      category: "Mexicana",
//    ),
//    MenuItem(
//      id: 4,
//      name: "Sushi Roll",
//      price: 18.75,
//      image: "🍣",
//      description: "8 piezas de sushi roll con salmón, aguacate y pepino",
//      category: "Japonesa",
//    ),
//    MenuItem(
//      id: 5,
//      name: "Pasta Carbonara",
//      price: 13.25,
//      image: "🍝",
//      description: "Pasta con salsa carbonara, tocino y queso parmesano",
//      category: "Italiana",
//    ),
//    MenuItem(
//      id: 6,
//      name: "Ensalada César",
//      price: 9.99,
//      image: "🥗",
//      description: "Lechuga romana, crutones, queso parmesano y aderezo césar",
//      category: "Ensaladas",
//    ),
//  ];
//
//  // Funciones del carrito
//  void addToCart(MenuItem item, int qty) {
//    setState(() {
//      final existingItemIndex = cart.indexWhere((cartItem) => cartItem.menuItem.id == item.id);
//      
//      if (existingItemIndex != -1) {
//        cart[existingItemIndex].quantity += qty;
//      } else {
//        cart.add(CartItem(menuItem: item, quantity: qty));
//      }
//      
//      currentScreen = 'menu';
//      quantity = 1;
//    });
//  }
//
//  int getTotalItems() {
//    return cart.fold(0, (total, item) => total + item.quantity);
//  }
//
//  double getTotalPrice() {
//    return cart.fold(0.0, (total, item) => total + (item.menuItem.price * item.quantity));
//  }
//
//  void placeOrder() {
//    // Simular creación de orden
//    print('Orden creada: ${cart.length} items, Total: \$${getTotalPrice().toStringAsFixed(2)}');
//    
//    setState(() {
//      cart.clear();
//      currentScreen = 'menu';
//    });
//    
//    ScaffoldMessenger.of(context).showSnackBar(
//      const SnackBar(
//        content: Text('¡Orden realizada con éxito!'),
//        backgroundColor: Colors.green,
//      ),
//    );
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      body: _buildCurrentScreen(),
//    );
//  }
//
//  Widget _buildCurrentScreen() {
//    switch (currentScreen) {
//      case 'menu':
//        return _buildMenuScreen();
//      case 'detail':
//        return _buildDetailScreen();
//      case 'cart':
//        return _buildCartScreen();
//      default:
//        return _buildMenuScreen();
//    }
//  }
//
//  // Pantalla del menú
//  Widget _buildMenuScreen() {
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('Restaurante App', style: TextStyle(color: Colors.white)),
//        backgroundColor: Colors.red[600],
//        centerTitle: true,
//      ),
//      body: Column(
//        children: [
//          Expanded(
//            child: Padding(
//              padding: const EdgeInsets.all(16.0),
//              child: Column(
//                crossAxisAlignment: CrossAxisAlignment.start,
//                children: [
//                  const Text(
//                    'Nuestro Menú',
//                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
//                  ),
//                  const SizedBox(height: 16),
//                  Expanded(
//                    child: GridView.builder(
//                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                        crossAxisCount: 2,
//                        crossAxisSpacing: 16,
//                        mainAxisSpacing: 16,
//                        childAspectRatio: 0.8,
//                      ),
//                      itemCount: menuItems.length,
//                      itemBuilder: (context, index) {
//                        final item = menuItems[index];
//                        return GestureDetector(
//                          onTap: () {
//                            setState(() {
//                              selectedItem = item;
//                              currentScreen = 'detail';
//                            });
//                          },
//                          child: Container(
//                            decoration: BoxDecoration(
//                              color: Colors.white,
//                              borderRadius: BorderRadius.circular(12),
//                              boxShadow: [
//                                BoxShadow(
//                                  color: Colors.grey.withOpacity(0.2),
//                                  spreadRadius: 1,
//                                  blurRadius: 4,
//                                  offset: const Offset(0, 2),
//                                ),
//                              ],
//                            ),
//                            padding: const EdgeInsets.all(16),
//                            child: Column(
//                              mainAxisAlignment: MainAxisAlignment.center,
//                              children: [
//                                Text(
//                                  item.image,
//                                  style: const TextStyle(fontSize: 40),
//                                ),
//                                const SizedBox(height: 8),
//                                Text(
//                                  item.name,
//                                  style: const TextStyle(
//                                    fontWeight: FontWeight.w600,
//                                    fontSize: 14,
//                                    color: Colors.black87,
//                                  ),
//                                  textAlign: TextAlign.center,
//                                  maxLines: 2,
//                                  overflow: TextOverflow.ellipsis,
//                                ),
//                                const SizedBox(height: 4),
//                                Text(
//                                  '\$${item.price.toStringAsFixed(2)}',
//                                  style: TextStyle(
//                                    color: Colors.red[600],
//                                    fontWeight: FontWeight.bold,
//                                    fontSize: 14,
//                                  ),
//                                ),
//                                const SizedBox(height: 4),
//                                Text(
//                                  item.category,
//                                  style: const TextStyle(
//                                    fontSize: 12,
//                                    color: Colors.grey,
//                                  ),
//                                ),
//                              ],
//                            ),
//                          ),
//                        );
//                      },
//                    ),
//                  ),
//                ],
//              ),
//            ),
//          ),
//          Container(
//            padding: const EdgeInsets.all(16),
//            decoration: BoxDecoration(
//              color: Colors.white,
//              border: Border(top: BorderSide(color: Colors.grey.shade300)),
//            ),
//            child: SafeArea(
//              child: SizedBox(
//                width: double.infinity,
//                child: ElevatedButton(
//                  onPressed: () {
//                    setState(() {
//                      currentScreen = 'cart';
//                    });
//                  },
//                  style: ElevatedButton.styleFrom(
//                    backgroundColor: Colors.red[600],
//                    padding: const EdgeInsets.symmetric(vertical: 16),
//                    shape: RoundedRectangleBorder(
//                      borderRadius: BorderRadius.circular(12),
//                    ),
//                  ),
//                  child: Row(
//                    mainAxisAlignment: MainAxisAlignment.center,
//                    children: [
//                      const Icon(Icons.shopping_cart, color: Colors.white),
//                      const SizedBox(width: 8),
//                      const Text(
//                        'Ver Carrito',
//                        style: TextStyle(
//                          color: Colors.white,
//                          fontWeight: FontWeight.w600,
//                          fontSize: 16,
//                        ),