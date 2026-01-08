import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteBusiness {
  final int id;
  final String name;
  final String? email;
  final String? address;
  final String? photoUrl;
  final String category;
  final bool? isOpen;
  final double? minOrderAmount;
  final int? deliveryTimeMins;
  final double? ratingAvg;
  final int? ratingCount;

  const FavoriteBusiness({
    required this.id,
    required this.name,
    required this.category,
    this.email,
    this.address,
    this.photoUrl,
    this.isOpen,
    this.minOrderAmount,
    this.deliveryTimeMins,
    this.ratingAvg,
    this.ratingCount,
  });

  factory FavoriteBusiness.fromJson(Map<String, dynamic> json) {
    return FavoriteBusiness(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      category: (json['category'] ?? 'food').toString(),
      isOpen: json['is_open'] as bool?,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble(),
      deliveryTimeMins: (json['delivery_time_mins'] as num?)?.toInt(),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'photo_url': photoUrl,
      'category': category,
      'is_open': isOpen,
      'min_order_amount': minOrderAmount,
      'delivery_time_mins': deliveryTimeMins,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
    };
  }
}

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  final ValueNotifier<List<FavoriteBusiness>> favorites = ValueNotifier([]);
  SharedPreferences? _prefs;
  String? _currentKey;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setUser(String? email) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (email == null || email.trim().isEmpty) {
      _currentKey = null;
      favorites.value = [];
      return;
    }
    final key = _buildKey(email);
    if (_currentKey == key) return;
    _currentKey = key;
    await _loadFromPrefs(key);
  }

  String _buildKey(String email) {
    final safe = Uri.encodeComponent(email.trim().toLowerCase());
    return 'favorite_businesses_$safe';
  }

  Future<void> _loadFromPrefs(String key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      favorites.value = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final list = <FavoriteBusiness>[];
        for (final item in decoded) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final favorite = FavoriteBusiness.fromJson(map);
            if (favorite.id > 0) {
              list.add(favorite);
            }
          }
        }
        favorites.value = list;
      }
    } catch (_) {}
  }

  bool isFavorite(int id) {
    return favorites.value.any((item) => item.id == id);
  }

  void toggleFavorite(FavoriteBusiness business) {
    final list = List<FavoriteBusiness>.from(favorites.value);
    final index = list.indexWhere((item) => item.id == business.id);
    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.insert(0, business);
    }
    favorites.value = list;
    _save();
  }

  List<FavoriteBusiness> byCategory(String category) {
    return favorites.value.where((item) => item.category == category).toList();
  }

  Future<void> _save() async {
    final key = _currentKey;
    if (key == null) return;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final payload = favorites.value.map((item) => item.toJson()).toList();
    await prefs.setString(key, jsonEncode(payload));
  }
}
