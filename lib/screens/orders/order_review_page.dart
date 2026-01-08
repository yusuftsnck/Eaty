import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/utils/time_utils.dart';
import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';

class OrderReviewPage extends StatefulWidget {
  final dynamic order;
  final Color accentColor;
  final String customerEmail;
  final String category;

  const OrderReviewPage({
    super.key,
    required this.order,
    required this.accentColor,
    required this.customerEmail,
    required this.category,
  });

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  final _api = ApiService();
  final _commentCtrl = TextEditingController();
  int _speedRating = 0;
  int _serviceRating = 0;
  int _tasteRating = 0;
  bool _saving = false;
  Map<String, dynamic>? _business;
  bool _loadingBusiness = false;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    final email = widget.order['business_email']?.toString();
    if (email == null || email.trim().isEmpty) return;
    setState(() => _loadingBusiness = true);
    final profile = await _api.getBusiness(email);
    if (!mounted) return;
    setState(() {
      _business = profile;
      _loadingBusiness = false;
    });
  }

  String _formatDate(dynamic value) {
    final date = parseServerDateToTurkey(value);
    if (date == null) return '-';
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month ${date.year} - $hour:$minute';
  }

  String _formatPrice(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null) return '0';
    final isWhole = parsed.truncateToDouble() == parsed;
    return isWhole ? parsed.toStringAsFixed(0) : parsed.toStringAsFixed(2);
  }

  String _formatRatingText(double? value) {
    if (value == null) return 'Yeni';
    return value.toStringAsFixed(1);
  }

  double? _parseRating(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  bool get _canSubmit {
    return !_saving &&
        _speedRating > 0 &&
        _serviceRating > 0 &&
        _tasteRating > 0;
  }

  int get _averageRating {
    final avg = (_speedRating + _serviceRating + _tasteRating) / 3.0;
    return avg.round().clamp(1, 5);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final orderId = (widget.order['id'] as num?)?.toInt();
    if (orderId == null || orderId == 0) return;
    setState(() => _saving = true);
    final result = await _api.createOrderReview(
      orderId,
      widget.customerEmail,
      _averageRating,
      speedRating: _speedRating,
      serviceRating: _serviceRating,
      tasteRating: _tasteRating,
      comment: _commentCtrl.text,
    );
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Değerlendirme gönderilemedi.')),
    );
  }

  Widget _buildMiniRating(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 14, color: Colors.green),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final filled = index < value;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: _saving ? null : () => onChanged(index + 1),
                child: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: filled ? Colors.green : Colors.grey.shade400,
                  size: 30,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessName = widget.order['business_name']?.toString() ?? 'İşletme';
    final photoUrl = widget.order['business_photo_url']?.toString();
    final totalText = _formatPrice(widget.order['total_price']);
    final itemCount = (widget.order['items'] as List<dynamic>? ?? []).length;
    final dateText = _formatDate(widget.order['created_at']);

    final ratingAvg = _parseRating(_business?['rating_avg']);
    final speedAvg = _parseRating(_business?['rating_speed_avg']) ?? ratingAvg;
    final serviceAvg =
        _parseRating(_business?['rating_service_avg']) ?? ratingAvg;
    final tasteAvg = _parseRating(_business?['rating_taste_avg']) ?? ratingAvg;
    final ratingText = _formatRatingText(ratingAvg);

    final metaText = '$dateText | $itemCount Ürün | $totalText TL';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Siparişi Değerlendir'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.star, size: 32, color: Colors.green),
                      const SizedBox(height: 6),
                      Text(
                        ratingText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                      if (_loadingBusiness)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AppImage(
                                source: photoUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.storefront),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                businessName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _buildMiniRating(
                              'Hız',
                              _formatRatingText(speedAvg),
                            ),
                            _buildMiniRating(
                              'Servis',
                              _formatRatingText(serviceAvg),
                            ),
                            _buildMiniRating(
                              'Lezzet',
                              _formatRatingText(tasteAvg),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          metaText,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildRatingRow(
                  'Hız',
                  _speedRating,
                  (value) => setState(() => _speedRating = value),
                ),
                const SizedBox(height: 12),
                _buildRatingRow(
                  'Servis',
                  _serviceRating,
                  (value) => setState(() => _serviceRating = value),
                ),
                const SizedBox(height: 12),
                _buildRatingRow(
                  'Lezzet',
                  _tasteRating,
                  (value) => setState(() => _tasteRating = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _commentCtrl,
              maxLength: 300,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Siparişin nasıldı?',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Gönder',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
