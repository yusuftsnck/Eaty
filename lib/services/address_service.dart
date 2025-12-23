import 'dart:convert';

import 'package:eatyy/models/user_address.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressService {
  AddressService._();
  static final AddressService instance = AddressService._();

  static const _addressesKey = 'user_addresses';
  static const _selectedKey = 'selected_address_id';

  final ValueNotifier<List<UserAddress>> addresses = ValueNotifier([]);
  final ValueNotifier<UserAddress?> selected = ValueNotifier(null);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded
              .whereType<Map>()
              .map((e) => UserAddress.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          addresses.value = list;
        }
      } catch (_) {}
    }

    final selectedId = prefs.getString(_selectedKey);
    if (selectedId != null && selectedId.isNotEmpty) {
      selected.value = addresses.value
          .where((a) => a.id == selectedId)
          .firstOrNull;
    }
    if (selected.value == null && addresses.value.isNotEmpty) {
      selected.value = addresses.value.first;
      await _persistSelected();
    }
  }

  Future<void> addOrUpdate(UserAddress address, {bool select = true}) async {
    final list = List<UserAddress>.from(addresses.value);
    final index = list.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      list[index] = address;
    } else {
      list.add(address);
    }
    addresses.value = list;
    if (select) {
      selected.value = address;
    }
    await _persistAll();
  }

  Future<void> remove(String id) async {
    final list = List<UserAddress>.from(addresses.value);
    list.removeWhere((a) => a.id == id);
    addresses.value = list;
    if (selected.value?.id == id) {
      selected.value = list.isNotEmpty ? list.first : null;
    }
    await _persistAll();
  }

  Future<void> select(UserAddress address) async {
    selected.value = address;
    await _persistSelected();
  }

  Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = addresses.value.map((a) => a.toJson()).toList();
    await prefs.setString(_addressesKey, jsonEncode(list));
    await _persistSelected();
  }

  Future<void> _persistSelected() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedId = selected.value?.id;
    if (selectedId == null) {
      await prefs.remove(_selectedKey);
    } else {
      await prefs.setString(_selectedKey, selectedId);
    }
  }
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
