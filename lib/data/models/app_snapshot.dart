import 'dart:convert';

/// عکس‌فوری از کل دیتابیس — مبنای پشتیبان‌گیری/بازیابی.
/// تمام مدل‌ها رو به‌صورت Map ساده ذخیره می‌کند تا وابستگی‌ای به سِم‌بَست نداشته باشد.
class AppSnapshot {
  const AppSnapshot({
    required this.version,
    required this.exportedAt,
    this.categories,
    this.books,
    required this.decks,
    required this.cards,
    required this.reviews,
    required this.settings,
  });

  /// نسخه‌ی فرمت فایل — برای سازگاری آینده.
  final int version;

  /// تاریخ ایجاد عکس‌فوری (میلی‌ثانیه).
  final int exportedAt;

  /// لیست رکوردهای دسته‌بندی‌ها (نسخه ۲ به بعد).
  final List<Map<String, Object?>>? categories;

  /// لیست رکوردهای کتاب‌ها (نسخه ۲ به بعد).
  final List<Map<String, Object?>>? books;

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
  static const int currentVersion = 2;

  /// تبدیل به JSON رشته‌ای.
  String toJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'app': appName,
      'version': version,
      'exportedAt': exportedAt,
      if (categories != null) 'categories': categories,
      if (books != null) 'books': books,
      'decks': decks,
      'cards': cards,
      'reviews': reviews,
      'settings': settings,
    });
  }

  /// تجزیه‌ی JSON به عکس‌فوری — با سازگاری向后 به نسخه ۱.
  factory AppSnapshot.fromJson(String source) {
    final data = json.decode(source) as Map<String, dynamic>;
    return AppSnapshot(
      version: data['version'] as int? ?? 1,
      exportedAt: data['exportedAt'] as int? ?? 0,
      categories: data['categories'] == null
          ? null
          : (data['categories'] as List<dynamic>)
              .map((e) => (e as Map<String, dynamic>).cast<String, Object?>())
              .toList(),
      books: data['books'] == null
          ? null
          : (data['books'] as List<dynamic>)
              .map((e) => (e as Map<String, dynamic>).cast<String, Object?>())
              .toList(),
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
