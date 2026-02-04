import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ocean_colors.dart';

/// Ocean-themed Material theme configuration
class OceanTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: OceanColors.oceanBlue,
      scaffoldBackgroundColor: OceanColors.pearlWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: OceanColors.deepSeaBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.raleway(
          color: OceanColors.pearlWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.raleway(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: OceanColors.deepSeaBlue,
        ),
        displayMedium: GoogleFonts.raleway(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: OceanColors.deepSeaBlue,
        ),
        displaySmall: GoogleFonts.raleway(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: OceanColors.deepSeaBlue,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: OceanColors.deepSeaBlue,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: OceanColors.deepSeaBlue,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: OceanColors.deepSeaBlue,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: OceanColors.darkGray,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: OceanColors.darkGray,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: OceanColors.mediumGray,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: OceanColors.pearlWhite,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: OceanColors.pearlWhite,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: OceanColors.pearlWhite,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OceanColors.accentTeal,
          foregroundColor: OceanColors.pearlWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OceanColors.oceanBlue,
          side: const BorderSide(color: OceanColors.oceanBlue, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: OceanColors.accentTeal,
        foregroundColor: OceanColors.pearlWhite,
        elevation: 8,
        shape: const CircleBorder(),
      ),
      cardTheme: CardTheme(
        color: OceanColors.pearlWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OceanColors.lightGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OceanColors.mediumGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OceanColors.mediumGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OceanColors.oceanBlue, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: OceanColors.mediumGray,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: OceanColors.mediumGray,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: OceanColors.aquamarine,
        labelStyle: GoogleFonts.poppins(
          color: OceanColors.deepSeaBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: OceanColors.oceanBlue,
      scaffoldBackgroundColor: OceanColors.deepSeaBlue,
      appBarTheme: AppBarTheme(
        backgroundColor: OceanColors.deepSeaBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.raleway(
          color: OceanColors.aquamarine,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.raleway(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: OceanColors.pearlWhite,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: OceanColors.aquamarine,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: OceanColors.pearlWhite,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: OceanColors.lightGray,
        ),
      ),
    );
  }
}
