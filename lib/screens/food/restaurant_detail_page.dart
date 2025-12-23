import 'package:eatyy/screens/cart/cart_page.dart';
import 'package:eatyy/screens/food/restaurant_info_page.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/services/cart_service.dart';
import 'package:eatyy/services/favorites_service.dart';
import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';

class RestaurantDetailPage extends StatefulWidget {
  final int businessId;
  final String businessName;
  final String? businessEmail;
  final String? businessAddress;
  final String? businessPhotoUrl;
  final String category;
  final bool? isOpen;
  final double? minOrderAmount;
  final int? deliveryTimeMins;
  final String? customerEmail;
  const RestaurantDetailPage({
    super.key,
    required this.businessId,
    required this.businessName,
    this.businessEmail,
    this.businessAddress,
    this.businessPhotoUrl,
    this.category = 'food',
    this.isOpen,
    this.minOrderAmount,
    this.deliveryTimeMins,
    this.customerEmail,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final _api = ApiService();
  List<dynamic> _menu = [];
  bool _loading = true;
  String _searchQuery = '';
  Map<String, dynamic>? _profile;
  bool _profileLoading = false;

  CartService get _cartService => CartService.ofCategory(widget.category);

  List<dynamic> get _filteredMenu {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _menu;
    return _menu.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final desc = (item['description'] ?? '').toString().toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadProfile();
  }

  Future<void> _loadMenu() async {
    final items = await _api.getMenu(widget.businessId);
    if (mounted) {
      setState(() {
        _menu = items;
        _loading = false;
      });
    }
  }

  Future<void> _addToCart(dynamic product) async {
    final business = CartBusiness(
      id: widget.businessId,
      name: widget.businessName,
      email: widget.businessEmail,
      address:
          _profile?['open_address']?.toString() ??
          _profile?['address']?.toString() ??
          widget.businessAddress,
      photoUrl: _profile?['photo_url']?.toString() ?? widget.businessPhotoUrl,
      category: widget.category,
      minOrderAmount:
          (_profile?['min_order_amount'] as num?)?.toDouble() ??
          widget.minOrderAmount,
      deliveryTimeMins:
          (_profile?['delivery_time_mins'] as num?)?.toInt() ??
          widget.deliveryTimeMins,
    );

    final added = _cartService.addItem(business: business, product: product);

    if (!added) {
      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sepet dolu'),
          content: const Text(
            'Sepetinizde başka işletme ürünleri var. Yeni ürünleri eklemek için sepeti temizleyelim mi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Temizle'),
            ),
          ],
        ),
      );
      if (shouldClear == true) {
        _cartService.clear();
        _cartService.addItem(business: business, product: product);
      } else {
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sepete eklendi'),
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _loadProfile() async {
    final email = widget.businessEmail;
    if (email == null || email.trim().isEmpty) return;
    setState(() => _profileLoading = true);
    final profile = await _api.getBusiness(email);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _profileLoading = false;
    });
  }

  String _formatPrice(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null) return '0 TL';
    final isWhole = parsed.truncateToDouble() == parsed;
    final text = isWhole
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(2);
    return '$text TL';
  }

  void _showInfoSheet() {
    final email = widget.businessEmail;
    if (email == null || email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoran bilgisi bulunamadı.')),
      );
      return;
    }
    if (_profileLoading) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bilgiler yükleniyor.')));
      return;
    }
    final profile = _profile;
    if (profile == null) {
      _loadProfile();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bilgiler yükleniyor.')));
      return;
    }
    final address =
        profile['open_address']?.toString().trim().isNotEmpty == true
        ? profile['open_address']?.toString()
        : profile['address']?.toString() ?? 'Adres belirtilmemiş';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantInfoPage(
          name: widget.businessName,
          ownerName: profile['authorized_name']?.toString(),
          ownerSurname: profile['authorized_surname']?.toString(),
          address: address!,
          phone: profile['phone']?.toString(),
          workingHours: profile['working_hours']?.toString(),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(dynamic item) {
    final name = (item['name'] ?? '').toString();
    final desc = (item['description'] ?? '').toString();
    final imageUrl = item['image_url']?.toString();
    final price = _formatPrice(item['price']);
    final oldPriceRaw = item['old_price'];
    final hasOldPrice =
        oldPriceRaw != null && oldPriceRaw.toString().trim().isNotEmpty;
    final oldPrice = hasOldPrice ? _formatPrice(oldPriceRaw) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _addToCart(item),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (oldPrice != null) ...[
                      Text(
                        oldPrice,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppImage(
            source: imageUrl,
            width: 74,
            height: 74,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
            placeholder: Container(
              width: 74,
              height: 74,
              color: Colors.grey.shade200,
              child: const Icon(Icons.fastfood),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMarket = widget.category == 'market';
    final label = isMarket ? 'Market' : 'Restoran';
    final deliveryMins =
        (_profile?['delivery_time_mins'] as num?)?.toInt() ??
        widget.deliveryTimeMins;
    final minAmount =
        (_profile?['min_order_amount'] as num?)?.toDouble() ??
        widget.minOrderAmount;
    final timeText = deliveryMins != null
        ? '$deliveryMins dk'
        : (isMarket ? '20-30 dk' : '30-40 dk');
    final minText = minAmount != null
        ? 'Min ${_formatPrice(minAmount).replaceAll(' TL', '')} TL'
        : (isMarket ? 'Min 80 TL' : 'Min 100 TL');
    final address =
        _profile?['open_address']?.toString() ??
        _profile?['address']?.toString() ??
        widget.businessAddress ??
        'Adres belirtilmemiş';
    final fallbackImage = isMarket
        ? "https://images.unsplash.com/photo-1506617420156-8e4536971650?auto=format&fit=crop&w=800&q=80"
        : "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80";
    final heroImage = widget.businessPhotoUrl ?? fallbackImage;
    final menuItems = _filteredMenu;
    final menuWidgets = <Widget>[];
    for (int i = 0; i < menuItems.length; i++) {
      final item = menuItems[i];
      final category = item['category']?.toString();
      final prevCategory = i > 0
          ? menuItems[i - 1]['category']?.toString()
          : null;
      if (category != null && category.isNotEmpty && category != prevCategory) {
        menuWidgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.deepOrange.shade800,
              ),
            ),
          ),
        );
      }
      menuWidgets.add(_buildMenuItem(item));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.white.withOpacity(0.9),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Colors.white.withOpacity(0.9),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.black87),
                    onPressed: _showInfoSheet,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.white.withOpacity(0.9),
                  shape: const CircleBorder(),
                  child: ValueListenableBuilder<List<FavoriteBusiness>>(
                    valueListenable: FavoritesService.instance.favorites,
                    builder: (context, favorites, _) {
                      final isFavorite = favorites.any(
                        (item) => item.id == widget.businessId,
                      );
                      final favorite = FavoriteBusiness(
                        id: widget.businessId,
                        name: widget.businessName,
                        email: widget.businessEmail,
                        address: address,
                        photoUrl:
                            _profile?['photo_url']?.toString() ??
                            widget.businessPhotoUrl,
                        category: widget.category,
                        isOpen: widget.isOpen,
                        minOrderAmount: minAmount,
                        deliveryTimeMins: deliveryMins,
                      );
                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                        ),
                        color: isFavorite ? Colors.red : Colors.black54,
                        onPressed: () =>
                            FavoritesService.instance.toggleFavorite(favorite),
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    source: heroImage,
                    fallback: fallbackImage,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.businessName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              address,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F6EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.star, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              '4.3',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '250+',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$label Teslimatı',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$timeText · Ücretsiz Teslimat · $minText',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: isMarket
                          ? 'Market içinde ara'
                          : 'Restoranda ara',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
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
                      _buildInfoChip(Icons.star, '4.3', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (menuItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _searchQuery.trim().isEmpty
                      ? "Bu işletmenin menüsü henüz yok."
                      : "Aradığınız ürün bulunamadı.",
                ),
              ),
            )
          else
            SliverSafeArea(
              top: false,
              bottom: true,
              minimum: const EdgeInsets.only(bottom: 50),
              sliver: SliverList(
                delegate: SliverChildListDelegate(menuWidgets),
              ),
            ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<CartData>(
        valueListenable: _cartService.cart,
        builder: (context, cart, _) {
          final currentBusiness = cart.business;
          if (cart.isEmpty || currentBusiness?.id != widget.businessId) {
            return const SizedBox.shrink();
          }
          final buttonColor = widget.category == 'market'
              ? Colors.green
              : Colors.deepOrange;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Toplam Tutar",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        _formatPrice(cart.total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: buttonColor,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartPage(
                            category: widget.category,
                            customerEmail: widget.customerEmail,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Sepete Git",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
