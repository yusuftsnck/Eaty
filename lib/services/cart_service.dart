import 'package:flutter/foundation.dart';

class CartBusiness {
  final int id;
  final String name;
  final String? email;
  final String? address;
  final String? photoUrl;
  final String category;
  final double? minOrderAmount;
  final int? deliveryTimeMins;

  const CartBusiness({
    required this.id,
    required this.name,
    required this.category,
    this.email,
    this.address,
    this.photoUrl,
    this.minOrderAmount,
    this.deliveryTimeMins,
  });
}

class CartItem {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.description,
    this.imageUrl,
  });

  double get total => price * quantity;
}

class CartData {
  final CartBusiness? business;
  final List<CartItem> items;

  const CartData({required this.business, required this.items});

  bool get isEmpty => items.isEmpty;

  double get total =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  CartData copyWith({CartBusiness? business, List<CartItem>? items}) {
    return CartData(
      business: business ?? this.business,
      items: items ?? this.items,
    );
  }
}

class CartService {
  CartService._(this.category);

  final String category;

  static final CartService food = CartService._('food');
  static final CartService market = CartService._('market');

  static CartService ofCategory(String category) {
    return category == 'market' ? market : food;
  }

  final ValueNotifier<CartData> cart =
      ValueNotifier(const CartData(business: null, items: []));

  bool _matchesBusiness(int businessId) {
    final current = cart.value.business;
    return current == null || current.id == businessId;
  }

  bool addItem({required CartBusiness business, required dynamic product}) {
    if (!_matchesBusiness(business.id)) {
      return false;
    }

    final items = List<CartItem>.from(cart.value.items);
    final itemId = (product['id'] as num?)?.toInt();
    final name = (product['name'] ?? '').toString();
    final priceRaw = product['price'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw?.toString() ?? '') ?? 0;
    final imageUrl = product['image_url']?.toString();
    final description = product['description']?.toString();

    final existing = items.indexWhere((item) {
      if (item.id != null && itemId != null) return item.id == itemId;
      return item.name == name;
    });

    if (existing >= 0) {
      items[existing].quantity += 1;
    } else {
      items.add(
        CartItem(
          id: itemId,
          name: name,
          price: price,
          quantity: 1,
          description: description,
          imageUrl: imageUrl,
        ),
      );
    }

    cart.value = cart.value.copyWith(business: business, items: items);
    return true;
  }

  void setQuantity(CartItem item, int quantity) {
    final items = List<CartItem>.from(cart.value.items);
    final index = items.indexWhere((i) => i == item);
    if (index == -1) return;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index].quantity = quantity;
    }
    final business = items.isEmpty ? null : cart.value.business;
    cart.value = cart.value.copyWith(business: business, items: items);
  }

  void removeItem(CartItem item) {
    final items = List<CartItem>.from(cart.value.items);
    items.remove(item);
    final business = items.isEmpty ? null : cart.value.business;
    cart.value = cart.value.copyWith(business: business, items: items);
  }

  void clear() {
    cart.value = const CartData(business: null, items: []);
  }
}
