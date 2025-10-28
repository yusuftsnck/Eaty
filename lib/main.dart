import 'package:eatyy/auth_gate.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
