import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/enriched_restaurant_card.dart';
import '../widgets/category_carousel.dart';
import '../widgets/restaurant_options_dialog.dart'; // Importamos el nuevo diálogo
import 'user_profile_screen.dart';

class RestaurantListScreen extends StatefulWidget {
  // CORRECCIÓN: El constructor ya no necesita parámetros
  const RestaurantListScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  String? _selectedCategory;
  List<Restaurant>? _filteredRestaurants;
  bool _isLoadingFiltered = false;
  List<Restaurant>? _allRestaurantsData;
  final FirebaseService _firebaseService = FirebaseService();

  // Función para mostrar el diálogo de opciones del restaurante
  void _showRestaurantOptionsDialog(Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) => RestaurantOptionsDialog(restaurant: restaurant),
    );
  }

  void _onCategoryTap(String category) async {
    if (_selectedCategory == category) {
      setState(() {
        _selectedCategory = null;
        _filteredRestaurants = null;
      });
      return;
    }

    setState(() {
      _selectedCategory = category;
      _isLoadingFiltered = true;
      _filteredRestaurants = null;
    });

    final results = await _firebaseService.getRestaurantsByCategory(category);

    if (mounted) {
      setState(() {
        _filteredRestaurants = results;
        _isLoadingFiltered = false;
      });
    }
  }

  Future<void> _showLogoutDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Salida'),
        content: const Text('¿Estás seguro de que deseas cerrar la sesión?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          TextButton(
            onPressed: () {
              userProvider.clearUser();
              Navigator.of(context).pop(true);
            },
            child: const Text('Sí, Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${user?.nombre.split(' ').first ?? 'Usuario'} 👋', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
            const Text('¿Qué se te antoja hoy?', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
        actions: [
          // BOTÓN DE CARRITO / PEDIDOS
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black, size: 28),
            tooltip: 'Mis Pedidos',
            onPressed: () {
              Navigator.push(
                context,
                // Navega a la pantalla de perfil, abriendo directamente la pestaña de pedidos.
                MaterialPageRoute(builder: (context) => const UserProfileScreen(initialTabIndex: 0)),
              );
            },
          ),
          // BOTÓN DE PERFIL
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.black, size: 28),
            tooltip: 'Mi Perfil',
            onPressed: () {
              Navigator.push(
                context,
                // Navega a la pantalla de perfil, abriendo la pestaña de reservas.
                MaterialPageRoute(builder: (context) => const UserProfileScreen(initialTabIndex: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black, size: 28),
            tooltip: 'Cerrar Sesión',
            onPressed: _showLogoutDialog,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: _firebaseService.getRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _allRestaurantsData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los restaurantes.'));
          }
          if (snapshot.hasData) {
            _allRestaurantsData = snapshot.data!;
          }
          final allRestaurants = _allRestaurantsData ?? [];
          final recommendedRestaurants = allRestaurants.take(4).toList();
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Busca platos o restaurantes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("o busca por categoría", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              CategoryCarousel(onCategorySelected: _onCategoryTap, selectedCategory: _selectedCategory),
              _buildFilteredResults(),
              if (_selectedCategory == null) ...[
                const SizedBox(height: 24),
                _HorizontalRestaurantSection(title: 'Recomendados para ti ✨', restaurants: recommendedRestaurants, onRestaurantTap: _showRestaurantOptionsDialog),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                  child: Text('Todos los Restaurantes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.80),
                  itemCount: allRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = allRestaurants[index];
                    return GestureDetector(onTap: () => _showRestaurantOptionsDialog(restaurant), child: EnrichedRestaurantCard(restaurant: restaurant));
                  },
                ),
                const SizedBox(height: 20),
              ]
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilteredResults() {
    return AnimatedCrossFade(
      firstChild: Container(),
      secondChild: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultados para "$_selectedCategory"', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_isLoadingFiltered)
              const Center(child: CircularProgressIndicator())
            else if (_filteredRestaurants == null || _filteredRestaurants!.isEmpty)
              const Center(child: Text('Próximamente... 🧑‍🍳', style: TextStyle(fontSize: 16, color: Colors.grey)))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredRestaurants!.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final restaurant = _filteredRestaurants![index];
                  Widget imageWidget;
                  if (restaurant.imageUrl.startsWith('assets/')) {
                    imageWidget = Image.asset(restaurant.imageUrl, fit: BoxFit.cover);
                  } else if (restaurant.imageUrl.startsWith('http')) {
                    imageWidget = Image.network(restaurant.imageUrl, fit: BoxFit.cover);
                  } else {
                    imageWidget = const Icon(Icons.restaurant, color: Colors.grey);
                  }
                  return ListTile(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 56, height: 56, child: imageWidget)),
                    title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(restaurant.categories.join(', ')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showRestaurantOptionsDialog(restaurant),
                  );
                },
              )
          ],
        ),
      ),
      crossFadeState: _selectedCategory != null ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }
}

class _HorizontalRestaurantSection extends StatelessWidget {
  final String title;
  final List<Restaurant> restaurants;
  final Function(Restaurant) onRestaurantTap;
  const _HorizontalRestaurantSection({required this.title, required this.restaurants, required this.onRestaurantTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return SizedBox(
                width: 170,
                child: GestureDetector(onTap: () => onRestaurantTap(restaurant), child: EnrichedRestaurantCard(restaurant: restaurant)),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 16),
          ),
        ),
      ],
    );
  }
}
