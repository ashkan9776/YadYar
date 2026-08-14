import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/models/app_settings.dart';
import '../data/models/book.dart';
import '../data/models/category.dart';
import '../data/models/deck.dart';
import '../data/models/flashcard.dart';
import '../data/models/review_log.dart';
import '../data/repositories/book_repository.dart';
import '../data/repositories/card_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/deck_repository.dart';
import '../data/repositories/review_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/activity.dart';
import '../domain/gamification.dart';
import '../domain/study_stats.dart';
import '../domain/weak_cards.dart';

/// نمونه‌ی دیتابیس — در main هنگام راه‌اندازی override می‌شود.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider باید override شود'),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepository(ref.watch(databaseProvider)),
);

final deckRepositoryProvider = Provider<DeckRepository>(
  (ref) => DeckRepository(ref.watch(databaseProvider)),
);

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(ref.watch(databaseProvider)),
);

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

/// جریان زنده‌ی تنظیمات کاربر.
final settingsStreamProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// تنظیمات جاری (یا پیش‌فرض تا وقتی جریان بارگذاری شود).
final settingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(settingsStreamProvider).value ?? AppSettings.defaults,
);

/// ── دسته‌بندی‌ها ─────────────────────────────────────────────────

/// جریان زنده‌ی همه‌ی دسته‌بندی‌ها.
final categoriesStreamProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// ── کتاب‌ها ──────────────────────────────────────────────────────

/// جریان زنده‌ی همه‌ی کتاب‌ها.
final booksStreamProvider = StreamProvider<List<Book>>(
  (ref) => ref.watch(bookRepositoryProvider).watchAll(),
);

/// جریان زنده‌ی کتاب‌های یک دسته‌بندی.
final categoryBooksProvider = StreamProvider.family<List<Book>, int>((
  ref,
  categoryId,
) {
  return ref.watch(bookRepositoryProvider).watchByCategory(categoryId);
});

/// ── دک‌ها ─────────────────────────────────────────────────────────

/// جریان زنده‌ی همه‌ی دک‌ها.
final decksStreamProvider = StreamProvider<List<Deck>>(
  (ref) => ref.watch(deckRepositoryProvider).watchAll(),
);

/// جریان زنده‌ی دک‌های یک کتاب.
final bookDecksProvider = StreamProvider.family<List<Deck>, int>((ref, bookId) {
  return ref.watch(deckRepositoryProvider).watchByBook(bookId);
});

/// ── کارت‌ها ──────────────────────────────────────────────────────

/// جریان زنده‌ی همه‌ی کارت‌ها (مبنای شمارش سررسیدها).
final allCardsStreamProvider = StreamProvider<List<FlashCard>>(
  (ref) => ref.watch(cardRepositoryProvider).watchAll(),
);

/// جریان زنده‌ی لاگ مرورها.
final reviewLogsStreamProvider = StreamProvider<List<ReviewLog>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchAll(),
);

/// جریان زنده‌ی کارت‌های یک دک مشخص.
final deckCardsProvider = StreamProvider.family<List<FlashCard>, int>((
  ref,
  deckId,
) {
  return ref.watch(cardRepositoryProvider).watchByDeck(deckId);
});

/// ─ـ شمارش‌های مشتق ─────────────────────────────────────────────

/// تعداد کارت سررسیددار به تفکیک دک.
final dueCountsProvider = Provider<Map<int, int>>((ref) {
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  final now = DateTime.now();
  final map = <int, int>{};
  for (final c in cards) {
    if (c.isDueAt(now)) {
      map[c.deckId] = (map[c.deckId] ?? 0) + 1;
    }
  }
  return map;
});

/// تعداد کل کارت به تفکیک دک.
final cardCountsProvider = Provider<Map<int, int>>((ref) {
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  final map = <int, int>{};
  for (final c in cards) {
    map[c.deckId] = (map[c.deckId] ?? 0) + 1;
  }
  return map;
});

/// مجموع کارت‌های سررسیددار در همه‌ی دک‌ها.
final totalDueProvider = Provider<int>((ref) {
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  final now = DateTime.now();
  return cards.where((c) => c.isDueAt(now)).length;
});

/// تعداد کل کارت به تفکیک کتاب (جمع دک‌های هر کتاب).
final bookCardCountsProvider = Provider<Map<int, int>>((ref) {
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  final decks = ref.watch(decksStreamProvider).value ?? const [];
  final decksById = {for (final deck in decks) deck.id: deck};
  final map = <int, int>{};
  for (final c in cards) {
    final deck = decksById[c.deckId];
    if (deck != null) {
      map[deck.bookId] = (map[deck.bookId] ?? 0) + 1;
    }
  }
  return map;
});

/// تعداد کارت سررسیددار به تفکیک کتاب.
final bookDueCountsProvider = Provider<Map<int, int>>((ref) {
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  final decks = ref.watch(decksStreamProvider).value ?? const [];
  final decksById = {for (final deck in decks) deck.id: deck};
  final now = DateTime.now();
  final map = <int, int>{};
  for (final c in cards) {
    if (c.isDueAt(now)) {
      final deck = decksById[c.deckId];
      if (deck != null) {
        map[deck.bookId] = (map[deck.bookId] ?? 0) + 1;
      }
    }
  }
  return map;
});

