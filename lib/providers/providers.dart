import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/models/app_settings.dart';
import '../data/models/deck.dart';
import '../data/models/flashcard.dart';
import '../data/models/review_log.dart';
import '../data/repositories/card_repository.dart';
import '../data/repositories/deck_repository.dart';
import '../data/repositories/review_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/deck_share_service.dart';
import '../domain/activity.dart';
import '../domain/gamification.dart';
import '../domain/study_stats.dart';
import '../domain/weak_cards.dart';
import '../core/home_widget_service.dart';

/// نمونه‌ی دیتابیس — در main هنگام راه‌اندازی override می‌شود.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider باید override شود'),
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

/// سرویس اشتراک‌گذاری دک.
final deckShareServiceProvider = Provider<DeckShareService>(
  (ref) => DeckShareService(ref.watch(databaseProvider)),
);

/// جریان زنده‌ی تنظیمات کاربر.
final settingsStreamProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// تنظیمات جاری (یا پیش‌فرض تا وقتی جریان بارگذاری شود).
final settingsProvider = Provider<AppSettings>(
  (ref) =>
      ref.watch(settingsStreamProvider).value ?? AppSettings.defaults,
);

/// جریان زنده‌ی همه‌ی دک‌ها.
final decksStreamProvider = StreamProvider<List<Deck>>(
  (ref) => ref.watch(deckRepositoryProvider).watchAll(),
);

/// جریان زنده‌ی همه‌ی کارت‌ها (مبنای شمارش سررسیدها).
final allCardsStreamProvider = StreamProvider<List<FlashCard>>(
  (ref) => ref.watch(cardRepositoryProvider).watchAll(),
);

/// جریان زنده‌ی لاگ مرورها.
final reviewLogsStreamProvider = StreamProvider<List<ReviewLog>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchAll(),
);

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

/// هماهنگی تعداد سررسیدها با ویجت صفحه‌ی خانه — side-effect provider.
/// روی هر تغییر `totalDueProvider`، ویجت را به‌روز می‌کند.
final homeWidgetSyncProvider = Provider<void>((ref) {
  final due = ref.watch(totalDueProvider);
  HomeWidgetService.updateDueCount(due);
});

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

/// جریان زنده‌ی کارت‌های یک دک مشخص.
final deckCardsProvider =
    StreamProvider.family<List<FlashCard>, int>((ref, deckId) {
  return ref.watch(cardRepositoryProvider).watchByDeck(deckId);
});
