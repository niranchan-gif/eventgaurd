import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // TACTICAL DEFENSE COMMAND PALETTE (Anduril / C2 Radar Aesthetic)
  // Non-blue, non-muddy: Precision Carbon Obsidian, Titanium White & Tactical Amber

  static const Color obsidianBlack = Color(0xFF090A0D);  // Pure, rich, distraction-free obsidian
  static const Color charcoalSurface = Color(0xFF13151A); // Sleek card surface
  static const Color charcoalElevated = Color(0xFF1C1F26); // Clean hover / elevated surface
  static const Color hairlineBorder = Color(0xFF232732);  // Crisp boundary
  static const Color subtleBorder = Color(0xFF1A1D24);

  static const Color titaniumWhite = Color(0xFFF9FAFB);  // Ultra-crisp, high-legibility primary text
  static const Color mutedSilver = Color(0xFFA1A8B8);    // Crisp secondary text (clean, legible)
  static const Color disabledGrey = Color(0xFF64748B);

  static const Color tacticalAmber = Color(0xFFF59E0B);  // Energetic tactical amber accent
  static const Color alertRed = Color(0xFFEF4444);       // High-vis alert red
  static const Color radarGreen = Color(0xFF10B981);     // Crisp neon radar green

  // Backward compatibility tokens
  static const Color darkOlive = obsidianBlack;
  static const Color deepGreen = charcoalSurface;
  static const Color cream = titaniumWhite;
  static const Color orange = tacticalAmber;
  static const Color darkTeal = obsidianBlack;
  static const Color sage = charcoalSurface;
  static const Color burgundy = alertRed;

  // Semantic mappings
  static const Color background = obsidianBlack;
  static const Color surface = charcoalSurface;
  static const Color surfaceLight = charcoalElevated;
  static const Color surfaceDark = Color(0xFF0E1014);

  static const Color primary = tacticalAmber;
  static const Color accent = tacticalAmber;
  static const Color secondary = titaniumWhite;

  static const Color textLight = titaniumWhite;
  static const Color textDark = obsidianBlack;
  static const Color textMuted = mutedSilver;
  static const Color textDisabled = disabledGrey;

  static const Color border = hairlineBorder;
  static const Color borderSubtle = subtleBorder;

  static const Color critical = alertRed;
  static const Color warning = tacticalAmber;
  static const Color safe = radarGreen;
  static const Color info = titaniumWhite;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: tacticalAmber,
        secondary: titaniumWhite,
        surface: charcoalSurface,
        error: alertRed,
        onPrimary: obsidianBlack,
        onSecondary: obsidianBlack,
        onSurface: titaniumWhite,
      ),
      cardColor: surface,
      dividerColor: borderSubtle,
      
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: titaniumWhite),
        titleTextStyle: GoogleFonts.inter(color: titaniumWhite, fontSize: 18, fontWeight: FontWeight.w600),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tacticalAmber,
          foregroundColor: obsidianBlack,
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tacticalAmber,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: titaniumWhite,
          side: const BorderSide(color: hairlineBorder, width: 1.2),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        labelStyle: const TextStyle(color: mutedSilver),
        hintStyle: const TextStyle(color: disabledGrey),
        prefixIconColor: mutedSilver,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: hairlineBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: hairlineBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: tacticalAmber, width: 1.8),
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: hairlineBorder, width: 1),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 12,
        shadowColor: Colors.black87,
        titleTextStyle: GoogleFonts.inter(color: titaniumWhite, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: GoogleFonts.inter(color: titaniumWhite, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: hairlineBorder, width: 1),
        ),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(charcoalElevated),
        headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: titaniumWhite, fontSize: 13),
        dataTextStyle: GoogleFonts.inter(color: titaniumWhite, fontSize: 13),
        dividerThickness: 1,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tacticalAmber;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(obsidianBlack),
        side: const BorderSide(color: hairlineBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.inter(color: titaniumWhite, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: titaniumWhite, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.inter(color: titaniumWhite, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(color: titaniumWhite, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.inter(color: titaniumWhite, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(color: titaniumWhite, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: titaniumWhite),
        bodyMedium: GoogleFonts.inter(color: titaniumWhite),
        bodySmall: GoogleFonts.inter(color: mutedSilver),
      ),
    );
  }
}
