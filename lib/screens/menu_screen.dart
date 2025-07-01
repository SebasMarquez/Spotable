import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../services/cart_service.dart';
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
    // La llamada a _checkRestaurantSetup() ha sido eliminada.
    _setupCartService();
  }

  void _setupCartService() {
    // Esta función establece el restaurante actual en el servicio del carrito
    // para que sepa de dónde se están añadiendo los productos.
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.setCurrentRestaurant(widget.restaurantId);
    print('🏪 Restaurante establecido en CartService: ${widget.restaurantId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú del Restaurante'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Navigator.of(context).canPop()
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCategory == 'Todos' ? 'Nuestro Menú' : 'Categoría: $selectedCategory',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildMenuGrid()),
                ],
              ),
            ),
          ),
          // El botón del carrito se muestra solo si hay items
          Consumer<CartService>(
            builder: (context, cart, child) {
              if (cart.totalItems > 0) {
                return _buildBottomCartButton(context);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      // El pie de página de órdenes se mantiene
      bottomNavigationBar: const OrdersFooter(),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder<List<String>>(
        stream: FirebaseService.getCategories(widget.restaurantId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay categorías"));
          }

          final categories = ['Todos', ...snapshot.data!];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      stream: selectedCategory == 'Todos'
          ? FirebaseService.getMenuItems(widget.restaurantId)
          : FirebaseService.getMenuItemsByCategory(
              widget.restaurantId,
              selectedCategory,
            ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar el menú: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final menuItems = snapshot.data ?? [];

        if (menuItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay items disponibles en esta categoría'),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      padding: const EdgeInsets.all(16),
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
                  builder: (context) =>
                      CartScreen(restaurantId: widget.restaurantId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cartService.totalItems} items en el carrito',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Total: \$${cartService.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
