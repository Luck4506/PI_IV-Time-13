// Autoria de Lucas Soares Gonçalves RA 25009467
// Com contribuições de Sofia de Sousa.
import 'package:flutter/material.dart';

const appName = 'Gabariteii';

abstract final class AppColors {
  static const ink = Color(0xFF17212B);
  static const muted = Color(0xFF667085);

  static const primary = Color(0xFF1565FF);
  static const primaryDark = Color(0xFF0D47C1);

  static const mint = Color(0xFF00CFFF);
  static const mintSoft = Color(0xFFE3F5FF);

  static const amber = Color(0xFFFFC247);
  static const amberSoft = Color(0xFFFFF5D8);

  static const coral = Color(0xFFFF6B6B);
  static const coralSoft = Color(0xFFFFECE7);

  static const sky = Color(0xFF00B8D9);

  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E7EC);
  static const white = Color(0xFFFFFFFF);
}

ThemeData buildTrilhaTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    surface: AppColors.white,
    error: const Color(0xFFD92D20),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'SF Pro Display',
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(
        color: AppColors.ink,
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
      headlineLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      headlineMedium: const TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.35,
      ),
      titleLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: const TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: const TextStyle(
        color: AppColors.muted,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.7),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: const Color(0xFFE9EEFF),
      elevation: 0,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
