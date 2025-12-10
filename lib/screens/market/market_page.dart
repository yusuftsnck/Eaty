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
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF28D06C), // Sol - daha açık yeşil
                Color(0xFF009966),
                // Color(0xFF45B649), Color(0xFF6DEB70)
              ], // İstenen renkler
              begin: Alignment.topLeft, // Sol üstten
              end: Alignment.bottomRight, // Sağ alta doğru
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors
              .white, // Geri butonu, menü butonu gibi ikonları beyaz yapar
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
        selectedItemColor: Color(0xFF009966),
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
