import 'package:eatyy/services/address_service.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/services/cart_service.dart';
import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  final String category;
  final String? customerEmail;

  const CheckoutPage({super.key, required this.category, this.customerEmail});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _api = ApiService();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _ringBell = true;
  bool _contactless = false;
  String _paymentMethod = 'Kredi Kartı';
  bool _saving = false;

  CartService get _cartService => CartService.ofCategory(widget.category);

  Color get _headerColor => widget.category == 'market'
      ? const Color(0xFF009966)
      : const Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    final selected = AddressService.instance.selected.value;
    if (selected != null) {
      _addressCtrl.text = selected.fullAddress;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(double value) {
    final isWhole = value.truncateToDouble() == value;
    return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  Future<void> _submit() async {
    if (_saving) return;
    final cart = _cartService.cart.value;
    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sepet boş.')));
      return;
    }

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Teslimat adresi gerekli.')));
      return;
    }

    final email = widget.customerEmail ?? 'guest@eaty.app';

    final items = cart.items
        .map(
          (item) => {
            'product_name': item.name,
            'quantity': item.quantity,
            'price': item.price,
          },
        )
        .toList();

    setState(() => _saving = true);
    final success = await _api.placeOrder({
      'business_id': cart.business!.id,
      'customer_email': email,
      'customer_address': address,
      'total_price': cart.total,
      'items': items,
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      _cartService.clear();
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Sipariş alındı'),
          content: const Text('Siparişiniz işletmeye iletildi.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sipariş oluşturulamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = _cartService.cart.value;
    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Siparişi Tamamla'),
          backgroundColor: _headerColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Sepet boş.')),
      );
    }

    final totalText = _formatPrice(cart.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişi Tamamla'),
        backgroundColor: _headerColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          _SectionTitle('Teslimat Adresin'),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              children: [
                TextField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Adresini gir',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ToggleTile(
                        label: 'Zili Çalma',
                        value: _ringBell,
                        onChanged: (value) {
                          setState(() => _ringBell = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToggleTile(
                        label: 'Temassız Teslimat',
                        value: _contactless,
                        onChanged: (value) {
                          setState(() => _contactless = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Ödeme Yöntemin'),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              children: [
                _PaymentOption(
                  title: 'Kredi Kartı',
                  value: _paymentMethod,
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),
                const Divider(height: 16),
                _PaymentOption(
                  title: 'Nakit',
                  value: _paymentMethod,
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),
                const Divider(height: 16),
                _PaymentOption(
                  title: 'Online Ödeme',
                  value: _paymentMethod,
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Sipariş Notu'),
          const SizedBox(height: 8),
          _Card(
            child: TextField(
              controller: _noteCtrl,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Sipariş notu ekle',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Sipariş Özeti'),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Sepetimdeki Ürünler',
                  value: '${cart.totalItems} adet',
                ),
                const Divider(height: 16),
                _SummaryRow(label: 'Sipariş Tutarı', value: '$totalText TL'),
                const Divider(height: 16),
                const _SummaryRow(
                  label: 'Teslimat Ücreti',
                  value: 'Ücretsiz Teslimat',
                  valueColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ödenecek Tutar',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  Text(
                    '$totalText TL',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ödeme Yap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        fontSize: 15,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.deepOrange,
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final String value;
  final ValueChanged<String> onChanged;

  const _PaymentOption({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(title),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Radio<String>(
            value: title,
            groupValue: value,
            onChanged: (val) => onChanged(val ?? title),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
