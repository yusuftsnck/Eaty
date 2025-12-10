import 'package:eatyy/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class BusinessProfilePage extends StatelessWidget {
  final GoogleSignInAccount user;
  const BusinessProfilePage({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleSignIn.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Çıkış yapılamadı: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFFF7A18),
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 34)
                    : null,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Restoran',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Hızlı Ayarlar'),
          const SizedBox(height: 10),
          const _ProfileTile(
            icon: Icons.storefront,
            title: 'Restoran bilgileri',
            subtitle: 'Adres, çalışma saatleri',
          ),
          const _ProfileTile(
            icon: Icons.local_offer_outlined,
            title: 'Kampanyalar',
            subtitle: 'İndirimler ve kuponlar',
          ),
          const _ProfileTile(
            icon: Icons.notifications_none,
            title: 'Bildirimler',
            subtitle: 'Anlık sipariş uyarıları',
          ),
          const _ProfileTile(
            icon: Icons.security,
            title: 'Güvenlik',
            subtitle: 'Giriş ve yetkiler',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _signOut(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Çıkış yap', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E6),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: const Color(0xFFE85B2B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }
}
