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
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors
              .white, // Geri butonu, menü butonu gibi ikonları beyaz yapar
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF7A18), Color(0xFFE60012)], // İstenen renkler
              begin: Alignment.topLeft, // Sol üstten
              end: Alignment.bottomRight, // Sağ alta doğru
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
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.deepOrange,
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
