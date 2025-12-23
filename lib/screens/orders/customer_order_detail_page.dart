import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';

class CustomerOrderDetailPage extends StatelessWidget {
  final dynamic order;
  final Color accentColor;

  const CustomerOrderDetailPage({
    super.key,
    required this.order,
    required this.accentColor,
  });

  String _formatDate(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} / $hour:$minute';
  }

  String _formatPrice(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null) return '0';
    final isWhole = parsed.truncateToDouble() == parsed;
    return isWhole ? parsed.toStringAsFixed(0) : parsed.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'Onay Bekliyor';
    final businessName = order['business_name']?.toString() ?? 'İşletme';
    final photoUrl = order['business_photo_url']?.toString();
    final businessAddress = order['business_address']?.toString();
    final dateText = _formatDate(order['created_at']);
    final items = (order['items'] as List<dynamic>? ?? []);
    final address =
        order['customer_address']?.toString() ?? 'Adres belirtilmedi';
    final totalText = _formatPrice(order['total_price']);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Sipariş Detayı'),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _InfoCard(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.15),
                  child: Icon(Icons.check_circle, color: accentColor),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sipariş Durumu',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppImage(
                    source: photoUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 58,
                      height: 58,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.storefront),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      if (businessAddress != null &&
                          businessAddress.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          businessAddress,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Sipariş No: ${order['id']}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sipariş Tarihi: $dateText',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Sepetindeki Ürünler'),
          const SizedBox(height: 8),
          _InfoCard(
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _OrderItemRow(item: items[i]),
                  if (i != items.length - 1) const Divider(height: 16),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Teslimat Adresi'),
          const SizedBox(height: 8),
          _InfoCard(child: Text(address)),
          const SizedBox(height: 16),
          _SectionTitle('Sipariş Özeti'),
          const SizedBox(height: 8),
          _InfoCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sipariş Tutarı',
                  style: TextStyle(color: Colors.black54),
                ),
                Text(
                  '$totalText TL',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
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

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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

class _OrderItemRow extends StatelessWidget {
  final dynamic item;

  const _OrderItemRow({required this.item});

  String _formatPrice(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null) return '0';
    final isWhole = parsed.truncateToDouble() == parsed;
    return isWhole ? parsed.toStringAsFixed(0) : parsed.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final name = item['product_name']?.toString() ?? '';
    final qty = item['quantity']?.toString() ?? '0';
    final price = _formatPrice(item['price']);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
          ),
          child: const Icon(Icons.fastfood, color: Colors.black45),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$qty adet',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        Text('$price TL', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
