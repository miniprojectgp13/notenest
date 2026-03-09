import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF7357FF);
  static const Color secondary = Color(0xFF65C8D0);
  static const Color warm = Color(0xFFF0BE49);
  static const Color panel = Color(0xFFFAF5DF);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F2F7),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        headlineSmall: GoogleFonts.fredoka(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: const Color(0xFF352C54),
        ),
        titleMedium: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: const Color(0xFF40355E),
        ),
        bodyMedium: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5D5574),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }
}
