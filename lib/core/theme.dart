import 'package:flutter/material.dart';
import 'constants.dart';

/// أنماط الخطوط التحريرية — كلها مدمجة داخل التطبيق (assets/fonts)
/// فتظهر فوراً من أول شاشة وبدون إنترنت:
/// أميري للعناوين (روح المطبعة)، بلكس العربي لنص الواجهة، ومونو للحروف والأرقام.
class AppType {
  static const String displayFamily = 'Amiri';
  static const String uiFamily = 'PlexArabic';
  static const String monoFamily = 'PlexMono';

  static TextStyle display({
    double size = 26,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.55,
  }) =>
      TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        // أميري متاح بوزنين فقط: عادي وعريض
        fontWeight: weight.index >= FontWeight.w600.index
            ? FontWeight.w700
            : FontWeight.w400,
        color: color ?? AppColors.ink,
        height: height,
      );

  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.6,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: uiFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double letterSpacing = 2,
  }) =>
      TextStyle(
        fontFamily: monoFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        letterSpacing: letterSpacing,
      );
}

class AppTheme {
  /// تُبنى بعد ضبط AppColors.dark فتتبع اللوحة الحالية
  static ThemeData build() {
    const textTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: AppType.displayFamily),
      displayMedium: TextStyle(fontFamily: AppType.displayFamily),
      displaySmall: TextStyle(fontFamily: AppType.displayFamily),
      headlineLarge: TextStyle(fontFamily: AppType.displayFamily),
      headlineMedium: TextStyle(fontFamily: AppType.displayFamily),
      headlineSmall: TextStyle(fontFamily: AppType.displayFamily),
      titleLarge: TextStyle(fontFamily: AppType.uiFamily),
      titleMedium: TextStyle(fontFamily: AppType.uiFamily),
      titleSmall: TextStyle(fontFamily: AppType.uiFamily),
      bodyLarge: TextStyle(fontFamily: AppType.uiFamily),
      bodyMedium: TextStyle(fontFamily: AppType.uiFamily),
      bodySmall: TextStyle(fontFamily: AppType.uiFamily),
      labelLarge: TextStyle(fontFamily: AppType.uiFamily),
      labelMedium: TextStyle(fontFamily: AppType.uiFamily),
      labelSmall: TextStyle(fontFamily: AppType.uiFamily),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppType.uiFamily,
      scaffoldBackgroundColor: AppColors.paper,
      brightness: AppColors.dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violet,
        brightness: AppColors.dark ? Brightness.dark : Brightness.light,
        surface: AppColors.paper,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: AppType.ui(size: 14, weight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppType.ui(size: 13, color: AppColors.paper),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
