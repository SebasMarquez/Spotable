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
import '../widgets/orders_footer.dart';

class MenuScreen extends StatefulWidget {
  final String restaurantId;
  const MenuScreen({Key? key, required this.restaurantId}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    _checkRestaurantSetup();
    _setupCartService();
  }

  Future<void> _checkRestaurantSetup() async {
    final exists = await FirebaseService.checkRestaurantExists(
      widget.restaurantId,
    );
    print('Resultado de verificación del restaurante: $exists');
  }

  void _setupCartService() {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.setCurrentRestaurant(widget.restaurantId);
    print('🏪 Restaurante establecido en CartService: ${widget.restaurantId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurante App'),
        backgroundColor: Colors.white,
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
      ),
      body: Column(
        children: [
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
      bottomNavigationBar: const OrdersFooter(),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder<List<String>>(
        stream: FirebaseService.getCategories(widget.restaurantId),
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
              ? FirebaseService.getMenuItems(widget.restaurantId)
              : FirebaseService.getMenuItemsByCategory(
                widget.restaurantId,
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
            childAspectRatio: 0.71,
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
                      (context) =>
                          CartScreen(restaurantId: widget.restaurantId),
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

// Cambia la función buildReservationButton para aceptar restaurantId
