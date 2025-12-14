import 'package:eatyy/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class BusinessMenuPage extends StatefulWidget {
  final GoogleSignInAccount user;
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
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?['name']);
    final descCtrl = TextEditingController(text: product?['description']);
    final priceCtrl = TextEditingController(
      text: product?['price']?.toString(),
    );
    final imgCtrl = TextEditingController(
      text:
          product?['image_url'] ??
          "https://images.unsplash.com/photo-1546069901-ba9599a7e63c",
    );

    final existingCats = _products
        .map((e) => e['category'].toString())
        .toSet()
        .toList();
    if (!existingCats.contains("Genel")) existingCats.add("Genel");

    String selectedCategory = product?['category'] ?? existingCats.first;
    final customCatCtrl = TextEditingController();
    bool isCustomCategory = false;
    bool isAvailable = product?['is_available'] ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(isEditing ? "Ürünü Düzenle" : "Yeni Ürün Ekle"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(imgCtrl.text),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imgCtrl,
                    decoration: const InputDecoration(
                      labelText: "Resim URL",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setStateSB(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Ürün Adı",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: "Açıklama",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isCustomCategory)
                    DropdownButtonFormField<String>(
                      value: existingCats.contains(selectedCategory)
                          ? selectedCategory
                          : null,
                      decoration: const InputDecoration(
                        labelText: "Kategori",
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        ...existingCats.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                        const DropdownMenuItem(
                          value: "NEW",
                          child: Text(
                            "+ Yeni Kategori",
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                        ),
                      ],
                      onChanged: (val) => val == "NEW"
                          ? setStateSB(() => isCustomCategory = true)
                          : setStateSB(() => selectedCategory = val!),
                    ),
                  if (isCustomCategory)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customCatCtrl,
                            decoration: const InputDecoration(
                              labelText: "Kategori Adı",
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setStateSB(() => isCustomCategory = false),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Fiyat"),
                        ),
                      ),
                      Switch(
                        value: isAvailable,
                        activeColor: Colors.deepOrange,
                        onChanged: (v) => setStateSB(() => isAvailable = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: () async {
                    await _api.deleteProduct(product['id']);
                    Navigator.pop(ctx);
                    _fetchMenu();
                  },
                  child: const Text("Sil", style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  final cat = isCustomCategory
                      ? customCatCtrl.text
                      : selectedCategory;
                  final data = {
                    "name": nameCtrl.text,
                    "description": descCtrl.text,
                    "price": double.tryParse(priceCtrl.text) ?? 0,
                    "category": cat,
                    "image_url": imgCtrl.text,
                    "is_available": isAvailable,
                  };
                  isEditing
                      ? await _api.updateProduct(product['id'], data)
                      : await _api.addProduct(widget.user.email, data);
                  Navigator.pop(ctx);
                  _fetchMenu();
                },
                child: const Text("Kaydet"),
              ),
            ],
          );
        },
      ),
    );
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
              icon: const Icon(Icons.add),
              label: const Text("Ürün Ekle"),
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
          key: ValueKey(product['id']),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E6),
                    borderRadius: BorderRadius.circular(12),
                    image: item['image_url'] != null
                        ? DecorationImage(
                            image: NetworkImage(item['image_url']),
                            fit: BoxFit.cover,
                            colorFilter: available
                                ? null
                                : const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  ),
                          )
                        : null,
                  ),
                  child: item['image_url'] == null
                      ? const Icon(
                          Icons.restaurant_menu,
                          color: Color(0xFFE85B2B),
                        )
                      : null,
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
