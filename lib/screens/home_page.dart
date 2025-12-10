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
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7A18), Color(0xFFE60012)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, padding.top + 12, 20, 18),
              child: Stack(
                children: [
                  Center(
                    child: const Text(
                      'Eaty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.white.withOpacity(0.14),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(user: user),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.account_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),
            _buildCategoryCard(
              context,
              title: "Yemek",
              description: "Restoranlardan sipariş ver",
              icon: Icons.fastfood,
              colors: const [Color(0xFFFEB343), Color(0xFFE43B43)],
              imageUrl:
                  'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=800&q=80',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FoodHomePage()),
                );
              },
            ),
            _buildCategoryCard(
              context,
              title: "Market",
              description: "Taze ürünler kapınızda",
              icon: Icons.local_grocery_store,
              colors: const [
                Color(0xFF28D06C), // Sol - daha açık yeşil
                Color(0xFF009966),
              ],
              imageUrl:
                  'https://images.unsplash.com/photo-1464226184884-fa280b87c399?auto=format&fit=crop&w=800&q=80',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MarketHomePage()),
                );
              },
            ),
            _buildCategoryCard(
              context,
              title: "Tarif",
              description: "Lezzetli tarifler keşfet",
              icon: Icons.menu_book_rounded,
              colors: const [Color(0xFF8B00FF), Color(0xFFFF006C)],
              imageUrl:
                  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecipesHomePage()),
                );
              },
            ),
            SizedBox(height: padding.bottom + 12),
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
  required List<Color> colors,
  required String imageUrl,
  required VoidCallback onTap,
}) {
  final borderRadius = BorderRadius.circular(18);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        height: 200,
        width: 500,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.24),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.08),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.first.withOpacity(0.85),
                        colors.last.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: 60,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.22),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Icon(icon, color: Colors.white, size: 50),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
