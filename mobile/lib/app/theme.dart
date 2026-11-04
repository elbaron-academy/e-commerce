import 'package:flutter/material.dart';

/// Brand colors, the same as the website.
abstract final class AppColors {
  static const brand50 = Color(0xFFEFFAF5);
  static const brand100 = Color(0xFFD9F2E7);
  static const brand200 = Color(0xFFB2E3CF);
  static const brand500 = Color(0xFF16976B);
  static const brand600 = Color(0xFF0E7C5A);
  static const brand700 = Color(0xFF0B6449);
  static const brand800 = Color(0xFF0A503B);
  static const accent50 = Color(0xFFFFF4ED);
  static const accent500 = Color(0xFFFF6B2C);
  static const accent600 = Color(0xFFE85512);
  static const accent700 = Color(0xFFC2440B);
  static const ink = Color(0xFF15211C);
  static const muted = Color(0xFF5F6D67);
  static const line = Color(0xFFE3E8E5);
  static const canvas = Color(0xFFF5F6F4);
  static const danger = Color(0xFFC93A2B);
  static const danger50 = Color(0xFFFDEEEC);
  static const warning50 = Color(0xFFFFF8E6);
  static const warning800 = Color(0xFF8A5A00);
}

abstract final class AppTheme {
  static const radius = 16.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand600,
      primary: AppColors.brand600,
      onPrimary: Colors.white,
      secondary: AppColors.accent500,
      surface: Colors.white,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Cairo');
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: rounded,
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: rounded,
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand700,
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand500, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.brand600,
        side: const BorderSide(color: AppColors.line),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: AppColors.ink),
        secondaryLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Colors.white),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.brand50,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected) ? AppColors.brand700 : AppColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) =>
              IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.brand700 : AppColors.muted),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
    );
  }
}
