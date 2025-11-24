import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF0B0F1A);
  static const Color accentTeal = Color(0xFF00D1B2);
  static const Color cardBackground = Color(0xFF121A29);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color alertGreen = Color(0xFF4CAF50);
  static const Color alertYellow = Color(0xFFFFC107);
  static const Color alertOrange = Color(0xFFFF9800);
  static const Color alertRed = Color(0xFFF44336);

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        primaryColor: accentTeal,
        colorScheme: const ColorScheme.dark(
          primary: accentTeal,
          secondary: accentTeal,
          surface: cardBackground,
          // background: backgroundColor, // Deprecated
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: textPrimary,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: textSecondary,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        // cardTheme: CardTheme(
        //   color: cardBackground.withValues(alpha: 0.9),
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(16),
        //   ),
        //   elevation: 4,
        // ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentTeal,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: textPrimary),
        ),
      );
}