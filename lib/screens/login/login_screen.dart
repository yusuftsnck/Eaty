import 'dart:async';
import 'package:eatyy/screens/business/business_auth_page.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;
  Timer? _failsafe;
  @override
  void dispose() {
    _failsafe?.cancel();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    unawaited(
      () async {
        try {
          if (GoogleSignIn.instance.supportsAuthenticate()) {
            await GoogleSignIn.instance.authenticate();
          } else {
            final acc = await GoogleSignIn.instance
                .attemptLightweightAuthentication();
            if (acc == null) {
              throw Exception('interactive_required');
            }
          }
        } catch (_) {}
      }().whenComplete(() {
        _failsafe?.cancel();
        if (mounted) setState(() => _loading = false);
      }),
    );

    _failsafe = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF7A18),
              Color(0xFFE60012),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12),
                  child: Material(
                    color: Colors.white.withOpacity(0.14),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BusinessAuthPage()),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.store, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.14),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Eaty',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hoş Geldiniz',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 42),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                              elevation: 3,
                            ),
                            child: _loading
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                      Text('Giriş yapılıyor...'),
                                    ],
                                  )
                                : const Text('Google ile Giriş Yap'),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 22),
                        const Text(
                          'Giriş yaparak kullanım şartlarını kabul etmiş olursunuz',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
