import 'package:eatyy/screens/food/food_page.dart';
import 'package:eatyy/screens/market/market_page.dart';
import 'package:eatyy/screens/profile_page.dart';
import 'package:eatyy/screens/recipes/recipes_home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatelessWidget {
  final GoogleSignInAccount user;
  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Eaty',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(user: user)),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            _buildCategoryCard(
              context,
              title: "Yemek",
              description: "restoranları keşfet",
              icon: Icons.fastfood,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FoodHomePage()),
                );
              },
            ),
            SizedBox(height: 10),

            _buildCategoryCard(
              context,
              title: "Market",
              description: "market keşfet",
              icon: Icons.local_grocery_store,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MarketHomePage()),
                );
              },
            ),
            SizedBox(height: 10),

            _buildCategoryCard(
              context,
              title: "Tarif",
              description: "tarif keşfet",
              icon: Icons.menu_book_rounded,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecipesHomePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCategoryCard(
  BuildContext context, {
  required String title,
  required String description,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white70,
        ),
        padding: const EdgeInsets.all(50),
        child: Row(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Icon(icon, color: color, size: 90),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
