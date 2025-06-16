import 'package:flutter/material.dart';

class Restaurant {
  final String name;
  final String description;
  final List<MenuItem> menu;

  Restaurant({
    required this.name,
    required this.description,
    required this.menu,
  });
}

class MenuItem {
  final String title;
  final String details;

  MenuItem({required this.title, required this.details});
}

final List<Restaurant> defaultRestaurants = [
  Restaurant(
    name: 'La Parrilla',
    description: 'Carnes y asados',
    menu: [
      MenuItem(title: 'Bife de chorizo', details: 'Jugoso y a la parrilla'),
      MenuItem(title: 'Pollo grillado', details: 'Con guarnición de papas'),
    ],
  ),
  Restaurant(
    name: 'Sushi House',
    description: 'Sushi y comida japonesa',
    menu: [
      MenuItem(title: 'Sushi roll', details: '8 piezas de salmón'),
      MenuItem(title: 'Tempura', details: 'Langostinos rebozados'),
    ],
  ),
  Restaurant(
    name: 'Pizzería Italia',
    description: 'Pizzas artesanales',
    menu: [
      MenuItem(
        title: 'Pizza Margarita',
        details: 'Tomate, mozzarella y albahaca',
      ),
      MenuItem(title: 'Pizza Pepperoni', details: 'Con extra pepperoni'),
    ],
  ),
];

class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({Key? key}) : super(key: key);

  void _openMenu(BuildContext context, Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
        backgroundColor: Colors.white,
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
      ),
      body: ListView.builder(
        itemCount: defaultRestaurants.length,
        itemBuilder: (context, index) {
          final restaurant = defaultRestaurants[index];
          return ListTile(
            title: Text(restaurant.name),
            subtitle: Text(restaurant.description),
            onTap: () => _openMenu(context, restaurant),
          );
        },
      ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  final Restaurant restaurant;

  const MenuScreen({Key? key, required this.restaurant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menú de ${restaurant.name}'),
        backgroundColor: Colors.white,
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
      ),
      body: ListView.builder(
        itemCount: restaurant.menu.length,
        itemBuilder: (context, index) {
          final item = restaurant.menu[index];
          return ListTile(
            title: Text(item.title),
            subtitle: Text(item.details),
          );
        },
      ),
    );
  }
}
