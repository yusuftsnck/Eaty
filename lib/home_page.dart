import 'package:eatyy/food_home_page.dart';
import 'package:eatyy/market_home_page.dart';
import 'package:eatyy/profile_page.dart';
import 'package:eatyy/recipes_home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatelessWidget {
  final GoogleSignInAccount user;
  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body: ListView(
        children: [
          _buildCategoryCard(
            context,
            title: "Yemek",
            description: "restoranları keşfet",
            icon: Icons.fastfood,
            color: Colors.orange.shade300,
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
            color: Colors.green.shade300,
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
            color: Colors.purple.shade300,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecipesHomePage()),
              );
            },
          ),
        ],
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
    borderRadius: BorderRadius.circular(50),
    child: Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color,
        ),
        padding: const EdgeInsets.all(70),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(icon, color: color, size: 50),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
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
