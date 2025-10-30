import 'dart:async';
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Eaty'e Hoşgeldiniz",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 50),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _signIn,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        _loading
                            ? 'Giriş yapılıyor...'
                            : 'Google ile Giriş Yap',
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
