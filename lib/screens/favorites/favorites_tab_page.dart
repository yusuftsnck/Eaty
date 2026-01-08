import 'package:eatyy/models/user_address.dart';
import 'package:eatyy/screens/addresses/addresses_page.dart';
import 'package:eatyy/screens/food/restaurant_detail_page.dart';
import 'package:eatyy/services/address_service.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/services/favorites_service.dart';
import 'package:eatyy/utils/distance_utils.dart';
import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';

class FavoritesTabPage extends StatelessWidget {
  final String category;
  final String emptyMessage;
  final String customerEmail;
  static final ApiService _api = ApiService();

  const FavoritesTabPage({
    super.key,
    required this.category,
    required this.emptyMessage,
    required this.customerEmail,
  });

  String get _fallbackImage {
    if (category == 'market') {
      return "https://images.unsplash.com/photo-1506617420156-8e4536971650?auto=format&fit=crop&w=800&q=80";
    }
    return "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80";
  }

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

  String _formatRatingText(double? avg, int? count) {
    if (avg == null || (count ?? 0) == 0) return 'Yeni';
    return avg.toStringAsFixed(1);
  }

  bool _isWithinRadius(dynamic biz, UserAddress address) {
    final lat = (biz['latitude'] as num?)?.toDouble();
    final lon = (biz['longitude'] as num?)?.toDouble();
    final radius = (biz['delivery_radius_km'] as num?)?.toDouble();
    if (lat == null || lon == null || radius == null) return false;
    final dist = distanceKm(address.latitude, address.longitude, lat, lon);
    return dist <= radius;
  }

  Widget _buildSelectAddressPrompt(BuildContext context) {
    final buttonColor = category == 'market'
        ? const Color(0xFF009966)
        : Colors.deepOrange;
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
              'Favorileri gormek icin once adres sec.',
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
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Adres Sec'),
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

  Widget _buildBusinessCard(BuildContext context, FavoriteBusiness business) {
    final isOpen = business.isOpen ?? true;
    final label = business.category == 'market' ? 'Market' : 'Restoran';
    final badgeText = isOpen ? label : 'Kapalı';
    final defaultTime = business.category == 'market' ? '20-30 dk' : '30-40 dk';
    final defaultMin = business.category == 'market'
        ? 'Min 80 TL'
        : 'Min 100 TL';
    final timeText = _formatDeliveryTime(
      business.deliveryTimeMins,
      defaultTime,
    );
    final minText = _formatMinOrder(business.minOrderAmount, defaultMin);
    final imageUrl = business.photoUrl;
    final ratingText = _formatRatingText(
      business.ratingAvg,
      business.ratingCount,
    );

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
                  business.name,
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
                        business.address ?? "Adres belirtilmemiş",
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
                    _buildInfoChip(Icons.star, ratingText, Colors.green),
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
          GestureDetector(
            onTap: isOpen
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailPage(
                          businessId: business.id,
                          businessName: business.name,
                          businessEmail: business.email,
                          businessAddress: business.address,
                          businessPhotoUrl: business.photoUrl,
                          category: business.category,
                          isOpen: business.isOpen,
                          minOrderAmount: business.minOrderAmount,
                          deliveryTimeMins: business.deliveryTimeMins,
                          ratingAvg: business.ratingAvg,
                          ratingCount: business.ratingCount,
                          customerEmail: customerEmail,
                        ),
                      ),
                    );
                  }
                : null,
            child: cardContent,
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.white.withOpacity(0.92),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.favorite),
                color: Colors.red,
                onPressed: () =>
                    FavoritesService.instance.toggleFavorite(business),
              ),
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
            future: _api.getBusinessesByCategory(category),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text(emptyMessage));
              }
              final available = snapshot.data!
                  .where((biz) => _isWithinRadius(biz, selected))
                  .toList();
              final availableById = <int, dynamic>{};
              for (final biz in available) {
                final id = (biz['id'] as num?)?.toInt();
                if (id != null) {
                  availableById[id] = biz;
                }
              }
              return ValueListenableBuilder<List<FavoriteBusiness>>(
                valueListenable: FavoritesService.instance.favorites,
                builder: (context, favorites, __) {
                  final byCategory = favorites
                      .where((item) => item.category == category)
                      .toList();
                  if (byCategory.isEmpty) {
                    return Center(child: Text(emptyMessage));
                  }
                  final list = <FavoriteBusiness>[];
                  for (final favorite in byCategory) {
                    final biz = availableById[favorite.id];
                    if (biz == null) continue;
                    list.add(
                      FavoriteBusiness(
                        id: favorite.id,
                        name: (biz['name'] ?? favorite.name).toString(),
                        email: biz['email']?.toString() ?? favorite.email,
                        address: biz['address']?.toString() ?? favorite.address,
                        photoUrl:
                            biz['photo_url']?.toString() ?? favorite.photoUrl,
                        category: category,
                        isOpen: (biz['is_open'] as bool?) ?? favorite.isOpen,
                        minOrderAmount:
                            (biz['min_order_amount'] as num?)?.toDouble() ??
                            favorite.minOrderAmount,
                        deliveryTimeMins:
                            (biz['delivery_time_mins'] as num?)?.toInt() ??
                            favorite.deliveryTimeMins,
                        ratingAvg:
                            (biz['rating_avg'] as num?)?.toDouble() ??
                            favorite.ratingAvg,
                        ratingCount:
                            (biz['rating_count'] as num?)?.toInt() ??
                            favorite.ratingCount,
                      ),
                    );
                  }
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('Secili adres icin favori isletme yok.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final biz = list[index];
                      return _buildBusinessCard(context, biz);
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
