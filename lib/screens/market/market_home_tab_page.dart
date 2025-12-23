import 'package:eatyy/screens/food/restaurant_detail_page.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/services/address_service.dart';
import 'package:eatyy/services/cart_service.dart';
import 'package:eatyy/services/favorites_service.dart';
import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:eatyy/models/user_address.dart';
import 'package:eatyy/screens/addresses/addresses_page.dart';
import 'package:eatyy/utils/distance_utils.dart';

class MarketHomeTabPage extends StatefulWidget {
  final String customerEmail;
  const MarketHomeTabPage({super.key, required this.customerEmail});

  @override
  State<MarketHomeTabPage> createState() => _MarketHomeTabPageState();
}

class _MarketHomeTabPageState extends State<MarketHomeTabPage> {
  final _api = ApiService();
  final _favorites = FavoritesService.instance;
  final _cartService = CartService.ofCategory('market');
  final _fallbackImage =
      "https://images.unsplash.com/photo-1506617420156-8e4536971650?auto=format&fit=crop&w=800&q=80";

  String _formatMinOrder(double? amount, String fallback) {
    if (amount == null) return fallback;
    final value = amount.truncateToDouble() == amount
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return 'Min $value TL';
  }

  String _formatDeliveryTime(int? minutes, String fallback) {
    if (minutes == null) return fallback;
    return '$minutes dk';
  }

  bool _isWithinRadius(dynamic biz, UserAddress address) {
    final lat = (biz['latitude'] as num?)?.toDouble();
    final lon = (biz['longitude'] as num?)?.toDouble();
    final radius = (biz['delivery_radius_km'] as num?)?.toDouble();
    if (lat == null || lon == null || radius == null) return false;
    final dist = distanceKm(address.latitude, address.longitude, lat, lon);
    return dist <= radius;
  }

  void _maybeClearCart(List<dynamic> list) {
    final cart = _cartService.cart.value;
    final business = cart.business;
    if (cart.isEmpty || business == null) return;
    final exists = list.any(
      (biz) => (biz['id'] as num?)?.toInt() == business.id,
    );
    if (exists) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = _cartService.cart.value.business;
      if (current?.id == business.id) {
        _cartService.clear();
      }
    });
  }

  Widget _buildSelectAddressPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'Marketleri görmek için önce adres seç.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressesPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009966),
                foregroundColor: Colors.white,
              ),
              child: const Text('Adres Seç'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(
    BuildContext context,
    FavoriteBusiness favorite, {
    required VoidCallback? onTap,
  }) {
    final isOpen = favorite.isOpen ?? true;
    final label = favorite.category == 'market' ? 'Market' : 'Restoran';
    final badgeText = isOpen ? label : 'Kapalı';
    final defaultTime = favorite.category == 'market' ? '20-30 dk' : '30-40 dk';
    final defaultMin = favorite.category == 'market'
        ? 'Min 80 TL'
        : 'Min 100 TL';
    final timeText = _formatDeliveryTime(
      favorite.deliveryTimeMins,
      defaultTime,
    );
    final minText = _formatMinOrder(favorite.minOrderAmount, defaultMin);
    final imageUrl = favorite.photoUrl;

    final cardColor = isOpen ? Colors.white : Colors.grey.shade200;
    Widget heroImage = AppImage(
      source: imageUrl,
      fallback: _fallbackImage,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
    );
    if (!isOpen) {
      heroImage = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: heroImage,
      );
    }

    final cardContent = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                heroImage,
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.35),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(left: 12, top: 12, child: _buildBadge(badgeText)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favorite.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        favorite.address ?? "Adres belirtilmemiş",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(Icons.star, '4.3', Colors.green),
                    _buildInfoChip(
                      Icons.timer_outlined,
                      timeText,
                      Colors.orange,
                    ),
                    _buildInfoChip(
                      Icons.shopping_bag_outlined,
                      minText,
                      Colors.blueGrey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          GestureDetector(onTap: isOpen ? onTap : null, child: cardContent),
          Positioned(
            top: 10,
            right: 10,
            child: ValueListenableBuilder<List<FavoriteBusiness>>(
              valueListenable: _favorites.favorites,
              builder: (context, favorites, _) {
                final isFavorite = favorites.any(
                  (item) => item.id == favorite.id,
                );
                return Material(
                  color: Colors.white.withOpacity(0.92),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    color: isFavorite ? Colors.red : Colors.black54,
                    onPressed: () => _favorites.toggleFavorite(favorite),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: ValueListenableBuilder<UserAddress?>(
        valueListenable: AddressService.instance.selected,
        builder: (context, selected, _) {
          if (selected == null) {
            return _buildSelectAddressPrompt(context);
          }
          return FutureBuilder<List<dynamic>>(
            future: _api.getBusinessesByCategory("market"),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Hata: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Şu anda açık market yok."));
              }

              final list = snapshot.data!
                  .where((biz) => _isWithinRadius(biz, selected))
                  .toList();
              _maybeClearCart(list);
              if (list.isEmpty) {
                return const Center(
                  child: Text('Seçili adres için market bulunamadı.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final biz = list[index];
                  final isOpen = (biz['is_open'] as bool?) ?? true;
                  final favorite = FavoriteBusiness(
                    id: (biz['id'] as num).toInt(),
                    name: (biz['name'] ?? '').toString(),
                    email: biz['email']?.toString(),
                    address: biz['address']?.toString(),
                    photoUrl: biz['photo_url']?.toString(),
                    category: 'market',
                    isOpen: isOpen,
                    minOrderAmount: (biz['min_order_amount'] as num?)
                        ?.toDouble(),
                    deliveryTimeMins: (biz['delivery_time_mins'] as num?)
                        ?.toInt(),
                  );
                  return _buildBusinessCard(
                    context,
                    favorite,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailPage(
                            businessId: favorite.id,
                            businessName: favorite.name,
                            businessEmail: favorite.email,
                            businessAddress: favorite.address,
                            businessPhotoUrl: favorite.photoUrl,
                            category: favorite.category,
                            isOpen: favorite.isOpen,
                            minOrderAmount: favorite.minOrderAmount,
                            deliveryTimeMins: favorite.deliveryTimeMins,
                            customerEmail: widget.customerEmail,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
