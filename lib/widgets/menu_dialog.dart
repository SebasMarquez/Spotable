import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../services/cart_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/menu_item_card.dart'; // Reutilizamos la tarjeta que ya tienes

// Enum para controlar la vista interna del diálogo
enum MenuDialogView { list, detail }

class MenuDialog extends StatefulWidget {
  final String restaurantId;

  const MenuDialog({Key? key, required this.restaurantId}) : super(key: key);

  @override
  State<MenuDialog> createState() => _MenuDialogState();
}

class _MenuDialogState extends State<MenuDialog> {
  MenuDialogView _currentView = MenuDialogView.list;
  MenuItem? _selectedMenuItem;

  void _changeView(MenuDialogView view, {MenuItem? menuItem}) {
    setState(() {
      _currentView = view;
      _selectedMenuItem = menuItem;
    });
  }

  Widget _buildTitle() {
    switch (_currentView) {
      case MenuDialogView.detail:
        return Text(_selectedMenuItem?.name ?? 'Detalle del Plato', overflow: TextOverflow.ellipsis);
      case MenuDialogView.list:
      default:
        return const Text('Menú del Restaurante');
    }
  }

  Widget _buildContent() {
    switch (_currentView) {
      case MenuDialogView.detail:
        return _MenuItemDetailView(
          menuItem: _selectedMenuItem!,
          onAddToCart: (quantity) {
            final cart = context.read<CartService>();
            cart.addToCart(_selectedMenuItem!, quantity);
            // Opcional: mostrar un SnackBar de confirmación
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_selectedMenuItem!.name} añadido al carrito.'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      case MenuDialogView.list:
      default:
        return _MenuListView(
          restaurantId: widget.restaurantId,
          onMenuItemTap: (item) => _changeView(MenuDialogView.detail, menuItem: item),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentView != MenuDialogView.list)
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => _changeView(MenuDialogView.list))
                  else
                    const SizedBox(width: 48),
                  
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      child: _buildTitle(),
                    ),
                  ),

                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}

// --- VISTA DE LISTA DE MENÚ (Lógica de MenuScreen) ---
class _MenuListView extends StatefulWidget {
  final String restaurantId;
  final Function(MenuItem) onMenuItemTap;

  const _MenuListView({required this.restaurantId, required this.onMenuItemTap});

  @override
  State<_MenuListView> createState() => _MenuListViewState();
}

class _MenuListViewState extends State<_MenuListView> {
  String selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCategorySelector(),
        Expanded(
          child: StreamBuilder<List<MenuItem>>(
            stream: selectedCategory == 'Todos'
                ? FirebaseService.getMenuItems(widget.restaurantId)
                : FirebaseService.getMenuItemsByCategory(widget.restaurantId, selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No hay platos en esta categoría.'));
              
              final items = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => MenuItemCard(
                  menuItem: items[index],
                  onTap: () => widget.onMenuItemTap(items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 50,
      child: StreamBuilder<List<String>>(
        stream: FirebaseService.getCategories(widget.restaurantId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final categories = ['Todos', ...snapshot.data!];
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (_) => setState(() => selectedCategory = category),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: selectedCategory == category ? Colors.white : AppColors.textPrimary),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- VISTA DE DETALLE DEL PLATO (Lógica de DetailScreen) ---
class _MenuItemDetailView extends StatefulWidget {
  final MenuItem menuItem;
  final Function(int) onAddToCart;

  const _MenuItemDetailView({required this.menuItem, required this.onAddToCart});

  @override
  State<_MenuItemDetailView> createState() => _MenuItemDetailViewState();
}

class _MenuItemDetailViewState extends State<_MenuItemDetailView> {
  int quantity = 1;

  Widget _buildImageWidget() {
    if (widget.menuItem.image.startsWith('assets/')) {
      return Image.asset(widget.menuItem.image, fit: BoxFit.cover);
    } else if (widget.menuItem.image.startsWith('http')) {
      return Image.network(widget.menuItem.image, fit: BoxFit.cover);
    } else {
      return const Icon(Icons.restaurant, size: 80, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: _buildImageWidget(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.menuItem.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('\$${widget.menuItem.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(widget.menuItem.description, style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5)),
                const SizedBox(height: 16),
                if (widget.menuItem.category.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: widget.menuItem.category.map((cat) => Chip(label: Text(cat))).toList(),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() { if (quantity > 1) quantity--; })),
                    Text('$quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => quantity++)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => widget.onAddToCart(quantity),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Agregar al Carrito'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
