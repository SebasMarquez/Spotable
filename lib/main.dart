import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/welcome_screen.dart';
import 'screens/restaurant_screen.dart';
import 'utils/app_colors.dart';
import 'services/cart_service.dart';
import 'firebase_options.dart';
import 'screens/restaurant_list_screen.dart';
import 'providers/user_provider.dart';
import 'widgets/user_login_dialog.dart';
import 'widgets/restaurant_login_dialog.dart';

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
      title: 'Spotable',
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
  restaurant,
}

class _RootNavigator extends StatefulWidget {
  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  AppScreen _currentScreen = AppScreen.welcome;
  String? _selectedRestaurantId;
  UserProvider? _userProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    if (_userProvider != userProvider) {
      _userProvider?.removeListener(_onUserChanged);
      _userProvider = userProvider;
      _userProvider?.addListener(_onUserChanged);
      _onUserChanged();
    }
  }

  @override
  void dispose() {
    _userProvider?.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (!mounted) return;
    final user = _userProvider?.user;
    if (user != null) {
      if (_currentScreen == AppScreen.welcome) {
        setState(() {
          _currentScreen = AppScreen.restaurantList;
        });
      }
    } else {
      if (_currentScreen != AppScreen.welcome) {
        setState(() {
          _currentScreen = AppScreen.welcome;
          _selectedRestaurantId = null;
        });
      }
    }
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case AppScreen.welcome:
        return WelcomeScreen(
          onUserTap: () {
            showDialog(context: context, builder: (context) => const UserLoginDialog());
          },
          onRestaurantTap: () async {
            final String? restaurantId = await showDialog<String>(
              context: context,
              builder: (context) => const RestaurantLoginDialog(),
            );
            if (restaurantId != null && restaurantId.isNotEmpty) {
              setState(() {
                _currentScreen = AppScreen.restaurant;
                _selectedRestaurantId = restaurantId;
              });
            }
          },
        );
      case AppScreen.restaurantList:
        // CORRECCIÓN: Se elimina el parámetro onRestaurantSelected
        return const RestaurantListScreen();
      
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
}
