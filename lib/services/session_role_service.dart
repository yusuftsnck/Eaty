import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionRoleService {
  SessionRoleService._();
  static final SessionRoleService instance = SessionRoleService._();

  static const _prefsKey = 'last_active_role';

  final ValueNotifier<String?> role = ValueNotifier(null);
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey);
    if (raw == 'customer' || raw == 'business') {
      role.value = raw;
    } else {
      role.value = null;
    }
  }

  Future<void> setRole(String? value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value == null) {
      role.value = null;
      await prefs.remove(_prefsKey);
      return;
    }
    if (value != 'customer' && value != 'business') return;
    role.value = value;
    await prefs.setString(_prefsKey, value);
  }
}
