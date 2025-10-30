import 'package:eatyy/screens/food/food_cart_tab_page.dart';
import 'package:eatyy/screens/food/food_home_tab_page.dart';
import 'package:eatyy/screens/food/food_orders_tab_page.dart';
import 'package:flutter/material.dart';

class FoodHomePage extends StatefulWidget {
  const FoodHomePage({super.key});

  @override
  State<FoodHomePage> createState() => _FoodHomePageState();
}

class _FoodHomePageState extends State<FoodHomePage> {
  int _currentIndex = 0;

  final _titles = const ["Yemek", "Siparişlerim", "Sepetim"];

  final _pages = const [
    FoodHomeTabPage(),
    FoodOrdersTabPage(),
    FoodCartTabPage(),
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
