import 'dart:convert';

import 'package:eatyy/models/business_user.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class BusinessMenuPage extends StatefulWidget {
  final BusinessUser user;
  const BusinessMenuPage({super.key, required this.user});

  @override
  State<BusinessMenuPage> createState() => _BusinessMenuPageState();
}

class _BusinessMenuPageState extends State<BusinessMenuPage> {
  final _api = ApiService();
  List<dynamic> _products = [];
  bool _loading = true;
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() => _loading = true);
    final biz = await _api.getBusiness(widget.user.email);
    if (biz != null) {
      final products = await _api.getMenu(biz['id']);
      if (mounted) setState(() => _products = products);
    }
    if (mounted) setState(() => _loading = false);
  }

  // Sürükle bırak bitince sunucuya kaydet
  Future<void> _saveOrder() async {
    List<Map<String, dynamic>> updateList = [];
    for (int i = 0; i < _products.length; i++) {
      updateList.add({"id": _products[i]['id'], "sequence": i});
    }
    await _api.reorderProducts(updateList);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Sıralama güncellendi!")));
  }

  Future<void> _showProductDialog({Map<String, dynamic>? product}) async {
    final categories = _products
        .map((e) => e['category']?.toString() ?? '')
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList();
    categories.sort();

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ProductEditorPage(
          user: widget.user,
          product: product,
          categories: categories,
        ),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      _fetchMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          "Menü Yönetimi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          TextButton.icon(
            onPressed: () async {
              if (_isReorderMode) {
                await _saveOrder();
              }
              setState(() => _isReorderMode = !_isReorderMode);
            },
            icon: Icon(
              _isReorderMode ? Icons.check : Icons.sort,
              color: _isReorderMode ? Colors.green : Colors.deepOrange,
            ),
            label: Text(
              _isReorderMode ? "Bitti" : "Sırala",
              style: TextStyle(
                color: _isReorderMode ? Colors.green : Colors.deepOrange,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isReorderMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showProductDialog(),
              backgroundColor: const Color(0xFFFF7A18),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Ürün Ekle",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isReorderMode
          ? _buildReorderList()
          : _buildViewList(),
    );
  }

  Widget _buildReorderList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _products.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _products.removeAt(oldIndex);
          _products.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          color: Colors.white,
          key: ValueKey(product['id']),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.drag_handle, color: Colors.grey),
            title: Text(
              product['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(product['category']),
            trailing: Text("${product['price']} ₺"),
          ),
        );
      },
    );
  }

  Widget _buildViewList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        bool showHeader = false;
        if (index == 0) {
          showHeader = true;
        } else {
          final prevCat = _products[index - 1]['category'];
          if (prevCat != product['category']) {
            showHeader = true;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  product['category'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            _MenuCard(
              item: product,
              onEdit: () => _showProductDialog(product: product),
            ),
          ],
        );
      },
    );
  }
}

class _ProductEditorPage extends StatefulWidget {
  final BusinessUser user;
  final Map<String, dynamic>? product;
  final List<String> categories;

  const _ProductEditorPage({
    required this.user,
    required this.product,
    required this.categories,
  });

  @override
  State<_ProductEditorPage> createState() => _ProductEditorPageState();
}

class _ProductEditorPageState extends State<_ProductEditorPage> {
  final _api = ApiService();
  final _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _imgCtrl;
  late TextEditingController _customCatCtrl;

  late List<String> _categories;
  String? _imageValue;
  String? _selectedCategory;
  bool _useCustomCategory = false;
  bool _isAvailable = true;
  bool _saving = false;

  static const String _fallbackImage =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80';

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameCtrl = TextEditingController(text: product?['name']?.toString() ?? '');
    _descCtrl = TextEditingController(
      text: product?['description']?.toString() ?? '',
    );
    _priceCtrl = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    _imageValue = product?['image_url']?.toString();
    _imgCtrl = TextEditingController(
      text: (_imageValue != null && !_imageValue!.startsWith('data:image'))
          ? _imageValue!
          : '',
    );
    _customCatCtrl = TextEditingController();

