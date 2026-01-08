import 'dart:async';
import 'dart:convert';

import 'package:eatyy/models/user_address.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressService {
  AddressService._();
  static final AddressService instance = AddressService._();

  static const _legacyAddressesKey = 'user_addresses';
  static const _legacySelectedKey = 'selected_address_id';

  final ValueNotifier<List<UserAddress>> addresses = ValueNotifier([]);
  final ValueNotifier<UserAddress?> selected = ValueNotifier(null);
  final ApiService _api = ApiService();

  SharedPreferences? _prefs;
  String? _currentKey;
  String? _currentSelectedKey;
  String? _currentEmail;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setUser(String? email) async {
    _prefs ??= await SharedPreferences.getInstance();
    final trimmedEmail = email?.trim();
    if (trimmedEmail == null || trimmedEmail.isEmpty) {
      _currentEmail = null;
      _currentKey = null;
      _currentSelectedKey = null;
      addresses.value = [];
      selected.value = null;
      return;
    }
    final key = _buildAddressesKey(trimmedEmail);
    if (_currentKey == key) return;
    _currentEmail = trimmedEmail;
    _currentKey = key;
    _currentSelectedKey = _buildSelectedKey(trimmedEmail);
    await _loadFromPrefs(
      key,
      _currentSelectedKey!,
      allowLegacy: true,
    );
    unawaited(_syncRemoteAddresses(trimmedEmail, key));
  }

  String _buildAddressesKey(String email) {
    final safe = Uri.encodeComponent(email.trim().toLowerCase());
    return 'user_addresses_$safe';
  }

  String _buildSelectedKey(String email) {
    final safe = Uri.encodeComponent(email.trim().toLowerCase());
    return 'selected_address_id_$safe';
  }

  Future<void> _loadFromPrefs(
    String key,
    String selectedKey, {
    bool allowLegacy = false,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    var list = _decodeList(prefs.getString(key));
    var migrated = false;

    if (list.isEmpty && allowLegacy) {
      final legacyList = _decodeList(prefs.getString(_legacyAddressesKey));
      if (legacyList.isNotEmpty) {
        list = legacyList;
        migrated = true;
      }
    }

    addresses.value = list;

    String? selectedId = prefs.getString(selectedKey);
    if ((selectedId == null || selectedId.isEmpty) && allowLegacy) {
      selectedId = prefs.getString(_legacySelectedKey);
    }
    final resolved = list.where((a) => a.id == selectedId).firstOrNull ??
        list.firstOrNull;
    selected.value = resolved;

    if (migrated) {
      await _persistAll(pushRemote: false);
      await prefs.remove(_legacyAddressesKey);
      await prefs.remove(_legacySelectedKey);
    } else if (selected.value?.id != selectedId) {
      await _persistSelected();
    }
  }

  List<UserAddress> _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => UserAddress.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _syncRemoteAddresses(String email, String key) async {
    final remoteData = await _api.getCustomerAddresses(email);
    if (_currentKey != key) return;
    final localList = addresses.value;

    if (remoteData == null) {
      if (localList.isNotEmpty) {
        unawaited(
          _api.updateCustomerAddresses(
            email,
            localList.map((a) => a.toJson()).toList(),
          ),
        );
      }
      return;
    }

    final remoteList = remoteData
        .map((e) => UserAddress.fromJson(Map<String, dynamic>.from(e)))
        .where((a) => a.id.trim().isNotEmpty)
        .toList();

    if (remoteList.isEmpty) {
      if (localList.isNotEmpty) {
        unawaited(
          _api.updateCustomerAddresses(
            email,
            localList.map((a) => a.toJson()).toList(),
          ),
        );
      }
      return;
    }

    if (localList.isEmpty) {
      addresses.value = remoteList;
      _ensureSelected();
      await _persistAll(pushRemote: false);
      return;
    }

    final merged = _mergeLists(localList, remoteList);
    if (_listsEqual(localList, merged)) return;

    addresses.value = merged;
    _ensureSelected();
    await _persistAll(pushRemote: false);
    unawaited(
      _api.updateCustomerAddresses(
        email,
        merged.map((a) => a.toJson()).toList(),
      ),
    );
  }

  List<UserAddress> _mergeLists(
    List<UserAddress> local,
    List<UserAddress> remote,
  ) {
    final localIds = local.map((a) => a.id).toSet();
    final merged = List<UserAddress>.from(local);
    for (final address in remote) {
      if (!localIds.contains(address.id)) {
        merged.add(address);
      }
    }
    return merged;
  }

  bool _listsEqual(List<UserAddress> a, List<UserAddress> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_addressEquals(a[i], b[i])) return false;
    }
    return true;
  }

  bool _addressEquals(UserAddress a, UserAddress b) {
    return a.id == b.id &&
        a.label == b.label &&
        a.addressLine == b.addressLine &&
        a.neighborhood == b.neighborhood &&
        a.district == b.district &&
        a.city == b.city &&
        a.note == b.note &&
        a.phone == b.phone &&
        a.latitude == b.latitude &&
        a.longitude == b.longitude;
  }

  void _ensureSelected() {
    final list = addresses.value;
    if (list.isEmpty) {
      selected.value = null;
      return;
    }
    final currentId = selected.value?.id;
    final nextSelected =
        list.where((a) => a.id == currentId).firstOrNull ?? list.first;
    selected.value = nextSelected;
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
      selected.value = list.firstOrNull;
    }
    await _persistAll();
  }

  Future<void> select(UserAddress address) async {
    selected.value = address;
    await _persistSelected();
  }

  Future<void> _persistAll({bool pushRemote = true}) async {
    final key = _currentKey;
    if (key == null) return;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final list = addresses.value.map((a) => a.toJson()).toList();
    await prefs.setString(key, jsonEncode(list));
    await _persistSelected();
    if (pushRemote) {
      final email = _currentEmail;
      if (email != null && email.isNotEmpty) {
        unawaited(_api.updateCustomerAddresses(email, list));
      }
    }
  }

  Future<void> _persistSelected() async {
    final key = _currentSelectedKey;
    if (key == null) return;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final selectedId = selected.value?.id;
    if (selectedId == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, selectedId);
    }
  }
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
