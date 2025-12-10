import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'business_dashboard_home_page.dart';
import 'business_menu_page.dart';
import 'business_orders_page.dart';
import 'business_profile_page.dart';

class BusinessDashboardPage extends StatefulWidget {
  final GoogleSignInAccount user;
  const BusinessDashboardPage({super.key, required this.user});

  @override
  State<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      BusinessDashboardHomePage(user: widget.user),
      const BusinessMenuPage(),
      const BusinessOrdersPage(),
      BusinessProfilePage(user: widget.user),
    ];

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: IndexedStack(index: _currentIndex, children: pages),

        /// ---------------------------
        ///   BOTTOM NAVIGATION BAR
        /// ---------------------------
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),

          type: BottomNavigationBarType.fixed,
          elevation: 12,

          backgroundColor: Colors.white,

          selectedItemColor: const Color(0xFFFF7A18), // Turuncu
          unselectedItemColor: Colors.black54,

          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ana sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: 'Menü',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Siparişler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
