import 'package:eatyy/models/business_user.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/utils/time_utils.dart';
import 'package:flutter/material.dart';

class BusinessDashboardHomePage extends StatefulWidget {
  final BusinessUser user;
  const BusinessDashboardHomePage({super.key, required this.user});

  @override
  State<BusinessDashboardHomePage> createState() =>
      _BusinessDashboardHomePageState();
}

class _BusinessDashboardHomePageState extends State<BusinessDashboardHomePage> {
  final _api = ApiService();
  bool _loading = true;

  // İstatistik Değişkenleri
  double _dailyRevenue = 0.0;
  int _todayOrderCount = 0;

  // Rozet Sayacı Değişkenleri
  int _activeCount = 0; // "Yeni Sipariş" durumu
  int _preparingCount = 0; // "Hazırlanıyor" durumu
  int _deliveredCount = 0; // "Teslim" durumu

  // Liste
  List<dynamic> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final orders = await _api.getBusinessOrders(widget.user.email);

    if (!mounted) return;

    double revenue = 0;
    int todayCount = 0;
    int active = 0;
    int preparing = 0;
    int delivered = 0;

    final now = nowInTurkey();

    for (var order in orders) {
      // Sipariş tarihini parse et
      final orderDate =
          parseServerDateToTurkey(order['created_at']) ?? DateTime(2000);

      // Bugün mü kontrolü (Yıl, Ay, Gün eşitliği)
      bool isToday =
          orderDate.year == now.year &&
          orderDate.month == now.month &&
          orderDate.day == now.day;

      // Durum kontrolü (Backend'deki status stringlerine göre)
      String status = order['status'] ?? "Yeni Sipariş";

      if (status == "Yeni Sipariş") active++;
      if (status == "Hazırlanıyor") preparing++;
      if (status == "Teslim") delivered++;

      // Günlük Ciro ve Sayı Hesaplama
      if (isToday) {
        revenue += (order['total_price'] as num).toDouble();
        todayCount++;
      }
    }

    setState(() {
      _recentOrders = orders.take(5).toList(); // Son 5 siparişi göster
      _dailyRevenue = revenue;
      _todayOrderCount = todayCount;
      _activeCount = active;
      _preparingCount = preparing;
      _deliveredCount = delivered;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final label = widget.user.category == 'market' ? 'Market' : 'Restoran';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                user: widget.user,
                businessLabel: label,
                topPadding: padding.top,
                activeCount: _activeCount,
                preparingCount: _preparingCount,
                deliveredCount: _deliveredCount,
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Güncel Durum'),
                    const SizedBox(height: 10),
                    _StatsRow(
                      dailyRevenue: _dailyRevenue,
                      todayCount: _todayOrderCount,
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle('Son Siparişler'),
                    const SizedBox(height: 12),
                    _OrdersPreview(orders: _recentOrders),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final BusinessUser user;
  final String businessLabel;
  final double topPadding;
  final int activeCount;
  final int preparingCount;
  final int deliveredCount;

  const _Header({
    required this.user,
    required this.businessLabel,
    required this.topPadding,
    required this.activeCount,
    required this.preparingCount,
    required this.deliveredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7A18), Color(0xFFE60012)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '$businessLabel Yönetimi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Merhaba, ${user.name ?? businessLabel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderBadge(
                  label: 'Yeni',
                  value: '$activeCount',
                  icon: Icons.notifications_active,
                ),
                _HeaderBadge(
                  label: 'Hazırlanıyor',
                  value: '$preparingCount',
                  icon: Icons.local_dining,
                ),
                _HeaderBadge(
                  label: 'Teslim',
                  value: '$deliveredCount',
                  icon: Icons.delivery_dining,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _HeaderBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final double dailyRevenue;
  final int todayCount;

  const _StatsRow({required this.dailyRevenue, required this.todayCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Günlük Ciro',
            value: '₺${dailyRevenue.toStringAsFixed(2)}',
            trend: 'Bugün',
            color: const Color(0xFF4CAF50),
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Yeni Sipariş',
            value: '$todayCount',
            trend: 'Bugün',
            color: const Color(0xFF3F51B5),
            icon: Icons.shopping_bag,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20, // Biraz küçülttüm sığması için
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  trend,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersPreview extends StatelessWidget {
  final List<dynamic> orders;
  const _OrdersPreview({required this.orders});

  Color _getStatusColor(String status) {
    switch (status) {
      case "Hazırlanıyor":
        return const Color(0xFFFFC107);
      case "Teslim":
        return const Color(0xFF4CAF50);
      case "Yeni Sipariş":
        return const Color(0xFFE53935);
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text("Henüz sipariş bulunmuyor.")),
      );
    }

    return Column(
      children: orders
          .map(
            (order) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFFE85B2B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['customer_name'] ?? 'Müşteri',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Sipariş #${order['id']}",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              order['status'] ?? "",
                            ).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            order['status'] ?? "Bilinmiyor",
                            style: TextStyle(
                              color: _getStatusColor(order['status'] ?? ""),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "₺${order['total_price']}",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
