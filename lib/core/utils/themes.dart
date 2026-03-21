import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SRColors {
  static const bg          = Color(0xFF0A0A0F);
  static const bgSecondary = Color(0xFF111118);
  static const bgCard      = Color(0xFF16161F);
  static const border      = Color(0xFF1F1F2E);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecond  = Color(0xFFB0B8C4);
  static const textMuted   = Color(0xFF6B7280);
  static const success     = Color(0xFF22C55E);
  static const warning     = Color(0xFFF59E0B);
  static const danger      = Color(0xFFEF4444);
  // Public blue
  static const publicAccent = Color(0xFF1D9BF0);
  // Government purple
  static const govAccent   = Color(0xFF8B5CF6);
}

ThemeData buildTheme(Color accent) {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: SRColors.bg,
    colorScheme: ColorScheme.dark(primary: accent, surface: SRColors.bgSecondary, error: SRColors.danger),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: SRColors.textPrimary, displayColor: SRColors.textPrimary),
    appBarTheme: AppBarTheme(
      backgroundColor: SRColors.bg, elevation: 0, scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: SRColors.textPrimary),
      titleTextStyle: GoogleFonts.inter(color: SRColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardTheme(
      color: SRColors.bgCard, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: SRColors.border)),
    ),
    dividerTheme: const DividerThemeData(color: SRColors.border),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: SRColors.bgSecondary,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SRColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SRColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 1.5)),
      hintStyle: const TextStyle(color: SRColors.textMuted, fontSize: 14),
      labelStyle: const TextStyle(color: SRColors.textSecond),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: SRColors.bg,
      selectedItemColor: accent,
      unselectedItemColor: SRColors.textMuted,
    ),
  );
}

Color hexColor(String hex, {double opacity = 1.0}) {
  try {
    final c = Color(int.parse('FF' + hex.replaceAll('#', ''), radix: 16));
    return c.withOpacity(opacity);
  } catch (_) { return Colors.grey; }
}
