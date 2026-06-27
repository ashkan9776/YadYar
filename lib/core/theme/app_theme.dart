import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// تم یادیار با فونت وزیرمتن و چیدمان راست‌به‌چپ — روشن و تاریک.
class AppTheme {
  AppTheme._();

  static const fontFamily = 'Vazirmatn';

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);
  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(
      primary: c.accent,
      onPrimary: Colors.white,
      secondary: c.teal,
      surface: c.bg2,
      onSurface: c.textPrimary,
      error: c.red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: c.bg,
      colorScheme: colorScheme,
      canvasColor: c.bg,
      dividerColor: c.border,
      extensions: [c],
      textTheme: _textTheme(base.textTheme, c),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: c.bg2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bg2,
        selectedItemColor: c.accent,
        unselectedItemColor: c.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bg3,
        hintStyle: TextStyle(color: c.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.bg3,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(backgroundColor: c.bg2),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppPalette c) {
    return base
        .apply(
          fontFamily: fontFamily,
          bodyColor: c.textPrimary,
          displayColor: c.textPrimary,
        )
        .copyWith(
          headlineLarge: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
          titleMedium: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontFamily: fontFamily,
            color: c.textSecondary,
            height: 1.7,
          ),
        );
  }
}
