import 'package:eatyy/screens/orders/customer_orders_page.dart';
import 'package:flutter/material.dart';

class MarketOrdersTabPage extends StatelessWidget {
  final String customerEmail;
  const MarketOrdersTabPage({super.key, required this.customerEmail});

  @override
  Widget build(BuildContext context) {
    return CustomerOrdersPage(
      customerEmail: customerEmail,
      category: 'market',
      accentColor: const Color(0xFF009966),
    );
  }
}
