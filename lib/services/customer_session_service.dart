import 'dart:convert';

import 'package:eatyy/models/app_user.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerSessionService {
  CustomerSessionService._();
  static final CustomerSessionService instance = CustomerSessionService._();

  static const _prefsKey = 'customer_session';

  final ValueNotifier<AppUser?> user = ValueNotifier(null);
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _load();
  }

  Future<void> setUser(AppUser? value) async {
    user.value = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, jsonEncode(value.toJson()));
    }
  }

  Future<void> _load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      user.value = null;
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        user.value = AppUser.fromJson(Map<String, dynamic>.from(decoded));
      } else {
        user.value = null;
      }
    } catch (_) {
      user.value = null;
    }
  }
}
