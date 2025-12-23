import 'package:eatyy/screens/orders/customer_orders_page.dart';
import 'package:flutter/material.dart';

class FoodOrdersTabPage extends StatelessWidget {
  final String customerEmail;
  const FoodOrdersTabPage({super.key, required this.customerEmail});

  @override
  Widget build(BuildContext context) {
    return CustomerOrdersPage(
      customerEmail: customerEmail,
      category: 'food',
      accentColor: const Color(0xFFE53935),
    );
  }
}
