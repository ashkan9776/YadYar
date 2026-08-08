/// محدودیت‌های نسخه رایگان و منطق بررسی آنها.
class FreemiumLimits {
  FreemiumLimits._();

  /// حداکثر تعداد دسته‌بندی در نسخه رایگان.
  static const int maxCategories = 3;

  /// حداکثر تعداد کتاب به ازای هر دسته در نسخه رایگان.
  static const int maxBooksPerCategory = 2;

  /// حداکثر تعداد دک به ازای هر کتاب در نسخه رایگان.
  static const int maxDecksPerBook = 5;

  /// حداکثر تعداد کارت به ازای هر دک در نسخه رایگان.
  static const int maxCardsPerDeck = 50;

  /// آیا کاربر رایگان می‌تواند دسته جدید بسازد؟
  static bool canCreateCategory(int currentCount, bool isPro) =>
      isPro || currentCount < maxCategories;

  /// آیا کاربر رایگان می‌تواند کتاب جدید بسازد؟
  static bool canCreateBook(int currentCount, bool isPro) =>
      isPro || currentCount < maxBooksPerCategory;

  /// آیا کاربر رایگان می‌تواند دک جدید بسازد؟
  static bool canCreateDeck(int currentCount, bool isPro) =>
      isPro || currentCount < maxDecksPerBook;

  /// آیا کاربر رایگان می‌تواند کارت جدید بسازد؟
  static bool canCreateCard(int currentCount, bool isPro) =>
      isPro || currentCount < maxCardsPerDeck;

  /// پیام فارسی محدودیت بر اساس نوع موجودیت.
  static String limitMessage(String entity) {
    return switch (entity) {
      'category' =>
        'نسخه رایگان حداکثر $maxCategories دسته‌بندی دارد.\nنسخه حرفه‌ای را ارتقا دهید تا نامحدود بسازید.',
      'book' =>
        'نسخه رایگان حداکثر $maxBooksPerCategory کتاب به ازای هر دسته دارد.\nنسخه حرفه‌ای را ارتقا دهید.',
      'deck' =>
        'نسخه رایگان حداکثر $maxDecksPerBook دک به ازای هر کتاب دارد.\nنسخه حرفه‌ای را ارتقا دهید.',
      'card' =>
        'نسخه رایگان حداکثر $maxCardsPerDeck کارت به ازای هر دک دارد.\nنسخه حرفه‌ای را ارتقا دهید.',
      _ => 'به محدودیت نسخه رایگان رسیده‌اید.\nنسخه حرفه‌ای را ارتقا دهید.',
    };
  }

  /// ساخت برچسب تعداد مصرف‌شده/حداکثر (مثلاً: ۲/۳).
  static String usageLabel(int current, int max, bool isPro) =>
      isPro ? '$current' : '$current/$max';
}
