import 'dart:async';
import 'package:eatyy/screens/home_page.dart';
import 'package:eatyy/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;
  GoogleSignInAccount? _user;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final signIn = GoogleSignIn.instance;

    await signIn.initialize();

    _sub =
        signIn.authenticationEvents.listen((event) {
          if (!mounted) return;
          if (event is GoogleSignInAuthenticationEventSignIn) {
            setState(() => _user = event.user);
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            setState(() => _user = null);
          }
        })..onError((Object error, StackTrace st) {
          if (!mounted) return;
          setState(() {});
        });

    try {
      final previous = await signIn.attemptLightweightAuthentication();
      setState(() {
        _user = previous;
        _initialized = true;
      });
    } catch (_) {
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _user == null ? const LoginScreen() : HomePage(user: _user!);
  }
}
