import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilePage extends StatelessWidget {
  final GoogleSignInAccount user;
  const ProfilePage({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleSignIn.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
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
    final name = user.displayName ?? 'Kullanıcı';
    final email = user.email;
    final paddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ÜST GRADIENT ALAN
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0BA360), Color(0xFF3CBA92)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, paddingTop + 12, 20, 24),
            child: Column(
              children: [
                // geri butonu + başlık
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text(
                      'Profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 48), // dengeleme
                  ],
                ),
                const SizedBox(height: 16),
                // avatar + isim + mail ORTADA
                Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.28),
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ORTADAKİ BOŞ ALAN (ileride ayarlar vs. koyarsın)
          const Spacer(),

          // ALTTA SABİT ÇIKIŞ BUTONU
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Material(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _signOut(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Çıkış Yap',
                        style: TextStyle(
                          color: Color(0xFFE60012),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
