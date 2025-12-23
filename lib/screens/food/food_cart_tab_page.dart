import 'package:eatyy/screens/cart/cart_page.dart';
import 'package:flutter/material.dart';

class FoodCartTabPage extends StatelessWidget {
  final VoidCallback? onClose;
  final String? customerEmail;

  const FoodCartTabPage({super.key, this.onClose, this.customerEmail});

  @override
  Widget build(BuildContext context) {
    return CartPage(
      category: 'food',
      onClose: onClose,
      customerEmail: customerEmail,
    );
  }
}
