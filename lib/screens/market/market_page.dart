import 'package:eatyy/models/app_user.dart';
import 'package:eatyy/screens/market/market_cart_tab_page.dart';
import 'package:eatyy/screens/market/market_home_tab_page.dart';
import 'package:eatyy/screens/market/market_orders_tab_page.dart';
import 'package:eatyy/screens/favorites/favorites_tab_page.dart';
import 'package:flutter/material.dart';

class MarketHomePage extends StatefulWidget {
  final AppUser user;
  const MarketHomePage({super.key, required this.user});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final _titles = const ["Market", "Favorilerim", "Siparişlerim", "Sepetim"];

  List<Widget> get _pages => [
    MarketHomeTabPage(customerEmail: widget.user.email),
    FavoritesTabPage(
      category: 'market',
      emptyMessage: 'Henüz favori market yok.',
      customerEmail: widget.user.email,
    ),
    MarketOrdersTabPage(customerEmail: widget.user.email),
    MarketCartTabPage(onClose: _closeCart, customerEmail: widget.user.email),
  ];

  void _closeCart() {
    setState(() {
      _currentIndex = _previousIndex;
    });
  }

  void _handleTab(int value) {
    setState(() {
      if (value == 3) {
        _previousIndex = _currentIndex;
        _currentIndex = value;
      } else {
        _currentIndex = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentIndex == 3
          ? null
          : AppBar(
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF28D06C), Color(0xFF009966)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                _titles[_currentIndex],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _currentIndex == 3
          ? null
          : BottomNavigationBar(
              selectedItemColor: Color(0xFF009966),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              currentIndex: _currentIndex,
              onTap: _handleTab,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Ana Sayfa",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: "Favorilerim",
                ),
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
