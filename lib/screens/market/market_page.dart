import 'package:eatyy/screens/market/market_cart_tab_page.dart';
import 'package:eatyy/screens/market/market_home_tab_page.dart';
import 'package:eatyy/screens/market/market_orders_tab_page.dart';
import 'package:flutter/material.dart';

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  int _currentIndex = 0;

  final _titles = const ["Market", "Siparişlerim", "Sepetim"];

  final _pages = const [
    MarketHomeTabPage(),
    MarketOrdersTabPage(),
    MarketCartTabPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex]), centerTitle: true),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (value) => setState(() {
          _currentIndex = value;
        }),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana Sayfa"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_rounded),
            label: "Siparişlerim",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_grocery_store),
            label: "Sepetim",
          ),
        ],
      ),
    );
  }
}
