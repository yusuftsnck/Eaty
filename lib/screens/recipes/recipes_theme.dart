import 'package:flutter/material.dart';

class RecipeColors {
  static const Color primary = Color(0xFF8B00FF);
  static const Color secondary = Color(0xFFFF006C);
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1E1F4B);
  static const Color textMuted = Color(0xFF6C6D83);
  static const Color border = Color(0xFFEAEAF2);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF8B00FF), Color(0xFFFF006C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
