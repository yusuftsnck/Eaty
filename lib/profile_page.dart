import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilePage extends StatelessWidget {
  final GoogleSignInAccount user;
  const ProfilePage({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleSignIn.instance.signOut();
      if (context.mounted) {
        Navigator.of(
          context,
        ).popUntil((r) => r.isFirst); // login screen e döner
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Çıkış yapılamadı: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (user.photoUrl != null)
              CircleAvatar(
                radius: 36,
                backgroundImage: NetworkImage(user.photoUrl!),
              )
            else
              const CircleAvatar(radius: 36, child: Icon(Icons.person)),
            const SizedBox(height: 12),
            Text(
              user.displayName ?? 'Adsız Kullanıcı',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
