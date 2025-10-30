import 'package:flutter/material.dart';

class RecipesHomePage extends StatelessWidget {
  const RecipesHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tarifler')),
      body: Center(child: Text("Listelenen Tarifler")),
    );
  }
}
