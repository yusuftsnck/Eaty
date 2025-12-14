import 'package:eatyy/screens/business/business_order_detail_page.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class BusinessOrdersPage extends StatefulWidget {
  final GoogleSignInAccount user;
  const BusinessOrdersPage({super.key, required this.user});

  @override
  State<BusinessOrdersPage> createState() => _BusinessOrdersPageState();
}

class _BusinessOrdersPageState extends State<BusinessOrdersPage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<dynamic> _allOrders = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    final orders = await _api.getBusinessOrders(widget.user.email);
    if (mounted)
      setState(() {
        _allOrders = orders;
        _loading = false;
      });
  }

  // Siparişleri duruma göre filtrele
  List<dynamic> _filterOrders(List<String> statuses) {
    return _allOrders.where((o) => statuses.contains(o['status'])).toList();
  }

  Future<void> _quickUpdate(int orderId, String status) async {
    await _api.updateOrderStatus(orderId, status);
    _fetchOrders();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Sipariş: $status")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          "Sipariş Yönetimi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrange,
          tabs: [
            Tab(text: "Gelen (${_filterOrders(['Onay Bekliyor']).length})"),
            Tab(text: "Mutfak (${_filterOrders(['Hazırlanıyor']).length})"),
            Tab(text: "Geçmiş"),
          ],
        ),
        actions: [
          IconButton(onPressed: _fetchOrders, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(
                  _filterOrders(['Onay Bekliyor']),
                  isIncoming: true,
                ),

                _buildOrderList(
                  _filterOrders(['Hazırlanıyor']),
                  isKitchen: true,
                ),

                _buildOrderList(
                  _filterOrders(['Yolda', 'Teslim Edildi', 'İptal Edildi']),
                ),
              ],
            ),
    );
  }

  Widget _buildOrderList(
    List<dynamic> orders, {
    bool isIncoming = false,
    bool isKitchen = false,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text(
              "Bu alanda sipariş yok",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessOrderDetailPage(order: order),
                ),
              ).then((_) => _fetchOrders());
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sipariş #${order['id']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            order['created_at'].toString().substring(11, 16),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${order['total_price']} ₺",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order['customer_address'] ?? "Adres girilmedi",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isIncoming)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectDialog(order['id']),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text("Reddet"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _quickUpdate(order['id'], "Hazırlanıyor"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Onayla"),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isKitchen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _quickUpdate(order['id'], "Yolda"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delivery_dining),
                        label: const Text("Kuryeye Teslim Et"),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRejectDialog(int orderId) async {
    final reasonCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Siparişi Reddet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bu siparişi reddetmek istediğinize emin misiniz?"),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: "Red Sebebi",
                hintText: "Malzeme kalmadı, Adres dışı...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _api.updateOrderStatus(
                orderId,
                "İptal Edildi",
                reason: reasonCtrl.text,
              );
              _fetchOrders();
            },
            child: const Text("Reddet"),
          ),
        ],
      ),
    );
  }
}
