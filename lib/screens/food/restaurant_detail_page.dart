import 'package:eatyy/services/api_service.dart';
import 'package:flutter/material.dart';

class RestaurantDetailPage extends StatefulWidget {
  final int businessId;
  final String businessName;
  const RestaurantDetailPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final _api = ApiService();
  List<dynamic> _menu = [];
  final Map<String, int> _cart = {};
  double _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final items = await _api.getMenu(widget.businessId);
    if (mounted) {
      setState(() {
        _menu = items;
        _loading = false;
      });
    }
  }

  void _addToCart(dynamic product) {
    setState(() {
      final name = product['name'];
      _cart[name] = (_cart[name] ?? 0) + 1;
      _total += product['price'];
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("sepete eklendi"),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  // --- Adres Soran Dialog ---
  Future<void> _sendOrder() async {
    if (_cart.isEmpty) return;

    final addressController = TextEditingController();

    // Adres iste
    final address = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Teslimat Adresi"),
        content: TextField(
          controller: addressController,
          decoration: const InputDecoration(
            hintText: "Mahalle, Cadde, No...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, addressController.text),
            child: const Text("Siparişi Onayla"),
          ),
        ],
      ),
    );

    if (address == null || address.isEmpty) return;

    List<Map<String, dynamic>> items = [];
    _cart.forEach((name, qty) {
      final product = _menu.firstWhere((element) => element['name'] == name);
      items.add({
        "product_name": name,
        "quantity": qty,
        "price": product['price'],
      });
    });

    final success = await _api.placeOrder({
      "business_id": widget.businessId,
      "customer_email": "musteri@ornek.com", // Normalde giriş yapan user
      "customer_address": address, // <--- YENİ EKLENDİ
      "total_price": _total,
      "items": items,
    });

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Sipariş Alındı!"),
          content: const Text("Siparişiniz restorana iletildi."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Hata oluştu.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _menu.isEmpty
                ? const Center(child: Text("Bu restoranın menüsü henüz yok."))
                : ListView.builder(
                    itemCount: _menu.length,
                    itemBuilder: (ctx, i) {
                      final p = _menu[i];

                      bool showHeader = false;
                      if (i == 0 || _menu[i - 1]['category'] != p['category']) {
                        showHeader = true;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: Text(
                                p['category'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange.shade800,
                                ),
                              ),
                            ),
                          Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  p['image_url'] ?? "",
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.fastfood),
                                  ),
                                ),
                              ),
                              title: Text(
                                p['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text("${p['price']} ₺"),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _addToCart(p),
                                child: const Text("Ekle"),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Toplam Tutar",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          "$_total ₺",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _sendOrder,
                      child: const Text(
                        "Siparişi Tamamla",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
