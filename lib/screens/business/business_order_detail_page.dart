import 'package:eatyy/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eatyy/utils/time_utils.dart';

class BusinessOrderDetailPage extends StatefulWidget {
  final dynamic order;
  const BusinessOrderDetailPage({super.key, required this.order});

  @override
  State<BusinessOrderDetailPage> createState() =>
      _BusinessOrderDetailPageState();
}

class _BusinessOrderDetailPageState extends State<BusinessOrderDetailPage> {
  final _api = ApiService();
  late String _currentStatus;
  bool _updating = false;

  final List<String> _statuses = [
    "Onay Bekliyor",
    "Hazırlanıyor",
    "Yolda",
    "Teslim Edildi",
    "İptal Edildi",
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] ?? "Onay Bekliyor";
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    final success = await _api.updateOrderStatus(widget.order['id'], newStatus);

    if (success) {
      setState(() => _currentStatus = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Durum güncellendi")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Hata oluştu")));
      }
    }
    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final date =
        parseServerDateToTurkey(order['created_at']) ?? nowInTurkey();
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);
    final items = order['items'] as List<dynamic>? ?? [];
    final customerName = _formatValue(order['customer_name'], 'Belirtilmedi');
    final customerPhone = _formatValue(order['customer_phone'], 'Belirtilmedi');
    final customerNote = _formatValue(order['customer_note'], 'Not yok');
    final customerAddress =
        _formatValue(order['customer_address'], 'Adres girilmedi');

    return Scaffold(
      appBar: AppBar(
        title: Text("Sipariş #${order['id']}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DURUM YÖNETİM KARTI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sipariş Durumu",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _statuses.contains(_currentStatus)
                        ? _currentStatus
                        : _statuses.first,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: _updating
                        ? null
                        : (val) {
                            if (val != null) _updateStatus(val);
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // MÜŞTERİ BİLGİLERİ
            _buildSectionTitle("Müşteri Bilgileri"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.person,
                    "İsim Soyisim",
                    customerName,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.phone,
                    "Telefon",
                    customerPhone,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.location_on,
                    "Adres",
                    customerAddress,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.sticky_note_2_outlined,
                    "Sipariş Notu",
                    customerNote,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.calendar_today, "Tarih", formattedDate),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SİPARİŞ İÇERİĞİ
            _buildSectionTitle("Sipariş İçeriği"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ...items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${item['quantity']}x ${item['product_name']}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                "${item['price']} ₺",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOPLAM",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${order['total_price']} ₺",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatValue(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isNotEmpty ? text : fallback;
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepOrange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
