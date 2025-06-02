import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'services/cart_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
        home: MenuScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

