import 'package:eatyy/services/api_service.dart';
import 'package:flutter/material.dart';
import 'restaurant_detail_page.dart';

class FoodHomeTabPage extends StatefulWidget {
  const FoodHomeTabPage({super.key});

  @override
  State<FoodHomeTabPage> createState() => _FoodHomeTabPageState();
}

class _FoodHomeTabPageState extends State<FoodHomeTabPage> {
  final _api = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<List<dynamic>>(
        future: _api.getBusinessesByCategory("food"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Şu anda açık restoran yok."));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final biz = list[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    // Detay sayfasına git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailPage(
                          businessId: biz['id'],
                          businessName: biz['name'],
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kapak Fotoğrafı (Eğer yoksa placeholder)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          biz['photo_url'] ??
                              "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80",
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 150,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.store, size: 50),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              biz['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  biz['address'] ?? "Adres belirtilmemiş",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
