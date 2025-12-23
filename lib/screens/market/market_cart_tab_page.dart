import 'package:eatyy/screens/cart/cart_page.dart';
import 'package:flutter/material.dart';

class MarketCartTabPage extends StatelessWidget {
  final VoidCallback? onClose;
  final String? customerEmail;

  const MarketCartTabPage({super.key, this.onClose, this.customerEmail});

  @override
  Widget build(BuildContext context) {
    return CartPage(
      category: 'market',
      onClose: onClose,
      customerEmail: customerEmail,
    );
  }
}
