import 'package:flutter/material.dart';

class FoodHomePage extends StatelessWidget {
  const FoodHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Restoranlar')),
      body: Center(child: Text("Listelenen Restoranlar")),
    );
  }
}
