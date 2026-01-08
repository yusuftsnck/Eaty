import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/utils/time_utils.dart';
import 'package:flutter/material.dart';

class BusinessReviewsPage extends StatefulWidget {
  final int businessId;
  final String businessLabel;
  final Color accentColor;

  const BusinessReviewsPage({
    super.key,
    required this.businessId,
    required this.businessLabel,
    required this.accentColor,
  });

  @override
  State<BusinessReviewsPage> createState() => _BusinessReviewsPageState();
}

class _BusinessReviewsPageState extends State<BusinessReviewsPage> {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await _api.getBusinessReviews(widget.businessId);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _loading = false;
    });
  }

  double _parseRating(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  double _avgOf(List<double> values) {
    if (values.isEmpty) return 0;
    final sum = values.fold<double>(0, (a, b) => a + b);
    return sum / values.length;
  }

  String _formatRating(double value) => value.toStringAsFixed(1);

  String _timeAgo(dynamic value) {
    final date = parseServerDateToTurkey(value);
    if (date == null) return '';
    final diff = nowInTurkey().difference(date);
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks HAFTA ÖNCE';
    }
    if (diff.inDays >= 1) {
      return '${diff.inDays} GÜN ÖNCE';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} SAAT ÖNCE';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} DK ÖNCE';
    }
    return 'ŞİMDİ';
  }

  Color _ratingColor(double value) {
    if (value >= 4) return Colors.green;
    if (value >= 3) return Colors.orange;
    if (value > 0) return Colors.redAccent;
    return Colors.black38;
  }

  Widget _buildSummaryRow(String label, double value) {
    final color = _ratingColor(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Icon(Icons.star, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            _formatRating(value),
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRating(String label, double value) {
    final color = _ratingColor(value);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(width: 4),
        Icon(Icons.star, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          _formatRating(value),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.accentColor == Colors.green
        ? const [Color(0xFF28D06C), Color(0xFF009966)]
        : const [Color(0xFFFF7A18), Color(0xFFE60012)];
    final speedValues = <double>[];
    final serviceValues = <double>[];
    final tasteValues = <double>[];

    for (final review in _reviews) {
      final rating = _parseRating(review['rating']);
      final speed = _parseRating(review['speed_rating']);
      final service = _parseRating(review['service_rating']);
      final taste = _parseRating(review['taste_rating']);
      speedValues.add(speed > 0 ? speed : rating);
      serviceValues.add(service > 0 ? service : rating);
      tasteValues.add(taste > 0 ? taste : rating);
    }

    final avgSpeed = _avgOf(speedValues);
    final avgService = _avgOf(serviceValues);
    final avgTaste = _avgOf(tasteValues);
    final overallAvg =
        _avgOf([avgSpeed, avgService, avgTaste].where((v) => v > 0).toList());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Yorumlar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  '${widget.businessLabel} Puanı',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.star,
                              size: 32,
                              color: _ratingColor(overallAvg),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatRating(overallAvg),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _ratingColor(overallAvg),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryRow('Hız', avgSpeed),
                              _buildSummaryRow('Servis', avgService),
                              _buildSummaryRow('Lezzet', avgTaste),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Yorumlar (${_reviews.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                if (_reviews.isEmpty)
                  const Center(child: Text('Henüz yorum yok.'))
                else
                  for (final review in _reviews) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE6E6E6)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person,
                              color: Colors.black38,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (review['comment']?.toString().trim().isNotEmpty ==
                                              true)
                                      ? review['comment'].toString()
                                      : 'Yorum yapılmadı.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _timeAgo(review['created_at']),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 6,
                                  children: [
                                    _buildMiniRating(
                                      'Hız',
                                      _parseRating(review['speed_rating']) > 0
                                          ? _parseRating(review['speed_rating'])
                                          : _parseRating(review['rating']),
                                    ),
                                    _buildMiniRating(
                                      'Servis',
                                      _parseRating(review['service_rating']) > 0
                                          ? _parseRating(review['service_rating'])
                                          : _parseRating(review['rating']),
                                    ),
                                    _buildMiniRating(
                                      'Lezzet',
                                      _parseRating(review['taste_rating']) > 0
                                          ? _parseRating(review['taste_rating'])
                                          : _parseRating(review['rating']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
    );
  }
}
