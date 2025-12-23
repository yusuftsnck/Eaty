import 'dart:convert';

import 'package:flutter/material.dart';

class RestaurantInfoPage extends StatelessWidget {
  final String name;
  final String? ownerName;
  final String? ownerSurname;
  final String address;
  final String? phone;
  final String? workingHours;

  const RestaurantInfoPage({
    super.key,
    required this.name,
    required this.ownerName,
    required this.ownerSurname,
    required this.address,
    required this.phone,
    required this.workingHours,
  });

  String _maskName(String? value) {
    if (value == null) return '';
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    return parts
        .where((p) => p.isNotEmpty)
        .map((p) {
          if (p.length <= 1) return p;
          return p[0] + ('*' * (p.length - 1));
        })
        .join(' ');
  }

  Map<String, dynamic>? _parseWorkingHours(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  List<_WorkingHourRow> _buildWorkingHours() {
    final parsed = _parseWorkingHours(workingHours);
    if (parsed == null) return [];
    const templates = [
      _WorkingHourTemplate('mon', 'Pazartesi'),
      _WorkingHourTemplate('tue', 'Salı'),
      _WorkingHourTemplate('wed', 'Çarşamba'),
      _WorkingHourTemplate('thu', 'Perşembe'),
      _WorkingHourTemplate('fri', 'Cuma'),
      _WorkingHourTemplate('sat', 'Cumartesi'),
      _WorkingHourTemplate('sun', 'Pazar'),
    ];
    final rows = <_WorkingHourRow>[];
    for (final template in templates) {
      final raw = parsed[template.key];
      String value = 'Belirtilmedi';
      if (raw is Map) {
        final closed = raw['closed'] == true;
        final open = raw['open']?.toString();
        final close = raw['close']?.toString();
        if (closed) {
          value = 'Kapalı';
        } else if (open != null && close != null) {
          value = '$open - $close';
        }
      }
      rows.add(_WorkingHourRow(template.label, value));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final maskedName = _maskName(ownerName);
    final maskedSurname = _maskName(ownerSurname);
    final ownerDisplay = [
      maskedName,
      maskedSurname,
    ].where((part) => part.isNotEmpty).join(' ').trim();
    final ownerText = ownerDisplay.isEmpty ? 'Bilinmiyor' : ownerDisplay;
    final phoneText = (phone != null && phone!.trim().isNotEmpty)
        ? phone!
        : 'Belirtilmemiş';
    final hours = _buildWorkingHours();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Restoran Bilgileri'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _InfoCard(
            title: 'İşletme',
            children: [
              _InfoRow(label: 'Ad', value: name),
              _InfoRow(label: 'Yetkili', value: ownerText),
              _InfoRow(label: 'Telefon', value: phoneText),
              _InfoRow(label: 'Adres', value: address),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Çalışma Saatleri',
            children: hours.isEmpty
                ? [const _InfoRow(label: 'Saatler', value: 'Belirtilmemiş')]
                : hours
                      .map((row) => _InfoRow(label: row.day, value: row.hours))
                      .toList(),
          ),
        ],
      ),
    );
  }
}

class _WorkingHourTemplate {
  final String key;
  final String label;
  const _WorkingHourTemplate(this.key, this.label);
}

class _WorkingHourRow {
  final String day;
  final String hours;
  const _WorkingHourRow(this.day, this.hours);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
