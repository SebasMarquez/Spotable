import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/menu_item.dart';
import '../services/firebase_service.dart';

// Enums para controlar el estado interno del diálogo
enum MenuView { list, add, edit }
enum ImageSourceType { local, url }

class MenuManagementDialog extends StatefulWidget {
  final String restaurantId;

  const MenuManagementDialog({Key? key, required this.restaurantId}) : super(key: key);

  @override
  State<MenuManagementDialog> createState() => _MenuManagementDialogState();
}

class _MenuManagementDialogState extends State<MenuManagementDialog> {
  MenuView _currentView = MenuView.list;
  MenuItem? _selectedMenuItem;

  void _changeView(MenuView view, {MenuItem? menuItem}) {
    setState(() {
      _currentView = view;
      _selectedMenuItem = menuItem;
    });
  }

  Widget _buildTitle() {
    switch (_currentView) {
      case MenuView.add:
        return const Text('Agregar Nuevo Plato');
      case MenuView.edit:
        return Text('Editar: ${_selectedMenuItem?.name ?? 'Plato'}');
      case MenuView.list:
      default:
        return const Text('Gestión de Menú');
    }
  }
  
  Widget _buildContent() {
    switch (_currentView) {
      case MenuView.add:
        return _AddMenuItemForm(
          restaurantId: widget.restaurantId,
          onSuccess: () => _changeView(MenuView.list),
        );
      case MenuView.edit:
        if (_selectedMenuItem != null) {
          return _EditMenuItemForm(
            restaurantId: widget.restaurantId,
            menuItem: _selectedMenuItem!,
            onSuccess: () => _changeView(MenuView.list),
          );
        }
        return const Center(child: Text("Error: No se seleccionó ningún plato."));
      case MenuView.list:
      default:
        return _MenuListView(
          restaurantId: widget.restaurantId,
          onAdd: () => _changeView(MenuView.add),
          onEdit: (item) => _changeView(MenuView.edit, menuItem: item),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  if (_currentView != MenuView.list)
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => _changeView(MenuView.list))
                  else
                    const SizedBox(width: 48),
                  
                  DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    child: _buildTitle(),
                  ),

                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS INTERNOS PARA CADA VISTA ---

// 1. VISTA DE LISTA DE PLATOS
class _MenuListView extends StatefulWidget {
  final String restaurantId;
  final VoidCallback onAdd;
  final Function(MenuItem) onEdit;

  const _MenuListView({required this.restaurantId, required this.onAdd, required this.onEdit});

  @override
  State<_MenuListView> createState() => _MenuListViewState();
}

class _MenuListViewState extends State<_MenuListView> {

  Future<void> _deleteMenuItem(MenuItem item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Seguro que quieres eliminar "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService.deleteMenuItem(restaurantId: widget.restaurantId, menuItemId: item.id!);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${item.name}" eliminado.'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildMenuItemCard(MenuItem item) {
    Widget imageWidget;
    if (item.image.startsWith('assets/')) {
      imageWidget = Image.asset(item.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.restaurant, color: Colors.grey));
    } else if (item.image.startsWith('http')) {
      imageWidget = Image.network(item.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.restaurant, color: Colors.grey));
    } else {
      imageWidget = const Icon(Icons.restaurant, color: Colors.grey);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 56, height: 56, child: imageWidget),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item.category.join(', ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => widget.onEdit(item)),
            IconButton(icon: Icon(Icons.delete, color: Colors.red[700]), onPressed: () => _deleteMenuItem(item)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN: Usamos un Stack para posicionar el botón flotante
    return Stack(
      children: [
        StreamBuilder<List<MenuItem>>(
          stream: FirebaseService.getAllMenuItems(widget.restaurantId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No hay platos en el menú.'));
            
            final items = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildMenuItemCard(items[index]),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: widget.onAdd,
            backgroundColor: Colors.red[600],
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}


// 2. VISTA DE FORMULARIO PARA AÑADIR
class _AddMenuItemForm extends StatefulWidget {
  final String restaurantId;
  final VoidCallback onSuccess;
  const _AddMenuItemForm({required this.restaurantId, required this.onSuccess});

  @override
  State<_AddMenuItemForm> createState() => _AddMenuItemFormState();
}

class _AddMenuItemFormState extends State<_AddMenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String? _selectedImageName;
  ImageSourceType _imageSource = ImageSourceType.local;
  final List<String> _availableCategories = const ['Carnes', 'Aves', 'Pastas', 'Arroces', 'Postres', 'Pizzas', 'Bebidas', 'Bebidas Alcoholicas', 'Ensaladas', 'Entradas/Aperitivos', 'Sopas', 'Sushi', 'Pescados'];
  final List<String> _selectedCategories = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImageName = File(result.files.single.path!).path.split(Platform.pathSeparator).last;
      });
    }
  }

  Future<void> _addMenuItem() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes seleccionar al menos una categoría.'), backgroundColor: Colors.orange));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      String imagePath = '';
      if (_imageSource == ImageSourceType.local) {
        if (_selectedImageName != null) imagePath = 'assets/images/${widget.restaurantId}/$_selectedImageName';
      } else {
        imagePath = _imageUrlController.text.trim();
      }

      final menuItemData = {
        'Nombre': _nameController.text.trim(),
        'Descripción': _descriptionController.text.trim(),
        'Precio': double.parse(_priceController.text.trim()),
        'Categoria': _selectedCategories,
        'Imagen': imagePath,
        'available': true,
      };

      await FirebaseService.saveMenuItem(restaurantId: widget.restaurantId, newMenuItemData: menuItemData);
      widget.onSuccess();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ImageSourceType>(
              segments: const [
                ButtonSegment(value: ImageSourceType.local, label: Text('Local'), icon: Icon(Icons.folder_open)),
                ButtonSegment(value: ImageSourceType.url, label: Text('URL Web'), icon: Icon(Icons.link)),
              ],
              selected: {_imageSource},
              onSelectionChanged: (s) => setState(() => _imageSource = s.first),
            ),
            const SizedBox(height: 16),
            if (_imageSource == ImageSourceType.local)
              OutlinedButton.icon(icon: const Icon(Icons.image_search), label: Text(_selectedImageName ?? 'Seleccionar Imagen Local'), onPressed: _pickImage)
            else
              TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'URL de la imagen', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty || !Uri.parse(v).isAbsolute) ? 'URL inválida' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre del plato *', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 16),
            TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Precio *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => (v == null || double.tryParse(v) == null) ? 'Precio inválido' : null),
            const SizedBox(height: 16),
            const Text('Categorías *', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: _availableCategories.map((c) => FilterChip(label: Text(c), selected: _selectedCategories.contains(c), onSelected: (s) => setState(() => s ? _selectedCategories.add(c) : _selectedCategories.remove(c)))).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _isLoading ? null : _addMenuItem, child: Text(_isLoading ? 'Guardando...' : 'Guardar Plato')),
          ],
        ),
      ),
    );
  }
}


