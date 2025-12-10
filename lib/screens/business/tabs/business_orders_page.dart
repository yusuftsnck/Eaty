import 'package:flutter/material.dart';

class BusinessOrdersPage extends StatelessWidget {
  const BusinessOrdersPage({super.key});

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
      _OrderRow(
        table: 'Çevrimiçi',
        name: 'Falafel Bowl',
        price: '₺140',
        statusColor: const Color(0xFF3F51B5),
        statusText: 'Yolda',
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          const _SectionTitle('Siparişler'),
          const SizedBox(height: 10),
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _OrderCard(order: order),
            ),
          ),
        ],
      ),
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

class _OrderCard extends StatelessWidget {
  final _OrderRow order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E6),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.receipt_long, color: Color(0xFFE85B2B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.table,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  order.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w700,
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
    );
  }
}
