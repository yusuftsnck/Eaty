import 'package:eatyy/services/api_service.dart';
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
  final _api = ApiService();
  int _currentIndex = 0;
  bool _isOpen = true; // Dükkan durumu

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final biz = await _api.getBusiness(widget.user.email);
    if (biz != null && mounted) {
      setState(() => _isOpen = biz['is_open'] ?? true);
    }
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => _isOpen = value);
    await _api.updateBusinessStatus(widget.user.email, value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? "Restoran AÇILDI" : "Restoran KAPATILDI")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      BusinessDashboardHomePage(user: widget.user),
      BusinessMenuPage(user: widget.user),
      BusinessOrdersPage(user: widget.user),
      BusinessProfilePage(user: widget.user),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        // Üst kısımda "Açık/Kapalı" butonu
        appBar: _currentIndex == 0
            ? AppBar(
                title: const Text("Kontrol Paneli"),
                actions: [
                  Row(
                    children: [
                      Text(
                        _isOpen ? "AÇIK" : "KAPALI",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isOpen ? Colors.green : Colors.red,
                        ),
                      ),
                      Switch(
                        value: _isOpen,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        onChanged: _toggleStatus,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              )
            : null,
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFF7A18),
          unselectedItemColor: Colors.black54,
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
