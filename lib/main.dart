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
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartService(),
      child: MaterialApp(
        title: 'Restaurante App',
        theme: ThemeData(
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: AppColors.background,
        ),
        debugShowCheckedModeBanner: false,
        home: _RootNavigator(),
      ),
    );
  }
}

class _RootNavigator extends StatefulWidget {
  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _screen = WelcomeScreen(
      onUserTap: () {
        setState(() {
          _screen = RestaurantListScreen(
            onRestaurantSelected: (Restaurant restaurant) {
              setState(() {
                // Aquí puedes pasar el restaurante seleccionado a MenuScreen si lo necesitas
                _screen = MenuScreen();
              });
            },
          );
        });
      },
      onRestaurantTap: () {
        setState(() {
          _screen = RestaurantLoginScreen(
            onLogin: (String id) async {
              final exists = await FirebaseService().restaurantExists(id);
              if (exists) {
                setState(() {
                  _screen = RestaurantScreen(restaurantId: id);
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
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _screen!;
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
//                      ),
//                      if (getTotalItems() > 0) ...[
//                        const SizedBox(width: 8),
//                        Container(
//                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                          decoration: BoxDecoration(
//                            color: Colors.red[800],
//                            borderRadius: BorderRadius.circular(12),
//                          ),
//                          child: Text(
//                            '${getTotalItems()}',
//                            style: const TextStyle(
//                              color: Colors.white,
//                              fontSize: 12,
//                              fontWeight: FontWeight.w600,
//                            ),
//                          ),
//                        ),
//                      ],
//                    ],
//                  ),
//                ),
//              ),
//            ),
//          ),
//        ],
//      ),
//    );
//  }
//
//  // Pantalla de detalle del plato
//  Widget _buildDetailScreen() {
//    if (selectedItem == null) return _buildMenuScreen();
//    
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('Detalle del Plato', style: TextStyle(color: Colors.white)),
//        backgroundColor: Colors.red[600],
//        leading: IconButton(
//          icon: const Icon(Icons.arrow_back, color: Colors.white),
//          onPressed: () {
//            setState(() {
//              currentScreen = 'menu';
//            });
//          },
//        ),
//      ),
//      body: Padding(
//        padding: const EdgeInsets.all(16.0),
//        child: Column(
//          children: [
//            Expanded(
//              child: Container(
//                width: double.infinity,
//                decoration: BoxDecoration(
//                  color: Colors.white,
//                  borderRadius: BorderRadius.circular(12),
//                  boxShadow: [
//                    BoxShadow(
//                      color: Colors.grey.withOpacity(0.2),
//                      spreadRadius: 1,
//                      blurRadius: 4,
//                      offset: const Offset(0, 2),
//                    ),
//                  ],
//                ),
//                padding: const EdgeInsets.all(24),
//                child: Column(
//                  mainAxisAlignment: MainAxisAlignment.center,
//                  children: [
//                    Text(
//                      selectedItem!.image,
//                      style: const TextStyle(fontSize: 80),
//                    ),
//                    const SizedBox(height: 16),
//                    Text(
//                      selectedItem!.name,
//                      style: const TextStyle(
//                        fontSize: 24,
//                        fontWeight: FontWeight.bold,
//                        color: Colors.black87,
//                      ),
//                      textAlign: TextAlign.center,
//                    ),
//                    const SizedBox(height: 8),
//                    Text(
//                      selectedItem!.description,
//                      style: const TextStyle(
//                        fontSize: 16,
//                        color: Colors.grey,
//                      ),
//                      textAlign: TextAlign.center,
//                    ),
//                    const SizedBox(height: 16),
//                    Text(
//                      '\$${selectedItem!.price.toStringAsFixed(2)}',
//                      style: TextStyle(
//                        fontSize: 28,
//                        fontWeight: FontWeight.bold,
//                        color: Colors.red[600],
//                      ),
//                    ),
//                    const SizedBox(height: 24),
//                    // Selector de cantidad
//                    Row(
//                      mainAxisAlignment: MainAxisAlignment.center,
//                      children: [
//                        IconButton(
//                          onPressed: () {
//                            setState(() {
//                              if (quantity > 1) quantity--;
//                            });
//                          },
//                          icon: const Icon(Icons.remove),
//                          style: IconButton.styleFrom(
//                            backgroundColor: Colors.grey[200],
//                            shape: const CircleBorder(),
//                          ),
//                        ),
//                        Padding(
//                          padding: const EdgeInsets.symmetric(horizontal: 16),
//                          child: Text(
//                            '$quantity',
//                            style: const TextStyle(
//                              fontSize: 20,
//                              fontWeight: FontWeight.w600,
//                            ),
//                          ),
//                        ),
//                        IconButton(
//                          onPressed: () {
//                            setState(() {
//                              quantity++;
//                            });
//                          },
//                          icon: const Icon(Icons.add),
//                          style: IconButton.styleFrom(
//                            backgroundColor: Colors.grey[200],
//                            shape: const CircleBorder(),
//                          ),
//                        ),
//                      ],
//                    ),
//                  ],
//                ),
//              ),
//            ),
//            const SizedBox(height: 16),
//            SizedBox(
//              width: double.infinity,
//              child: ElevatedButton(
//                onPressed: () {
//                  addToCart(selectedItem!, quantity);
//                },
//                style: ElevatedButton.styleFrom(
//                  backgroundColor: Colors.red[600],
//                  padding: const EdgeInsets.symmetric(vertical: 16),
//                  shape: RoundedRectangleBorder(
//                    borderRadius: BorderRadius.circular(12),
//                  ),
//                ),
//                child: Row(
//                  mainAxisAlignment: MainAxisAlignment.center,
//                  children: [
//                    const Icon(Icons.shopping_cart, color: Colors.white),
//                    const SizedBox(width: 8),
//                    Text(
//                      'Agregar al Carrito - \$${(selectedItem!.price * quantity).toStringAsFixed(2)}',
//                      style: const TextStyle(
//                        color: Colors.white,
//                        fontWeight: FontWeight.w600,
//                        fontSize: 16,
//                      ),
//                    ),
//                  ],
//                ),
//              ),
//            ),
//          ],
//        ),
//      ),
//    );
//  }
//
//  // Pantalla del carrito
//  Widget _buildCartScreen() {
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('Mi Carrito', style: TextStyle(color: Colors.white)),
//        backgroundColor: Colors.red[600],
//        leading: IconButton(
//          icon: const Icon(Icons.arrow_back, color: Colors.white),
//          onPressed: () {
//            setState(() {
//              currentScreen = 'menu';
//            });
//          },
//        ),
//      ),
//      body: cart.isEmpty
//          ? const Center(
//              child: Column(
//                mainAxisAlignment: MainAxisAlignment.center,
//                children: [
//                  Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
//                  SizedBox(height: 16),
//                  Text(
//                    'Tu carrito está vacío',
//                    style: TextStyle(fontSize: 18, color: Colors.grey),
//                  ),
//                ],
//              ),
//            )
//          : Column(
//              children: [
//                Expanded(
//                  child: ListView.builder(
//                    padding: const EdgeInsets.all(16),
//                    itemCount: cart.length,
//                    itemBuilder: (context, index) {
//                      final cartItem = cart[index];
//                      return Container(
//                        margin: const EdgeInsets.only(bottom: 16),
//                        decoration: BoxDecoration(
//                          color: Colors.white,
//                          borderRadius: BorderRadius.circular(12),
//                          boxShadow: [
//                            BoxShadow(
//                              color: Colors.grey.withOpacity(0.2),
//                              spreadRadius: 1,
//                              blurRadius: 4,
//                              offset: const Offset(0, 2),
//                            ),
//                          ],
//                        ),
//                        padding: const EdgeInsets.all(16),
//                        child: Row(
//                          children: [
//                            Text(
//                              cartItem.menuItem.image,
//                              style: const TextStyle(fontSize: 32),
//                            ),
//                            const SizedBox(width: 16),
//                            Expanded(
//                              child: Column(
//                                crossAxisAlignment: CrossAxisAlignment.start,
//                                children: [
//                                  Text(
//                                    cartItem.menuItem.name,
//                                    style: const TextStyle(
//                                      fontWeight: FontWeight.w600,
//                                      color: Colors.black87,
//                                    ),
//                                  ),
//                                  const SizedBox(height: 4),
//                                  Text(
//                                    'Cantidad: ${cartItem.quantity}',
//                                    style: const TextStyle(color: Colors.grey),
//                                  ),
//                                  const SizedBox(height: 4),
//                                  Text(
//                                    '\$${(cartItem.menuItem.price * cartItem.quantity).toStringAsFixed(2)}',
//                                    style: TextStyle(
//                                      color: Colors.red[600],
//                                      fontWeight: FontWeight.bold,
//                                    ),
//                                  ),
//                                ],
//                              ),
//                            ),
//                          ],
//                        ),
//                      );
//                    },
//                  ),
//                ),
//                Container(
//                  padding: const EdgeInsets.all(16),
//                  decoration: BoxDecoration(
//                    color: Colors.white,
//                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
//                  ),
//                  child: SafeArea(
//                    child: Column(
//                      children: [
//                        // Resumen del pedido
//                        Container(
//                          padding: const EdgeInsets.all(16),
//                          decoration: BoxDecoration(
//                            color: Colors.grey[50],
//                            borderRadius: BorderRadius.circular(12),
//                          ),
//                          child: Column(
//                            children: [
//                              const Text(
//                                'Resumen del Pedido',
//                                style: TextStyle(
//                                  fontSize: 18,
//                                  fontWeight: FontWeight.w600,
//                                ),
//                              ),
//                              const SizedBox(height: 8),
//                              Row(
//                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                children: [
//                                  const Text('Total de items:'),
//                                  Text('${getTotalItems()}'),
//                                ],
//                              ),
//                              const SizedBox(height: 8),
//                              Row(
//                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                children: [
//                                  const Text(
//                                    'Total:',
//                                    style: TextStyle(
//                                      fontSize: 20,
//                                      fontWeight: FontWeight.bold,
//                                    ),
//                                  ),
//                                  Text(
//                                    '\$${getTotalPrice().toStringAsFixed(2)}',
//                                    style: TextStyle(
//                                      fontSize: 20,
//                                      fontWeight: FontWeight.bold,
//                                      color: Colors.red[600],
//                                    ),
//                                  ),
//                                ],
//                              ),
//                            ],
//                          ),
//                        ),
//                        const SizedBox(height: 16),
//                        SizedBox(
//                          width: double.infinity,
//                          child: ElevatedButton(
//                            onPressed: placeOrder,
//                            style: ElevatedButton.styleFrom(
//                              backgroundColor: Colors.green[600],
//                              padding: const EdgeInsets.symmetric(vertical: 16),
//                              shape: RoundedRectangleBorder(
//                                borderRadius: BorderRadius.circular(12),
//                              ),
//                            ),
//                            child: const Row(
//                              mainAxisAlignment: MainAxisAlignment.center,
//                              children: [
//                                Icon(Icons.check, color: Colors.white),
//                                SizedBox(width: 8),
//                                Text(
//                                  'Realizar Pedido',
//                                  style: TextStyle(
//                                    color: Colors.white,
//                                    fontWeight: FontWeight.w600,
//                                    fontSize: 16,
//                                  ),
//                                ),
//                              ],
//                            ),
//                          ),
//                        ),
//                      ],
//                    ),
//                  ),
//                ),
//              ],
//            ),
//    );
//  }
//}