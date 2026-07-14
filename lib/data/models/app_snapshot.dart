import 'dart:convert';

/// عکس‌فوری از کل دیتابیس — مبنای پشتیبان‌گیری/بازیابی.
/// تمام مدل‌ها رو به‌صورت Map ساده ذخیره می‌کند تا وابستگی‌ای به سِم‌بَست نداشته باشد.
class AppSnapshot {
  const AppSnapshot({
    required this.version,
    required this.exportedAt,
    required this.decks,
    required this.cards,
    required this.reviews,
    required this.settings,
  });

  /// نسخه‌ی فرمت فایل — برای سازگاری آینده.
  final int version;

  /// تاریخ ایجاد عکس‌فوری (میلی‌ثانیه).
  final int exportedAt;

  /// لیست رکوردهای دک‌ها (هر رکورد شامل فیلدهای خام Deck.toMap).
  final List<Map<String, Object?>> decks;

  /// لیست رکوردهای فلش‌کارت‌ها.
  final List<Map<String, Object?>> cards;

  /// لیست رکوردهای لاگ مرورها.
  final List<Map<String, Object?>> reviews;

  /// رکورد تنظیمات (یا null اگر ذخیره نشده).
  final Map<String, Object?>? settings;

  /// نام اپ — برای نمایش در فایل.
  static const String appName = 'یادیار';

  /// نسخه‌ی فعلی فرمت.
  static const int currentVersion = 1;

  /// تبدیل به JSON رشته‌ای.
  String toJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'app': appName,
      'version': version,
      'exportedAt': exportedAt,
      'decks': decks,
      'cards': cards,
      'reviews': reviews,
      'settings': settings,
    });
  }

  /// تجزیه‌ی JSON به عکس‌فوری.
  factory AppSnapshot.fromJson(String source) {
    final data = json.decode(source) as Map<String, dynamic>;
    return AppSnapshot(
      version: data['version'] as int? ?? 0,
      exportedAt: data['exportedAt'] as int? ?? 0,
      decks: (data['decks'] as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>).cast<String, Object?>())
          .toList(),
      cards: (data['cards'] as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>).cast<String, Object?>())
          .toList(),
      reviews: (data['reviews'] as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>).cast<String, Object?>())
          .toList(),
      settings: data['settings'] == null
          ? null
          : (data['settings'] as Map<String, dynamic>)
              .cast<String, Object?>(),
    );
  }
}
