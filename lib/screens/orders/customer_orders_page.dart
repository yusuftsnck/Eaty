import 'package:eatyy/screens/orders/customer_order_detail_page.dart';
import 'package:eatyy/screens/orders/order_review_page.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/utils/time_utils.dart';
import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';

class CustomerOrdersPage extends StatefulWidget {
  final String customerEmail;
  final String category;
  final Color accentColor;

  const CustomerOrdersPage({
    super.key,
    required this.customerEmail,
    required this.category,
    required this.accentColor,
  });

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  final _api = ApiService();

  String _formatDate(dynamic value) {
    final date = parseServerDateToTurkey(value);
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} / $hour:$minute';
  }

  bool _isDeliveredStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized.contains('teslim');
  }

  Future<void> _openReviewPage(dynamic order) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderReviewPage(
          order: order,
          accentColor: widget.accentColor,
          customerEmail: widget.customerEmail,
          category: widget.category,
        ),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Değerlendirmeniz alındı.')));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<List<dynamic>>(
        future: _api.getCustomerOrders(widget.customerEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          final orders = (snapshot.data ?? [])
              .where(
                (order) =>
                    order['business_category']?.toString() == widget.category,
              )
              .toList();
          if (orders.isEmpty) {
            return const Center(child: Text('Henüz sipariş yok.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final dateText = _formatDate(order['created_at']);
              final status = order['status']?.toString() ?? 'Onay Bekliyor';
              final reviewed = order['reviewed'] == true;
              final canReview = _isDeliveredStatus(status) && !reviewed;
              final businessName =
                  order['business_name']?.toString() ?? 'İşletme';
              final photoUrl = order['business_photo_url']?.toString();
              final businessAddress = order['business_address']?.toString();
              return _OrderCard(
                accentColor: widget.accentColor,
                status: status,
                businessName: businessName,
                dateText: dateText,
                photoUrl: photoUrl,
                businessAddress: businessAddress,
                reviewed: reviewed,
                reviewLabel: canReview ? 'Siparişi Değerlendir' : null,
                onReview: canReview ? () => _openReviewPage(order) : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerOrderDetailPage(
                        order: order,
                        accentColor: widget.accentColor,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Color accentColor;
  final String status;
  final String businessName;
  final String dateText;
  final String? photoUrl;
  final String? businessAddress;
  final bool reviewed;
  final String? reviewLabel;
  final VoidCallback? onReview;
  final VoidCallback onTap;

  const _OrderCard({
    required this.accentColor,
    required this.status,
    required this.businessName,
    required this.dateText,
    required this.photoUrl,
    required this.businessAddress,
    required this.reviewed,
    required this.reviewLabel,
    required this.onReview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppImage(
                        source: photoUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          width: 52,
                          height: 52,
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
                              businessAddress!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              businessAddress!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            dateText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
                if (onReview != null || reviewed) ...[
                  const SizedBox(height: 12),
                  if (onReview != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onReview,
                        icon: const Icon(Icons.star_border),
                        label: Text(reviewLabel ?? 'Değerlendir'),
                      ),
                    )
                  else
                    Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Değerlendirildi',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
