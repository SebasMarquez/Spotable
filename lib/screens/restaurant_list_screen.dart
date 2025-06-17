import 'package:flutter/material.dart';
import 'package:restaurant_app/screens/restaurant_screen.dart';
import '../services/firebase_service.dart';
import '../models/restaurant.dart';
import '../screens/select_option.dart';
import '../screens/welcome_screen.dart';
import '../screens/restaurant_login_screen.dart';
import '../widgets/orders_footer.dart';

class RestaurantListScreen extends StatelessWidget {
  final Function(Restaurant)? onRestaurantSelected;

  const RestaurantListScreen({Key? key, this.onRestaurantSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un restaurante'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navegar de vuelta a WelcomeScreen con los callbacks correctos
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder:
                    (context) => WelcomeScreen(
                      onUserTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RestaurantListScreen(),
                          ),
                        );
                      },
                      onRestaurantTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => RestaurantLoginScreen(
                                  onLogin: (String restaurantId) {
                                    // Manejar el login exitoso del restaurante
                                    _handleRestaurantLogin(
                                      context,
                                      restaurantId,
                                    );
                                  },
                                ),
                          ),
                        );
                      },
                    ),
              ),
              (route) => false,
            );
          },
        ),
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: FirebaseService().getRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay restaurantes disponibles.'),
            );
          }
          final restaurants = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                SelectOptionScreen(restaurant: restaurant),
                      ),
                    );
                  },
                  child: RestaurantCard(restaurant: restaurant),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const OrdersFooter(),
    );
  }

  // Método separado para manejar el login del restaurante
  void _handleRestaurantLogin(BuildContext context, String restaurantId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login exitoso para restaurante ID: $restaurantId'),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantScreen(restaurantId: restaurantId),
      ),
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({Key? key, required this.restaurant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            restaurant.imageUrl.isNotEmpty
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    restaurant.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.restaurant, size: 60),
                  ),
                )
                : const Icon(Icons.restaurant, size: 60),
            const SizedBox(height: 12),
            Text(
              restaurant.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFFB71C1C),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
