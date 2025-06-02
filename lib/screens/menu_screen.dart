import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/screens/reservation_screen.dart';
import '../models/menu_item.dart';
import '../services/cart_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/menu_item_card.dart';
import '../utils/app_colors.dart';
import 'detail_screen.dart';
import 'cart_screen.dart';
import '../services/firebase_service.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

// Botón para ir a la pantalla de reservas
// Botón para ir a la pantalla de reservas
Widget buildReservationButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
    child: ElevatedButton.icon(
      icon: Icon(Icons.calendar_today, color: Colors.white),
      label: const Text(
        'Reservar Mesa',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => const ReservationScreen(
                  restauranteId: _MenuScreenState.restaurantId,
                ),
          ),
        );
      },
    ),
  );
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategory = 'Todos';
  static const String restaurantId =
      "id_cantina"; // Definir como constante para reutilizar

  @override
  void initState() {
    super.initState();
    // Verificar la existencia del restaurante al inicializar
    _checkRestaurantSetup();
    // Establecer el restaurante en el CartService
    _setupCartService();
  }

  Future<void> _checkRestaurantSetup() async {
    final exists = await FirebaseService.checkRestaurantExists(restaurantId);
    print('Resultado de verificación del restaurante: $exists');

    // Opcional: También debuggear la estructura
    // await FirebaseService.debugFirebaseStructure(restaurantId);
  }

  void _setupCartService() {
    // Establecer el restaurante actual en el CartService
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.setCurrentRestaurant(restaurantId);
    print('🏪 Restaurante establecido en CartService: $restaurantId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Restaurante App'),
      body: Column(
        children: [
          buildReservationButton(context),
          _buildCategorySelector(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuestro Menú',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(child: _buildMenuGrid()),
                ],
              ),
            ),
          ),
          _buildBottomCartButton(context),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder<List<String>>(
        stream: FirebaseService.getCategories(restaurantId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final categories = ['Todos', ...snapshot.data!];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category;

              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuGrid() {
    return StreamBuilder<List<MenuItem>>(
      stream:
          selectedCategory == 'Todos'
              ? FirebaseService.getMenuItems(restaurantId)
              : FirebaseService.getMenuItemsByCategory(
                restaurantId,
                selectedCategory,
              ),

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error al cargar el menú'),
                SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}', // Mostrar el error específico
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final menuItems = snapshot.data ?? [];

        if (menuItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay items disponibles'),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final menuItem = menuItems[index];
            return MenuItemCard(
              menuItem: menuItem,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(menuItem: menuItem),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomCartButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Consumer<CartService>(
        builder: (context, cartService, child) {
          return ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CartScreen(
                        restaurantId: restaurantId,
                      ), // Pasar el restaurantId
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart),
                SizedBox(width: 8),
                Text(
                  'Ver Carrito',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (cartService.totalItems > 0) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cartService.totalItems}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
