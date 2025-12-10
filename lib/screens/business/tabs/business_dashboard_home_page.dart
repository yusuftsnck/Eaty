import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class BusinessDashboardHomePage extends StatelessWidget {
  final GoogleSignInAccount user;
  const BusinessDashboardHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(user: user, topPadding: padding.top),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SectionTitle('Güncel Durum'),
                  SizedBox(height: 10),
                  _StatsRow(),
                  SizedBox(height: 22),
                  _SectionTitle('Hızlı İşlemler'),
                  SizedBox(height: 12),
                  _QuickActionsGrid(),
                  SizedBox(height: 22),
                  _SectionTitle('Bugünkü Siparişler'),
                  SizedBox(height: 12),
                  _OrdersPreview(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final GoogleSignInAccount user;
  final double topPadding;
  const _Header({required this.user, required this.topPadding});

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
                  children: const [
                    Icon(Icons.shield, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Restoran Yönetimi',
                      style: TextStyle(
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
            'Merhaba, ${user.displayName ?? 'Restoran'}',
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
              children: const [
                _HeaderBadge(
                  label: 'Aktif',
                  value: '12',
                  icon: Icons.receipt_long,
                ),
                _HeaderBadge(
                  label: 'Hazırlanıyor',
                  value: '4',
                  icon: Icons.local_dining,
                ),
                _HeaderBadge(
                  label: 'Teslim',
                  value: '8',
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
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            title: 'Günlük Ciro',
            value: '₺4.320',
            trend: '+12%',
            color: Color(0xFF4CAF50),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Yeni Sipariş',
            value: '7',
            trend: 'Bugün',
            color: Color(0xFF3F51B5),
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
  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.color,
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
              fontSize: 22,
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
                Icon(Icons.trending_up, color: color, size: 16),
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

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.fastfood, label: 'Menü'),
      _QuickAction(icon: Icons.receipt_long, label: 'Siparişler'),
      _QuickAction(icon: Icons.local_offer, label: 'Kampanyalar'),
      _QuickAction(icon: Icons.table_bar, label: 'Masalar'),
      _QuickAction(icon: Icons.people_alt, label: 'Personel'),
      _QuickAction(icon: Icons.analytics, label: 'Raporlar'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions
          .map(
            (e) => SizedBox(
              width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
              child: _QuickActionCard(action: e),
            ),
          )
          .toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E6),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(action.icon, color: const Color(0xFFE85B2B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action.label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }
}

class _OrdersPreview extends StatelessWidget {
  const _OrdersPreview();

  @override
  Widget build(BuildContext context) {
    final orders = [
      _OrderRow(
        table: 'Çevrimiçi',
        name: 'Burger Menü x2',
        price: '₺280',
        statusColor: const Color(0xFFFFC107),
        statusText: 'Hazırlanıyor',
      ),
      _OrderRow(
        table: 'Masa 4',
        name: 'Karışık Pizza',
        price: '₺190',
        statusColor: const Color(0xFF4CAF50),
        statusText: 'Teslim',
      ),
      _OrderRow(
        table: 'Paket',
        name: 'Tavuk Dürüm',
        price: '₺120',
        statusColor: const Color(0xFFE53935),
        statusText: 'Yeni',
      ),
    ];

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
                            order.table,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.name,
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
                            color: order.statusColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            order.statusText,
                            style: TextStyle(
                              color: order.statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.price,
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

class _OrderRow {
  final String table;
  final String name;
  final String price;
  final Color statusColor;
  final String statusText;
  const _OrderRow({
    required this.table,
    required this.name,
    required this.price,
    required this.statusColor,
    required this.statusText,
  });
}
