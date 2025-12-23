import 'dart:convert';

import 'package:eatyy/models/business_user.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessSessionService {
  BusinessSessionService._();
  static final BusinessSessionService instance = BusinessSessionService._();

  static const _prefsKey = 'business_session';

  final ValueNotifier<BusinessUser?> user = ValueNotifier(null);
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _load();
  }

  Future<void> setUser(BusinessUser? value) async {
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
        user.value = BusinessUser.fromJson(Map<String, dynamic>.from(decoded));
      } else {
        user.value = null;
      }
    } catch (_) {
      user.value = null;
    }
  }
}
