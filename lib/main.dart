import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/restaurant_dashboard_screen.dart';
import 'screens/client_dashboard_screen.dart';
import 'utils/app_colors.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[DEBUG] Firebase inicializado correctamente');
  } on PlatformException catch (e) {
    print('[ERROR] PlatformException durante inicialización de Firebase: ${e.code} - ${e.message}');
    print('[ERROR] Detalles: ${e.details}');
    
    // Si es un error de configuración, mostrar información útil
    if (e.code == 'firebase_core/no-options') {
      print('[ERROR] No se encontraron opciones de Firebase para esta plataforma');
    } else if (e.code == 'firebase_core/initialization-error') {
      print('[ERROR] Error durante la inicialización de Firebase');
    }
    
    // Continuar con la app pero mostrar un mensaje de error
    print('[WARNING] Continuando sin Firebase inicializado');
  } catch (e) {
    print('[ERROR] Error inesperado durante inicialización de Firebase: $e');
    print('[WARNING] Continuando sin Firebase inicializado');
  }
  
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/restaurant-dashboard': (context) => const RestaurantDashboardScreen(),
        '/client-dashboard': (context) => const ClientDashboardScreen(),
      },
    );
  }
}