    final categories = widget.categories
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    _categories = categories.isEmpty ? ['Genel'] : categories;

    final categoryValue = product?['category']?.toString();
    if (categoryValue != null &&
        categoryValue.trim().isNotEmpty &&
        !_categories.contains(categoryValue)) {
      _useCustomCategory = true;
      _customCatCtrl.text = categoryValue;
      _selectedCategory = _categories.first;
    } else {
      _selectedCategory =
          (categoryValue != null && categoryValue.trim().isNotEmpty)
          ? categoryValue
          : _categories.first;
    }

    _isAvailable = product?['is_available'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imgCtrl.dispose();
    _customCatCtrl.dispose();
    super.dispose();
  }

  String _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickImage() async {
    if (_saving) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);
      final mime = _guessMime(file.path);
      if (!mounted) return;
      setState(() {
        _imageValue = 'data:$mime;base64,$base64Data';
        _imgCtrl.text = '';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resim seçilemedi.')));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ürün adı gerekli.')));
      return;
    }

    String category;
    if (_useCustomCategory) {
      category = _customCatCtrl.text.trim();
      if (category.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kategori adı gerekli.')));
        return;
      }
    } else {
      category = _selectedCategory ?? 'Genel';
    }

    final priceText = _priceCtrl.text.trim();
    double price = 0;
    if (priceText.isNotEmpty) {
      final normalized = priceText.replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fiyat geçersiz.')));
        return;
      }
      price = parsed;
    }

    final imageUrl = (_imageValue ?? _imgCtrl.text).trim();

    final data = {
      'name': name,
      'description': _descCtrl.text.trim(),
      'price': price,
      'category': category,
      'image_url': imageUrl.isEmpty ? null : imageUrl,
      'is_available': _isAvailable,
    };

    setState(() => _saving = true);
    bool success = false;
    if (_isEditing) {
      success = await _api.updateProduct(widget.product!['id'], data);
    } else {
      success = await _api.addProduct(widget.user.email, data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kaydedilemedi.')));
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isEditing || _saving) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ürünü silmek istediğine emin misin?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    setState(() => _saving = true);
    final success = await _api.deleteProduct(widget.product!['id']);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silinemedi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Ürünü Düzenle' : 'Yeni ürün Ekle';
    final previewSource = (_imageValue != null && _imageValue!.isNotEmpty)
        ? _imageValue
        : _imgCtrl.text.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppImage(
                  source: previewSource,
                  fallback: _fallbackImage,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.restaurant_menu, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeriden Resim Seç'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _imgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Resim URL (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    setState(() => _imageValue = trimmed);
                  } else if (_imageValue == null ||
                      !_imageValue!.startsWith('data:image')) {
                    setState(() => _imageValue = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'ürün adı ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (!_useCustomCategory)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _useCustomCategory = !_useCustomCategory);
                  },
                  icon: Icon(_useCustomCategory ? Icons.list_alt : Icons.add),
                  label: Text(
                    _useCustomCategory
                        ? 'Listeden kategori seç'
                        : 'Yeni kategori ekle',
                  ),
                ),
              ),
              if (_useCustomCategory)
                TextField(
                  controller: _customCatCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('ürün aktif'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onEdit;
  const _MenuCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final bool available = item['is_available'] ?? true;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      AppImage(
                        source: item['image_url']?.toString(),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFFFF1E6),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Color(0xFFE85B2B),
                          ),
                        ),
                      ),
                      if (!available)
                        Positioned.fill(
                          child: Container(color: Colors.grey.withOpacity(0.5)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: TextStyle(
                          color: available ? Colors.black87 : Colors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          decoration: available
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['description'] ?? "",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "₺${item['price']}",
                        style: TextStyle(
                          color: available ? Colors.black87 : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: (available ? Colors.green : Colors.red).withOpacity(
                      0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    available ? 'Aktif' : 'Pasif',
                    style: TextStyle(
                      color: available ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
