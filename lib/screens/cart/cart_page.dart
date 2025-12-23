import 'package:eatyy/screens/cart/checkout_page.dart';
import 'package:eatyy/services/cart_service.dart';
import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  final String category;
  final VoidCallback? onClose;
  final String? customerEmail;

  const CartPage({
    super.key,
    required this.category,
    this.onClose,
    this.customerEmail,
  });

  Color get _headerColor =>
      category == 'market' ? const Color(0xFF009966) : const Color(0xFFE53935);

  String _formatPrice(double value) {
    final isWhole = value.truncateToDouble() == value;
    return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  String _formatMinOrder(double? amount, String fallback) {
    if (amount == null) return fallback;
    final text = amount.truncateToDouble() == amount
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return 'Min $text TL';
  }

  @override
  Widget build(BuildContext context) {
    final email = customerEmail;
    final cartService = CartService.ofCategory(category);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _headerColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose ?? () => Navigator.pop(context),
        ),
        title: const Text('Sepetim'),
      ),
      body: ValueListenableBuilder<CartData>(
        valueListenable: cartService.cart,
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(
              child: Text(
                'Sepetin boş',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }
          final business = cart.business!;
          final defaultMin = category == 'market' ? 'Min 80 TL' : 'Min 100 TL';
          final minText = _formatMinOrder(business.minOrderAmount, defaultMin);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _BusinessCard(business: business, minText: minText),
              const SizedBox(height: 16),
              for (final item in cart.items)
                _CartItemRow(item: item, cartService: cartService),
            ],
          );
        },
      ),
      bottomNavigationBar: ValueListenableBuilder<CartData>(
        valueListenable: cartService.cart,
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Toplam Tutar',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      Text(
                        '${_formatPrice(cart.total)} TL',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _headerColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(
                              category: category,
                              customerEmail: email,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Sepeti Onayla',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

class _BusinessCard extends StatelessWidget {
  final CartBusiness business;
  final String minText;

  const _BusinessCard({required this.business, required this.minText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppImage(
              source: business.photoUrl,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              placeholder: Container(
                width: 58,
                height: 58,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.storefront),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (business.address != null &&
                    business.address!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    business.address!,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Ücretsiz Teslimat • $minText',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade100,
            ),
            child: const Icon(Icons.chevron_right, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final CartService cartService;

  const _CartItemRow({required this.item, required this.cartService});

  String _formatPrice(double value) {
    final isWhole = value.truncateToDouble() == value;
    return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (item.description != null && item.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.description!,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${_formatPrice(item.price)} TL',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          _QuantityStepper(item: item, cartService: cartService),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final CartItem item;
  final CartService cartService;

  const _QuantityStepper({required this.item, required this.cartService});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE55A3B), width: 1.5),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onPressed: () {
              cartService.setQuantity(item, item.quantity - 1);
            },
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              item.quantity.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onPressed: () {
              cartService.setQuantity(item, item.quantity + 1);
            },
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepperButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0xFFE55A3B)),
      ),
    );
  }
}
