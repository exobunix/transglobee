import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Color Palette - Emerald Green (Dark) & Forest Green (Light)
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color forestGreen = Color(0xFF166534);

  // Dark Theme Palette (Dark Navy & Emerald)
  static const Color darkNavy = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF161F30);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9DA6B9);

  // Light Theme Palette (White & Forest)
  static const Color lightWhite = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF9FAFB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Palette constants used across the app
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color gradientStart = emeraldGreen;
  static const Color gradientEnd = Color(0xFF059669);

  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldGreen, Color(0xFF059669)],
  );

  static LinearGradient get forestGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forestGreen, Color(0xFF14532D)],
  );

  // Legacy static accessors for quick migration (will map to light theme palette by default)
  // Note: These should ideally be replaced with Theme.of(context) calls
  static const Color primaryColor = forestGreen;
  static const Color backgroundColor = lightWhite; // Default light
  static const Color surfaceColor = lightSurface;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textHint = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardColor = lightWhite;
  static const Color buttonColor = Color(0xFFE5E7EB);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 25,
      offset: const Offset(0, 10),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: forestGreen,
      scaffoldBackgroundColor: lightWhite,
      cardColor: lightWhite,
      extensions: [
        CustomColors(
          surface: lightSurface,
          textPrimary: lightTextPrimary,
          textSecondary: lightTextSecondary,
          accent: forestGreen,
          button: Color(0xFFE5E7EB),
        ),
      ],
      colorScheme: const ColorScheme.light(
        primary: forestGreen,
        secondary: Color(0xFF14532D),
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: error,
      ),
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        displayLarge: GoogleFonts.lexend(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.lexend(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.notoSans(color: lightTextPrimary),
        bodyMedium: GoogleFonts.notoSans(color: lightTextSecondary),
        bodySmall: GoogleFonts.notoSans(color: lightTextSecondary),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightWhite,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: forestGreen, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: emeraldGreen,
      scaffoldBackgroundColor: darkNavy,
      cardColor: darkSurface,
      extensions: [
        CustomColors(
          surface: darkSurface,
          textPrimary: darkTextPrimary,
          textSecondary: darkTextSecondary,
          accent: emeraldGreen,
          button: Color(0xFF282E39),
        ),
      ],
      colorScheme: const ColorScheme.dark(
        primary: emeraldGreen,
        secondary: Color(0xFF059669),
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: error,
      ),
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        displayLarge: GoogleFonts.lexend(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.lexend(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.notoSans(color: darkTextPrimary),
        bodyMedium: GoogleFonts.notoSans(color: darkTextSecondary),
        bodySmall: GoogleFonts.notoSans(color: darkTextSecondary),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkNavy,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3B4354)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3B4354)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emeraldGreen, width: 2),
        ),
      ),
    );
  }
}

class CustomColors extends ThemeExtension<CustomColors> {
  final Color? surface;
  final Color? textPrimary;
  final Color? textSecondary;
  final Color? accent;
  final Color? button;

  CustomColors({
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.button,
  });

  @override
  CustomColors copyWith({
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? button,
  }) {
    return CustomColors(
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      button: button ?? this.button,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      surface: Color.lerp(surface, other.surface, t),
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t),
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t),
      accent: Color.lerp(accent, other.accent, t),
      button: Color.lerp(button, other.button, t),
    );
  }
}

extension ThemeGetters on BuildContext {
  ThemeData get theme => Theme.of(this);
  CustomColors get colors => theme.extension<CustomColors>()!;
}
