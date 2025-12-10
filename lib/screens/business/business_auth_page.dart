import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'tabs/business_dashboard_page.dart';

class BusinessAuthPage extends StatefulWidget {
  const BusinessAuthPage({super.key});

  @override
  State<BusinessAuthPage> createState() => _BusinessAuthPageState();
}

class _BusinessAuthPageState extends State<BusinessAuthPage> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final signIn = GoogleSignIn.instance;
      await signIn.initialize();

      GoogleSignInAccount? account = signIn.supportsAuthenticate()
          ? await signIn.authenticate()
          : await signIn.attemptLightweightAuthentication();

      if (account == null) throw Exception('cancelled');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BusinessDashboardPage(user: account)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Google girişi tamamlanamadı. Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF7A18), Color(0xFFE60012)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, padding.top + 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Geri'),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFE6D1),
                                border: Border.all(
                                  color: const Color(0xFFFFAB76),
                                ),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                color: Color(0xFFE85B2B),
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Restoran Paneli',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'İşletmenizi yönetin',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _AuthSwitcher(
                              isLogin: _isLogin,
                              onChanged: (val) =>
                                  setState(() => _isLogin = val),
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isLogin
                                  ? const Padding(
                                      key: ValueKey('login'),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        'Restoran hesabınıza giriş yapın',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : const _RegisterForm(key: ValueKey('reg')),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading
                                    ? null
                                    : _handleGoogleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  side: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: _loading
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Bağlanıyor...'),
                                        ],
                                      )
                                    : Text(
                                        _isLogin
                                            ? 'Google ile Giriş Yap'
                                            : 'Google ile Kayıt Ol',
                                      ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthSwitcher extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;
  const _AuthSwitcher({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTab(
            context,
            title: 'Giriş Yap',
            selected: isLogin,
            value: true,
          ),
          _buildTab(
            context,
            title: 'Kayıt Ol',
            selected: !isLogin,
            value: false,
          ),
        ],
      ),
    );
  }

  Expanded _buildTab(
    BuildContext context, {
    required String title,
    required bool selected,
    required bool value,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.black87 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _LabeledField(label: 'Restoran Adı', hint: 'Lezzet Restaurant'),
        _LabeledField(
          label: 'E-posta',
          hint: 'info@restoran.com',
          keyboardType: TextInputType.emailAddress,
        ),
        _LabeledField(
          label: 'Telefon',
          hint: '0555 123 45 67',
          keyboardType: TextInputType.phone,
        ),
        _LabeledField(label: 'Adres', hint: 'İstanbul, Türkiye'),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  const _LabeledField({
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
