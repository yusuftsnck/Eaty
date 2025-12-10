import 'package:eatyy/auth_gate.dart';
import 'package:eatyy/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