/// تعداد کل کارت به تفکیک دسته‌بندی.
final categoryCardCountsProvider = Provider<Map<int, int>>((ref) {
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  final decks = ref.watch(decksStreamProvider).value ?? const [];
  final books = ref.watch(booksStreamProvider).value ?? const [];
  final decksById = {for (final deck in decks) deck.id: deck};
  final booksById = {for (final book in books) book.id: book};
  final map = <int, int>{};
  for (final c in cards) {
    final deck = decksById[c.deckId];
    final book = deck == null ? null : booksById[deck.bookId];
    if (book != null) {
      map[book.categoryId] = (map[book.categoryId] ?? 0) + 1;
    }
  }
  return map;
});

/// تعداد کارت سررسیددار به تفکیک دسته‌بندی.
final categoryDueCountsProvider = Provider<Map<int, int>>((ref) {
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  final decks = ref.watch(decksStreamProvider).value ?? const [];
  final books = ref.watch(booksStreamProvider).value ?? const [];
  final decksById = {for (final deck in decks) deck.id: deck};
  final booksById = {for (final book in books) book.id: book};
  final now = DateTime.now();
  final map = <int, int>{};
  for (final c in cards) {
    if (c.isDueAt(now)) {
      final deck = decksById[c.deckId];
      final book = deck == null ? null : booksById[deck.bookId];
      if (book != null) {
        map[book.categoryId] = (map[book.categoryId] ?? 0) + 1;
      }
    }
  }
  return map;
});

/// ── آمار و گیمیفیکیشن ────────────────────────────────────────────

/// آمار مطالعه‌ی محاسبه‌شده.
final statsProvider = Provider<StudyStats>((ref) {
  final logs = ref.watch(reviewLogsStreamProvider).value ?? const [];
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  return StudyStats.compute(logs: logs, totalCards: cards.length);
});

/// کارت‌های «ضعیف» — مبنای نشست مرور نقاط ضعف.
final weakCardsProvider = Provider<List<FlashCard>>((ref) {
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  final logs = ref.watch(reviewLogsStreamProvider).value ?? const [];
  return WeakCards.select(cards, logs);
});

/// تعداد مرور به تفکیک روز — مبنای نقشه‌ی حرارتی فعالیت.
final dailyActivityProvider = Provider<Map<DateTime, int>>((ref) {
  final logs = ref.watch(reviewLogsStreamProvider).value ?? const [];
  return Activity.dailyCounts(logs);
});

/// پیش‌بینی کارت‌های سررسید برای ۷ روز آینده.
final forecastProvider = Provider<List<int>>((ref) {
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  return Activity.forecast(cards, days: 7);
});

/// سطح و XP کاربر (از روی تعداد کل مرورها).
final levelProvider = Provider<LevelInfo>((ref) {
  final logs = ref.watch(reviewLogsStreamProvider).value ?? const [];
  return Gamification.levelFromXp(Gamification.xpFromLogs(logs));
});

/// فهرست دستاوردها با میزان پیشرفت.
final achievementsProvider = Provider<List<Achievement>>((ref) {
  final stats = ref.watch(statsProvider);
  final logs = ref.watch(reviewLogsStreamProvider).value ?? const [];
  final cards = ref.watch(allCardsStreamProvider).value ?? const [];
  final level = ref.watch(levelProvider).level;
  return Achievements.evaluate(
    totalReviews: logs.length,
    streakDays: stats.streakDays,
    weeklyAccuracy: stats.weeklyAccuracy,
    totalCards: cards.length,
    level: level,
  );
});

/// ── Freemium / Premium ──────────────────────────────────────────

/// آیا کاربر نسخه حرفه‌ای دارد؟ از تنظیمات خوانده می‌شود.
final isProProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).isPro,
);

/// تعداد دسته‌بندی‌های فعلی.
final categoryCountProvider = Provider<int>(
  (ref) => ref.watch(categoriesStreamProvider).value?.length ?? 0,
);

/// تعداد کتاب‌های یک دسته (family).
final bookCountProvider = Provider.family<int, int>((ref, categoryId) {
  final books = ref.watch(booksStreamProvider).value ?? const [];
  return books.where((b) => b.categoryId == categoryId).length;
});

/// تعداد دک‌های یک کتاب (family).
final deckCountProvider = Provider.family<int, int>((ref, bookId) {
  final decks = ref.watch(decksStreamProvider).value ?? const [];
  return decks.where((d) => d.bookId == bookId).length;
});

/// تعداد کارت‌های یک دک (family).
final cardsInDeckCountProvider = Provider.family<int, int>((ref, deckId) {
  final cards = ref.watch(deckCardsProvider(deckId)).value?.length ?? 0;
  return cards;
});
