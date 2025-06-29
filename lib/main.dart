import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'package:intl/date_symbol_data_local.dart'; // Corrección de la ruta de importación
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
  await initializeDateFormatting('es_ES', null);
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
  UserProvider? _userProvider; // Added

  @override
  void didChangeDependencies() {
    // Changed from initState
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    if (_userProvider != userProvider) {
      _userProvider?.removeListener(_onUserChanged);
      _userProvider = userProvider;
      _userProvider?.addListener(_onUserChanged);
      // Initialize screen based on current user state
      _onUserChanged(); // Call it once to set initial screen
    }
  }

  @override
  void dispose() {
    _userProvider?.removeListener(_onUserChanged); // Added
    super.dispose();
  }

  void _onUserChanged() {
    // Added listener method
    final user = _userProvider?.user;
    if (mounted) {
      // Ensure the widget is still in the tree
      if (user != null) {
        // If user is logged in and we are on a public screen, navigate to the main authenticated screen.
        if (_currentScreen == AppScreen.welcome || _currentScreen == AppScreen.restaurantLogin) {
          setState(() {
            _currentScreen = AppScreen.restaurantList;
          });
        }
      } else { // User is null (logged out)
        // If user is logged out and we are on a private screen, navigate to the welcome screen.
        if (_currentScreen != AppScreen.welcome && _currentScreen != AppScreen.restaurantLogin) {
          setState(() {
            _currentScreen = AppScreen.welcome;
            _selectedRestaurantId = null; // Clear selected restaurant on logout
          });
        }
      }
    }
  }

  Widget _buildScreen() {
    // Potentially add a check here for userProvider.user and navigate
    // but _onUserChanged should handle it.

    switch (_currentScreen) {
      case AppScreen.welcome:
        return WelcomeScreen(
          onUserTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserIdentificationScreen()),
          ),
          onRestaurantTap: () {
            setState(() {
              _currentScreen = AppScreen.restaurantLogin;
            });
          },
        );
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
        return RestaurantScreen(
          restaurantId: _selectedRestaurantId!,
          onLogout: () {
            setState(() {
              _currentScreen = AppScreen.welcome;
              _selectedRestaurantId = null;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildScreen();
  }

  @override
  void initState() {
    super.initState();
    // showWelcomeScreen(); // Commented out, didChangeDependencies will handle initial setup
    // Initial listener setup will be in didChangeDependencies
  }
  }