// 3. VISTA DE FORMULARIO PARA EDITAR
class _EditMenuItemForm extends StatefulWidget {
  final String restaurantId;
  final MenuItem menuItem;
  final VoidCallback onSuccess;
  const _EditMenuItemForm({required this.restaurantId, required this.menuItem, required this.onSuccess});

  @override
  State<_EditMenuItemForm> createState() => _EditMenuItemFormState();
}

class _EditMenuItemFormState extends State<_EditMenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  String? _selectedImageName;
  late ImageSourceType _imageSource;
  late List<String> _selectedCategories;
  late bool _isAvailable;
  bool _isLoading = false;
  final List<String> _availableCategories = const ['Carnes', 'Aves', 'Pastas', 'Arroces', 'Postres', 'Pizzas', 'Bebidas', 'Bebidas Alcoholicas', 'Ensaladas', 'Entradas/Aperitivos', 'Sopas', 'Sushi', 'Pescados'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menuItem.name);
    _descriptionController = TextEditingController(text: widget.menuItem.description);
    _priceController = TextEditingController(text: widget.menuItem.price.toString());
    _isAvailable = widget.menuItem.available;
    _selectedCategories = List<String>.from(widget.menuItem.category);

    if (widget.menuItem.image.startsWith('assets/')) {
      _imageSource = ImageSourceType.local;
      _selectedImageName = widget.menuItem.image.split('/').last;
      _imageUrlController = TextEditingController();
    } else {
      _imageSource = ImageSourceType.url;
      _imageUrlController = TextEditingController(text: widget.menuItem.image);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) setState(() => _selectedImageName = File(result.files.single.path!).path.split(Platform.pathSeparator).last);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      String imagePath = '';
      if (_imageSource == ImageSourceType.local) {
        if (_selectedImageName != null) imagePath = 'assets/images/${widget.restaurantId}/$_selectedImageName';
      } else {
        imagePath = _imageUrlController.text.trim();
      }

      final updatedData = {
        'Nombre': _nameController.text.trim(),
        'Descripción': _descriptionController.text.trim(),
        'Precio': double.parse(_priceController.text.trim()),
        'Categoria': _selectedCategories,
        'Imagen': imagePath,
        'available': _isAvailable,
      };

      await FirebaseService.saveMenuItem(restaurantId: widget.restaurantId, menuItemId: widget.menuItem.id, newMenuItemData: updatedData);
      widget.onSuccess();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ImageSourceType>(
              segments: const [
                ButtonSegment(value: ImageSourceType.local, label: Text('Local'), icon: Icon(Icons.folder_open)),
                ButtonSegment(value: ImageSourceType.url, label: Text('URL Web'), icon: Icon(Icons.link)),
              ],
              selected: {_imageSource},
              onSelectionChanged: (s) => setState(() => _imageSource = s.first),
            ),
            const SizedBox(height: 16),
            if (_imageSource == ImageSourceType.local)
              OutlinedButton.icon(icon: const Icon(Icons.image_search), label: Text(_selectedImageName ?? 'Seleccionar Imagen Local'), onPressed: _pickImage)
            else
              TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'URL de la imagen', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty || !Uri.parse(v).isAbsolute) ? 'URL inválida' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre del plato *', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 16),
            TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Precio *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => (v == null || double.tryParse(v) == null) ? 'Precio inválido' : null),
            const SizedBox(height: 16),
            const Text('Categorías *', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: _availableCategories.map((c) => FilterChip(label: Text(c), selected: _selectedCategories.contains(c), onSelected: (s) => setState(() => s ? _selectedCategories.add(c) : _selectedCategories.remove(c)))).toList(),
            ),
            SwitchListTile(title: const Text('Disponible'), value: _isAvailable, onChanged: (v) => setState(() => _isAvailable = v)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _isLoading ? null : _saveChanges, child: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios')),
          ],
        ),
      ),
    );
  }
}
