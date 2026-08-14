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

  /// لیست رکوردهای دک‌ها (هر رکورد شامل کلید `id` و فیلدهای خام Deck.toMap).
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
  ///
  /// نسخه ۳ کلیدهای سِم‌بَست را نیز ذخیره می‌کند تا ارتباط رکوردها حفظ شود.
  static const int currentVersion = 3;

  /// تبدیل به JSON رشته‌ای.
  String toJson() {
    validateForImport();
    return const JsonEncoder.withIndent('  ').convert({
      'app': appName,
      'version': version,
      'exportedAt': exportedAt,
      'categories': categories,
      'books': books,
      'decks': decks,
      'cards': cards,
      'reviews': reviews,
      'settings': settings,
    });
  }

  /// تجزیه‌ی JSON به عکس‌فوری و اعتبارسنجی ساختار آن.
  factory AppSnapshot.fromJson(String source) {
    if (source.trim().isEmpty) {
      throw const FormatException('فایل پشتیبان خالی است.');
    }

    try {
      final decoded = json.decode(source);
      if (decoded is! Map) {
        throw const FormatException('ریشه فایل پشتیبان باید یک شیء JSON باشد.');
      }
      final data = _stringKeyedMap(decoded, 'ریشه فایل پشتیبان');
      final snapshot = AppSnapshot(
        version: _requiredInt(data, 'version', 'ریشه فایل پشتیبان'),
        exportedAt: _requiredInt(data, 'exportedAt', 'ریشه فایل پشتیبان'),
        categories: _requiredRecords(data, 'categories'),
        books: _requiredRecords(data, 'books'),
        decks: _requiredRecords(data, 'decks'),
        cards: _requiredRecords(data, 'cards'),
        reviews: _requiredRecords(data, 'reviews'),
        settings: _optionalMap(data['settings'], 'settings'),
      );
      if (data['app'] != appName) {
        throw const FormatException('این فایل پشتیبان متعلق به یادیار نیست.');
      }
      snapshot.validateForImport();
      return snapshot;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('ساختار فایل پشتیبان نامعتبر است: $error');
    }
  }

  /// اعتبارسنجی کامل داده‌ها پیش از هرگونه تغییر مخرب در دیتابیس.
  void validateForImport() {
    if (version != currentVersion) {
      throw FormatException(
        'نسخه پشتیبان $version پشتیبانی نمی‌شود. فقط نسخه $currentVersion قابل بازیابی است.',
      );
    }
    if (exportedAt < 0) {
      throw const FormatException('زمان ایجاد پشتیبان نامعتبر است.');
    }

    final categoryRecords = _requiredSnapshotRecords(categories, 'categories');
    final bookRecords = _requiredSnapshotRecords(books, 'books');
    final deckRecords = _requiredSnapshotRecords(decks, 'decks');
    final cardRecords = _requiredSnapshotRecords(cards, 'cards');
    final reviewRecords = _requiredSnapshotRecords(reviews, 'reviews');

    final categoryIds = _validateRecords(
      categoryRecords,
      'categories',
      requiredFields: const {
        'title': _FieldType.string,
        'colorHex': _FieldType.integer,
        'createdAt': _FieldType.integer,
      },
    );
    final bookIds = _validateRecords(
      bookRecords,
      'books',
      requiredFields: const {
        'categoryId': _FieldType.positiveInteger,
        'title': _FieldType.string,
        'colorHex': _FieldType.integer,
        'createdAt': _FieldType.integer,
      },
    );
    final deckIds = _validateRecords(
      deckRecords,
      'decks',
      requiredFields: const {
        'bookId': _FieldType.positiveInteger,
        'title': _FieldType.string,
        'colorHex': _FieldType.integer,
        'createdAt': _FieldType.integer,
      },
    );
    final cardIds = _validateRecords(
      cardRecords,
      'cards',
      requiredFields: const {
        'deckId': _FieldType.positiveInteger,
        'front': _FieldType.string,
        'back': _FieldType.string,
        'nextReview': _FieldType.integer,
      },
    );
    _validateRecords(
      reviewRecords,
      'reviews',
      requiredFields: const {
        'cardId': _FieldType.positiveInteger,
        'deckId': _FieldType.positiveInteger,
        'quality': _FieldType.integer,
        'reviewedAt': _FieldType.integer,
      },
    );

    _validateReferences(bookRecords, 'books', 'categoryId', categoryIds);
    _validateReferences(deckRecords, 'decks', 'bookId', bookIds);
    _validateReferences(cardRecords, 'cards', 'deckId', deckIds);
    _validateReferences(reviewRecords, 'reviews', 'cardId', cardIds);
    _validateReferences(reviewRecords, 'reviews', 'deckId', deckIds);

    final cardDeckIds = <int, int>{
      for (final card in cardRecords)
        card['id']! as int: card['deckId']! as int,
    };
    for (final review in reviewRecords) {
      final cardId = review['cardId']! as int;
      if (review['deckId'] != cardDeckIds[cardId]) {
        throw FormatException(
          'رکورد reviews با شناسه ${review['id']} به کارت و دک ناسازگار اشاره می‌کند.',
        );
      }
    }
  }

  static List<Map<String, Object?>> _requiredSnapshotRecords(
    List<Map<String, Object?>>? records,
    String name,
  ) {
    if (records == null) {
      throw FormatException('بخش $name در فایل پشتیبان وجود ندارد.');
    }
    return records;
  }

  static Set<int> _validateRecords(
    List<Map<String, Object?>> records,
    String name, {
    required Map<String, _FieldType> requiredFields,
  }) {
    final ids = <int>{};
    for (final record in records) {
      final id = record['id'];
      if (id is! int || id <= 0) {
        throw FormatException('هر رکورد $name باید یک شناسه مثبت داشته باشد.');
      }
      if (!ids.add(id)) {
        throw FormatException('شناسه تکراری $id در بخش $name.');
      }
      for (final field in requiredFields.entries) {
        if (!_hasType(record[field.key], field.value)) {
          throw FormatException(
            'فیلد ${field.key} در $name با شناسه $id نامعتبر است.',
          );
        }
      }
    }
    return ids;
  }

  static bool _hasType(Object? value, _FieldType type) => switch (type) {
    _FieldType.string => value is String,
    _FieldType.integer => value is int,
    _FieldType.positiveInteger => value is int && value > 0,
  };

  static void _validateReferences(
    List<Map<String, Object?>> records,
    String name,
    String field,
    Set<int> targetIds,
  ) {
    for (final record in records) {
      if (!targetIds.contains(record[field])) {
        throw FormatException(
          'رکورد $name با شناسه ${record['id']} به $field ناموجود اشاره می‌کند.',
        );
      }
    }
  }

  static int _requiredInt(
    Map<String, Object?> map,
    String key,
    String context,
  ) {
    final value = map[key];
    if (value is! int) {
      throw FormatException('فیلد $key در $context باید عدد صحیح باشد.');
    }
    return value;
  }

  static List<Map<String, Object?>> _requiredRecords(
    Map<String, Object?> data,
    String name,
  ) {
    final value = data[name];
    if (value is! List) {
      throw FormatException('بخش $name باید یک فهرست باشد.');
    }
    return [
      for (var index = 0; index < value.length; index++)
        _stringKeyedMap(value[index], '$name[$index]'),
    ];
  }

  static Map<String, Object?>? _optionalMap(Object? value, String name) {
    if (value == null) return null;
    return _stringKeyedMap(value, name);
  }

  static Map<String, Object?> _stringKeyedMap(Object? value, String context) {
    if (value is! Map) {
      throw FormatException('$context باید یک شیء JSON باشد.');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FormatException('کلیدهای $context باید رشته باشند.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }
}

enum _FieldType { string, integer, positiveInteger }
