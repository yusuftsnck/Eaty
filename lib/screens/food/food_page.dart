import 'package:eatyy/models/app_user.dart';
import 'package:eatyy/screens/food/food_cart_tab_page.dart';
import 'package:eatyy/screens/food/food_home_tab_page.dart';
import 'package:eatyy/screens/food/food_orders_tab_page.dart';
import 'package:eatyy/screens/favorites/favorites_tab_page.dart';
import 'package:flutter/material.dart';

class FoodHomePage extends StatefulWidget {
  final AppUser user;
  const FoodHomePage({super.key, required this.user});

  @override
  State<FoodHomePage> createState() => _FoodHomePageState();
}

class _FoodHomePageState extends State<FoodHomePage> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final _titles = const ["Yemek", "Favorilerim", "Siparişlerim", "Sepetim"];

  List<Widget> get _pages => [
    FoodHomeTabPage(customerEmail: widget.user.email),
    FavoritesTabPage(
      category: 'food',
      emptyMessage: 'Henüz favori restoran yok.',
      customerEmail: widget.user.email,
    ),
    FoodOrdersTabPage(customerEmail: widget.user.email),
    FoodCartTabPage(onClose: _closeCart, customerEmail: widget.user.email),
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
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF7A18), Color(0xFFE60012)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
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
              selectedItemColor: Colors.deepOrange,
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
                  icon: Icon(Icons.receipt_long),
                  label: "Siparişlerim",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_rounded),
                  label: "Sepetim",
                ),
              ],
            ),
    );
  }
}
