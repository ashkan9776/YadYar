import 'package:flutter/material.dart';

/// پالت رنگ یادیار به‌صورت ThemeExtension تا تم روشن/تاریک به‌صورت زنده
/// قابل تعویض باشد. رنگ‌ها در ویجت‌ها از طریق `context.colors.<token>` خوانده می‌شوند.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.bg2,
    required this.bg3,
    required this.border,
    required this.border2,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentGlow,
    required this.purple200,
    required this.purple600,
    required this.teal,
    required this.teal600,
    required this.amber,
    required this.amber600,
    required this.red,
    required this.red600,
    // توکن‌های نئون (افزوده‌ی بازطراحی بصری)
    required this.neonBlue,
    required this.neonGreen,
    required this.surfaceGlow,
    required this.cardShadow,
  });

  // پس‌زمینه‌ها
  final Color bg;
  final Color bg2;
  final Color bg3;

  // مرزها
  final Color border;
  final Color border2;

  // متن
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // اکسنت اصلی (بنفش)
  final Color accent;
  final Color accentGlow;
  final Color purple200;
  final Color purple600;

  // رنگ‌های ثانویه
  final Color teal;
  final Color teal600;
  final Color amber;
  final Color amber600;
  final Color red;
  final Color red600;

  // توکن‌های نئون (افزوده‌ی بازطراحی بصری)
  final Color neonBlue;
  final Color neonGreen;
  final Color surfaceGlow;
  final Color cardShadow;

  /// تم تاریک — پالت اصلی برگرفته از PRD رسمی محصول.
  static const dark = AppPalette(
    bg: Color(0xFF0D0C14),
    bg2: Color(0xFF13111F),
    bg3: Color(0xFF1C1929),
    border: Color(0x267F77DD), // rgba(127,119,221,0.15)
    border2: Color(0x407F77DD), // rgba(127,119,221,0.25)
    textPrimary: Color(0xFFF0EFF8),
    textSecondary: Color(0xFF9A97B8),
    textMuted: Color(0xFF5A5878),
    accent: Color(0xFF7F77DD),
    accentGlow: Color(0x337F77DD), // rgba(127,119,221,0.2)
    purple200: Color(0xFFAFA9EC),
    purple600: Color(0xFF534AB7),
    teal: Color(0xFF5DCAA5),
    teal600: Color(0xFF0F6E56),
    amber: Color(0xFFEF9F27),
    amber600: Color(0xFF854F0B),
    red: Color(0xFFE24B4A),
    red600: Color(0xFFA32D2D),
    neonBlue: Color(0xFF4A9BE2),
    neonGreen: Color(0xFF3DD68C),
    surfaceGlow: Color(0xCC13111F), // bg2 با آلفای ۸۰٪ برای شیشه‌مورفیسم
    cardShadow: Color(0x4D7F77DD), // accent با آلفای ۳۰٪
  );

  /// تم روشن — همان هویت بنفش با پس‌زمینه‌ی روشن و متن تیره.
  static const light = AppPalette(
    bg: Color(0xFFF6F5FB),
    bg2: Color(0xFFFFFFFF),
    bg3: Color(0xFFECEAF6),
    border: Color(0x267F77DD), // rgba(127,119,221,0.15)
    border2: Color(0x4D7F77DD), // rgba(127,119,221,0.30)
    textPrimary: Color(0xFF1A1825),
    textSecondary: Color(0xFF56536E),
    textMuted: Color(0xFF8B88A3),
    accent: Color(0xFF6A61D4),
    accentGlow: Color(0x1A7F77DD), // rgba(127,119,221,0.1)
    purple200: Color(0xFF6A61D4),
    purple600: Color(0xFF534AB7),
    teal: Color(0xFF1F9E78),
    teal600: Color(0xFF0F6E56),
    amber: Color(0xFFC07A0F),
    amber600: Color(0xFF854F0B),
    red: Color(0xFFD23A39),
    red600: Color(0xFFA32D2D),
    neonBlue: Color(0xFF2D7DD2),
    neonGreen: Color(0xFF1FB868),
    surfaceGlow: Color(0xCCFFFFFF), // bg2 با آلفای ۸۰٪
    cardShadow: Color(0x1A6A61D4), // accent روشن با آلفای ۱۰٪
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? bg2,
    Color? bg3,
    Color? border,
    Color? border2,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentGlow,
    Color? purple200,
    Color? purple600,
    Color? teal,
    Color? teal600,
    Color? amber,
    Color? amber600,
    Color? red,
    Color? red600,
    Color? neonBlue,
    Color? neonGreen,
    Color? surfaceGlow,
    Color? cardShadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      bg3: bg3 ?? this.bg3,
      border: border ?? this.border,
      border2: border2 ?? this.border2,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentGlow: accentGlow ?? this.accentGlow,
      purple200: purple200 ?? this.purple200,
      purple600: purple600 ?? this.purple600,
      teal: teal ?? this.teal,
      teal600: teal600 ?? this.teal600,
      amber: amber ?? this.amber,
      amber600: amber600 ?? this.amber600,
      red: red ?? this.red,
      red600: red600 ?? this.red600,
      neonBlue: neonBlue ?? this.neonBlue,
      neonGreen: neonGreen ?? this.neonGreen,
      surfaceGlow: surfaceGlow ?? this.surfaceGlow,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      bg3: Color.lerp(bg3, other.bg3, t)!,
      border: Color.lerp(border, other.border, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      purple200: Color.lerp(purple200, other.purple200, t)!,
      purple600: Color.lerp(purple600, other.purple600, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      teal600: Color.lerp(teal600, other.teal600, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amber600: Color.lerp(amber600, other.amber600, t)!,
      red: Color.lerp(red, other.red, t)!,
      red600: Color.lerp(red600, other.red600, t)!,
      neonBlue: Color.lerp(neonBlue, other.neonBlue, t)!,
      neonGreen: Color.lerp(neonGreen, other.neonGreen, t)!,
      surfaceGlow: Color.lerp(surfaceGlow, other.surfaceGlow, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }
}

/// دسترسی کوتاه به پالت جاری از روی context.
extension PaletteX on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}

/// ثابت‌های مستقل از تم.
class AppColors {
  AppColors._();

  /// رنگ‌های پیش‌فرض برای ساخت دک جدید (مستقل از تم).
  static const deckPalette = <int>[
    0xFF7F77DD, // بنفش
    0xFF5DCAA5, // سبزآبی
    0xFFEF9F27, // کهربایی
    0xFFE24B4A, // قرمز
    0xFF4A9BE2, // آبی
    0xFFD46FD4, // صورتی
  ];
}
