import 'dart:async';
import 'package:eatyy/models/app_user.dart';
import 'package:eatyy/screens/home_page.dart';
import 'package:eatyy/screens/login/login_screen.dart';
import 'package:eatyy/screens/business/business_auth_page.dart';
import 'package:eatyy/screens/business/tabs/business_dashboard_page.dart';
import 'package:eatyy/services/address_service.dart';
import 'package:eatyy/services/business_session_service.dart';
import 'package:eatyy/services/customer_profile_service.dart';
import 'package:eatyy/services/customer_session_service.dart';
import 'package:eatyy/services/favorites_service.dart';
import 'package:eatyy/services/session_role_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;
  AppUser? _user;
  String? _role;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _sub;

  void _handleRoleChange() {
    if (!mounted) return;
    setState(() => _role = SessionRoleService.instance.role.value);
  }

  @override
  void initState() {
    super.initState();
    SessionRoleService.instance.role.addListener(_handleRoleChange);
    _init();
  }

  Future<void> _init() async {
    final signIn = GoogleSignIn.instance;

    await signIn.initialize();

    _sub =
        signIn.authenticationEvents.listen((event) async {
          if (!mounted) return;
          final businessUser = BusinessSessionService.instance.user.value;
          final activeRole = SessionRoleService.instance.role.value;
          if (event is GoogleSignInAuthenticationEventSignIn) {
            if (activeRole == 'business') {
              if (!mounted) return;
              setState(() => _role = activeRole);
              return;
            }
            final appUser = AppUser(
              email: event.user.email,
              displayName: event.user.displayName,
              photoUrl: event.user.photoUrl,
            );
            await CustomerSessionService.instance.setUser(appUser);
            await FavoritesService.instance.setUser(appUser.email);
            await CustomerProfileService.instance.setUser(appUser.email);
            await AddressService.instance.setUser(appUser.email);
            if (activeRole != 'business') {
              await SessionRoleService.instance.setRole('customer');
            }
            if (!mounted) return;
            setState(() {
              _user = appUser;
              _role = SessionRoleService.instance.role.value;
            });
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            await CustomerSessionService.instance.setUser(null);
            await FavoritesService.instance.setUser(null);
            await CustomerProfileService.instance.setUser(null);
            await AddressService.instance.setUser(null);
            if (businessUser == null) {
              await SessionRoleService.instance.setRole(null);
            } else {
              await SessionRoleService.instance.setRole('business');
            }
            if (!mounted) return;
            setState(() {
              _user = null;
              _role = SessionRoleService.instance.role.value;
            });
          }
        })..onError((Object error, StackTrace st) {
          if (!mounted) return;
          setState(() {});
        });

    try {
      _role = SessionRoleService.instance.role.value;
      final previous = await signIn.attemptLightweightAuthentication();
      if (previous != null) {
        final appUser = AppUser(
          email: previous.email,
          displayName: previous.displayName,
          photoUrl: previous.photoUrl,
        );
        await CustomerSessionService.instance.setUser(appUser);
        await FavoritesService.instance.setUser(appUser.email);
        await CustomerProfileService.instance.setUser(appUser.email);
        await AddressService.instance.setUser(appUser.email);
        if (_role != 'business' && _role != null) {
          await SessionRoleService.instance.setRole('customer');
          _role = 'customer';
        }
        setState(() {
          _user = appUser;
          _initialized = true;
        });
      } else {
        final cached = CustomerSessionService.instance.user.value;
        if (cached != null) {
          await FavoritesService.instance.setUser(cached.email);
          await CustomerProfileService.instance.setUser(cached.email);
          await AddressService.instance.setUser(cached.email);
          if (_role != 'business' && _role != null) {
            await SessionRoleService.instance.setRole('customer');
            _role = 'customer';
          }
        } else {
          await FavoritesService.instance.setUser(null);
          await CustomerProfileService.instance.setUser(null);
          await AddressService.instance.setUser(null);
        }
        setState(() {
          _user = cached;
          _initialized = true;
        });
      }
    } catch (_) {
      await CustomerSessionService.instance.setUser(null);
      await FavoritesService.instance.setUser(null);
      await CustomerProfileService.instance.setUser(null);
      await AddressService.instance.setUser(null);
      await SessionRoleService.instance.setRole(null);
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    SessionRoleService.instance.role.removeListener(_handleRoleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final role = _role ?? SessionRoleService.instance.role.value;
    final businessUser = BusinessSessionService.instance.user.value;
    if (role == 'business') {
      if (businessUser != null) {
        return BusinessDashboardPage(user: businessUser);
      }
      return const BusinessAuthPage();
    }
    if (role == 'customer') {
      return _user == null ? const LoginScreen() : HomePage(user: _user!);
    }
    return const LoginScreen();
  }
}
