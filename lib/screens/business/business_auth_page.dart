import 'package:flutter/material.dart';

class BusinessAuthPage extends StatelessWidget {
  const BusinessAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("İşletme Giriş/Kayıt"), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 120),
                FilledButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.login),
                  label: Text("Google ile Giriş"),
                ),
                SizedBox(height: 30),
                Text("Henüz Hesabın Yok Mu?"),
                TextButton(
                  onPressed: () {},
                  child: Text("İşletmeni Eaty'ye Taşı"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
