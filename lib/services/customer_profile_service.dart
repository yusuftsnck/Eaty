import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerProfile {
  final String? name;
  final String? phoneDigits;

  const CustomerProfile({this.name, this.phoneDigits});

  String? get formattedPhone {
    final digits = phoneDigits;
    if (digits == null || digits.trim().isEmpty) return null;
    return formatTrPhone(digits);
  }

  CustomerProfile copyWith({String? name, String? phoneDigits}) {
    return CustomerProfile(
      name: name ?? this.name,
      phoneDigits: phoneDigits ?? this.phoneDigits,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'phoneDigits': phoneDigits};
  }

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      name: json['name']?.toString(),
      phoneDigits: json['phoneDigits']?.toString(),
    );
  }
}

class CustomerProfileService {
  CustomerProfileService._();
  static final CustomerProfileService instance = CustomerProfileService._();

  final ValueNotifier<CustomerProfile?> profile = ValueNotifier(null);

  SharedPreferences? _prefs;
  String? _currentKey;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setUser(String? email) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (email == null || email.trim().isEmpty) {
      _currentKey = null;
      profile.value = null;
      return;
    }
    final key = _buildKey(email);
    if (_currentKey == key) return;
    _currentKey = key;
    await _loadFromPrefs(key);
  }

  String _buildKey(String email) {
    final safe = Uri.encodeComponent(email.trim().toLowerCase());
    return 'customer_profile_$safe';
  }

  Future<void> _loadFromPrefs(String key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      profile.value = null;
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        profile.value = CustomerProfile.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      profile.value = null;
    }
  }

  Future<void> updateProfile({String? name, String? phoneDigits}) async {
    final key = _currentKey;
    if (key == null) return;
    final trimmedName = name?.trim();
    final trimmedPhone = phoneDigits?.trim();
    final hasName = trimmedName != null && trimmedName.isNotEmpty;
    final hasPhone = trimmedPhone != null && trimmedPhone.isNotEmpty;
    if (!hasName && !hasPhone) {
      profile.value = null;
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    final updated = CustomerProfile(
      name: hasName ? trimmedName : null,
      phoneDigits: hasPhone ? trimmedPhone : null,
    );
    profile.value = updated;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(updated.toJson()));
  }
}

String formatTrPhone(String digits) {
  final clean = digits.replaceAll(RegExp(r'\D'), '');
  if (clean.isEmpty) return '';
  final trimmed = clean.length > 11 ? clean.substring(0, 11) : clean;
  final buffer = StringBuffer();
  buffer.write(trimmed[0]);
  if (trimmed.length >= 2) {
    buffer.write('(');
    buffer.write(trimmed[1]);
  }
  if (trimmed.length >= 3) buffer.write(trimmed[2]);
  if (trimmed.length >= 4) {
    buffer.write(trimmed[3]);
    buffer.write(')');
  } else {
    return buffer.toString();
  }
  if (trimmed.length >= 5) {
    buffer.write(' ');
    buffer.write(trimmed[4]);
  }
  if (trimmed.length >= 6) buffer.write(trimmed[5]);
  if (trimmed.length >= 7) {
    buffer.write(trimmed[6]);
  } else {
    return buffer.toString();
  }
  if (trimmed.length >= 8) {
    buffer.write(' ');
    buffer.write(trimmed[7]);
  }
  if (trimmed.length >= 9) {
    buffer.write(trimmed[8]);
  } else {
    return buffer.toString();
  }
  if (trimmed.length >= 10) {
    buffer.write(' ');
    buffer.write(trimmed[9]);
  }
  if (trimmed.length >= 11) {
    buffer.write(trimmed[10]);
  }
  return buffer.toString();
}
