import 'package:flutter/material.dart';

class BusinessMenuPage extends StatelessWidget {
  const BusinessMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        name: 'Margherita Pizza',
        category: 'Pizzalar',
        price: '₺145',
        available: true,
      ),
      _MenuItem(
        name: 'Izgara Köfte',
        category: 'Ana Yemek',
        price: '₺185',
        available: true,
      ),
      _MenuItem(
        name: 'Tavuk Caesar',
        category: 'Salatalar',
        price: '₺132',
        available: false,
      ),
      _MenuItem(
        name: 'Çikolatalı Sufle',
        category: 'Tatlı',
        price: '₺96',
        available: true,
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          const _SectionTitle('Menü'),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _MenuCard(item: item),
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

class _MenuItem {
  final String name;
  final String category;
  final String price;
  final bool available;
  const _MenuItem({
    required this.name,
    required this.category,
    required this.price,
    required this.available,
  });
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            child: const Icon(Icons.local_dining, color: Color(0xFFE85B2B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.category,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: (item.available ? Colors.green : Colors.red).withOpacity(
                0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              item.available ? 'Aktif' : 'Pasif',
              style: TextStyle(
                color: item.available ? Colors.green : Colors.red,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
