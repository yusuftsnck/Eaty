import 'package:eatyy/auth_gate.dart';
import 'package:eatyy/firebase_options.dart';
import 'package:eatyy/services/address_service.dart';
import 'package:eatyy/services/business_session_service.dart';
import 'package:eatyy/services/customer_profile_service.dart';
import 'package:eatyy/services/customer_session_service.dart';
import 'package:eatyy/services/favorites_service.dart';
import 'package:eatyy/services/session_role_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FavoritesService.instance.init();
  await BusinessSessionService.instance.init();
  await CustomerProfileService.instance.init();
  await CustomerSessionService.instance.init();
  await SessionRoleService.instance.init();
  await AddressService.instance.init();
  runApp(const EatyApp());
}

class EatyApp extends StatelessWidget {
  const EatyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eaty Mobil App',
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}
