import 'package:flutter/material.dart';

class MarketHomePage extends StatelessWidget {
  const MarketHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Marketler')),
      body: Center(child: Text("Listelenen Marketler")),
    );
  }
}
