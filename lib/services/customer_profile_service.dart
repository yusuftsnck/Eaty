import 'dart:async';
import 'dart:convert';

import 'package:eatyy/services/api_service.dart';
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
  final ApiService _api = ApiService();

  SharedPreferences? _prefs;
  String? _currentKey;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setUser(String? email) async {
    _prefs ??= await SharedPreferences.getInstance();
    final trimmedEmail = email?.trim();
    if (trimmedEmail == null || trimmedEmail.isEmpty) {
      _currentKey = null;
      profile.value = null;
      return;
    }
    final key = _buildKey(trimmedEmail);
    if (_currentKey == key) return;
    _currentKey = key;
    await _loadFromPrefs(key);
    unawaited(_syncRemoteProfile(trimmedEmail, key));
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

  CustomerProfile? _profileFromRemote(Map<String, dynamic> data) {
    final rawName = data['name']?.toString();
    final rawPhone = data['phone']?.toString();
    final name = rawName?.trim();
    final phone = rawPhone?.trim();
    final hasName = name != null && name.isNotEmpty;
    final hasPhone = phone != null && phone.isNotEmpty;
    if (!hasName && !hasPhone) return null;
    return CustomerProfile(
      name: hasName ? name : null,
      phoneDigits: hasPhone ? phone : null,
    );
  }

  CustomerProfile _mergeProfiles(
    CustomerProfile local,
    CustomerProfile remote,
  ) {
    final localName = local.name?.trim();
    final localPhone = local.phoneDigits?.trim();
    return CustomerProfile(
      name: (localName != null && localName.isNotEmpty)
          ? localName
          : remote.name,
      phoneDigits: (localPhone != null && localPhone.isNotEmpty)
          ? localPhone
          : remote.phoneDigits,
    );
  }

  bool _profilesMatch(CustomerProfile? a, CustomerProfile? b) {
    final nameA = a?.name?.trim() ?? '';
    final nameB = b?.name?.trim() ?? '';
    final phoneA = a?.phoneDigits?.trim() ?? '';
    final phoneB = b?.phoneDigits?.trim() ?? '';
    return nameA == nameB && phoneA == phoneB;
  }

  Future<void> _saveToPrefs(String key, CustomerProfile updated) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(updated.toJson()));
  }

  Future<void> _syncRemoteProfile(String email, String key) async {
    final remoteData = await _api.getCustomerProfile(email);
    if (_currentKey != key) return;
    final local = profile.value;

    if (remoteData == null) {
      final name = local?.name?.trim();
      if (name != null && name.isNotEmpty) {
        final phone = local?.phoneDigits ?? '';
        await _api.updateCustomerProfile(email, name: name, phone: phone);
      }
      return;
    }

    final remoteProfile = _profileFromRemote(remoteData);
    if (remoteProfile == null) return;

    if (local == null) {
      profile.value = remoteProfile;
      await _saveToPrefs(key, remoteProfile);
      return;
    }

    final merged = _mergeProfiles(local, remoteProfile);
    if (_profilesMatch(local, merged)) return;
    profile.value = merged;
    await _saveToPrefs(key, merged);
  }

  Future<void> updateProfile({
    String? name,
    String? phoneDigits,
    String? email,
  }) async {
    final resolvedEmail = email?.trim();
    if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
      await setUser(resolvedEmail);
    }
    final key = _currentKey;
    if (key == null) return;
    final previous = profile.value;
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
    await _saveToPrefs(key, updated);

    if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
      final remoteName = updated.name?.trim() ?? previous?.name?.trim();
      if (remoteName != null && remoteName.isNotEmpty) {
        final remotePhone = hasPhone
            ? (trimmedPhone)
            : (updated.phoneDigits ?? '');
        unawaited(
          _api.updateCustomerProfile(
            resolvedEmail,
            name: remoteName,
            phone: remotePhone,
          ),
        );
      }
    }
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
