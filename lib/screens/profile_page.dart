import 'dart:async';
import 'package:eatyy/auth_gate.dart';
import 'package:eatyy/models/app_user.dart';
import 'package:eatyy/screens/addresses/addresses_page.dart';
import 'package:eatyy/screens/profile/user_info_page.dart';
import 'package:eatyy/services/business_session_service.dart';
import 'package:eatyy/services/customer_profile_service.dart';
import 'package:eatyy/services/customer_session_service.dart';
import 'package:eatyy/services/favorites_service.dart';
import 'package:eatyy/services/session_role_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilePage extends StatelessWidget {
  final AppUser user;
  const ProfilePage({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleSignIn.instance.signOut();
      await CustomerSessionService.instance.setUser(null);
      await FavoritesService.instance.setUser(null);
      await CustomerProfileService.instance.setUser(null);
      final business = BusinessSessionService.instance.user.value;
      await SessionRoleService.instance.setRole(
        business == null ? null : 'business',
      );
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
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
    final email = user.email;
    final paddingTop = MediaQuery.of(context).padding.top;

    return ValueListenableBuilder<CustomerProfile?>(
      valueListenable: CustomerProfileService.instance.profile,
      builder: (context, profile, _) {
        final name = profile?.name?.trim().isNotEmpty == true
            ? profile!.name!
            : (user.displayName ?? 'Kullanıcı');
        final phoneText = profile?.formattedPhone;
        final infoLines = [
          name,
          email,
          if (phoneText != null && phoneText.isNotEmpty) phoneText,
        ].join('\n');

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
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

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  children: [
                    _ProfileCard(
                      icon: Icons.person,
                      title: 'Kullanıcı Bilgilerim',
                      subtitle: infoLines,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserInfoPage(user: user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ProfileCard(
                      icon: Icons.location_on,
                      title: 'Adreslerim',
                      subtitle: 'Adreslerini yönet',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressesPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepOrange, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
