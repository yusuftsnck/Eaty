import 'package:eatyy/auth_gate.dart';
import 'package:eatyy/models/business_user.dart';
import 'package:eatyy/screens/business/tabs/business_info_page.dart';
import 'package:eatyy/services/api_service.dart';
import 'package:eatyy/services/business_session_service.dart';
import 'package:eatyy/services/customer_session_service.dart';
import 'package:eatyy/services/session_role_service.dart';
import 'package:eatyy/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class BusinessProfilePage extends StatefulWidget {
  final BusinessUser user;
  const BusinessProfilePage({super.key, required this.user});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _api = ApiService();
  late Future<Map<String, dynamic>?> _profileFuture;
  bool? _isOpen;
  bool _statusSaving = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _api.getBusiness(widget.user.email);
    _profileFuture.then((profile) {
      if (!mounted || profile == null) return;
      setState(() => _isOpen = profile['is_open'] ?? true);
    });
  }

  Future<void> _refreshProfile() async {
    final future = _api.getBusiness(widget.user.email);
    setState(() {
      _profileFuture = future;
    });
    final profile = await future;
    if (!mounted || profile == null) return;
    setState(() => _isOpen = profile['is_open'] ?? true);
  }

  Future<void> _toggleEmergencyStatus(bool value) async {
    if (_statusSaving) return;
    setState(() {
      _statusSaving = true;
      _isOpen = value;
    });
    final success = await _api.updateBusinessStatus(widget.user.email, value);
    if (!mounted) return;
    if (!success) {
      setState(() {
        _statusSaving = false;
        _isOpen = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellenemedi.')),
      );
      return;
    }

    setState(() => _statusSaving = false);
    final label = widget.user.category == 'market' ? 'Market' : 'Restoran';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? "$label açıldı" : "$label kapatıldı")),
    );
  }


  Future<void> _signOut(BuildContext context) async {
    try {
      final customer = CustomerSessionService.instance.user.value;
      if (widget.user.isGoogle && customer == null) {
        await GoogleSignIn.instance.signOut();
      }
      await BusinessSessionService.instance.setUser(null);
      await SessionRoleService.instance.setRole(null);
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
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final displayName =
              profile?['name']?.toString() ?? widget.user.name ?? 'İşletme';
          final photoUrl =
              profile?['photo_url']?.toString() ?? widget.user.photoUrl;
          final openValue = _isOpen ?? (profile?['is_open'] as bool?);
          final isOpen = openValue ?? false;
          final statusSubtitle = openValue == null
              ? 'Durum yükleniyor'
              : (isOpen ? 'Şu an açık' : 'Şu an kapalı');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Row(
                children: [
                  ClipOval(
                    child: AppImage(
                      source: photoUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        width: 64,
                        height: 64,
                        color: const Color(0xFFFF7A18),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.user.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              if (snapshot.hasError)
                const Text(
                  'Profil bilgileri alınamadı.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              const _SectionTitle('Hızlı Ayarlar'),
              const SizedBox(height: 10),
              _ProfileToggleTile(
                icon: Icons.power_settings_new,
                title: 'Acil Durum Aç/Kapat',
                subtitle: statusSubtitle,
                value: isOpen,
                enabled: openValue != null && !_statusSaving,
                onChanged: _toggleEmergencyStatus,
              ),
              _ProfileTile(
                icon: Icons.storefront,
                title: 'İşletme bilgileri',
                subtitle: 'Adres, çalışma saatleri',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BusinessInfoPage(user: widget.user),
                    ),
                  );
                  if (!mounted) return;
                  _refreshProfile();
                },
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
          );
        },
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
  final VoidCallback? onTap;
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
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
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ProfileToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
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
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
