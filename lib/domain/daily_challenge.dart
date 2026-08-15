import 'dart:math';

import '../data/models/app_settings.dart';
import '../data/models/flashcard.dart';

/// شناسه‌ی ساختگی برای «چالش روزانه» (کارت‌های ترکیبی امروز در همه‌ی دک‌ها).
const int kDailyChallenge = -3;

/// منطق چالش روزانه — هر روز تعداد ثابتی کارت قطعی از همه‌ی دک‌ها + استریک مخصوص.
///
/// انتخاب کارت با seed تاریخ روز قطعی است؛ یعنی با باز و بسته کردن اپ در طول
/// روز همان کارت‌ها انتخاب می‌شوند. اولویت با کارت‌های سررسیدشده‌ی امروز است و
/// اگر کافی نباشند با بقیه‌ی کارت‌ها تکمیل می‌شود. منطق خالص و قابل‌تست.
class DailyChallenge {
  DailyChallenge._();

  /// تعداد کارت‌های چالش هر روز.
  static const int cardCount = 10;

  /// کلید روز به‌صورت 'yyyy-mm-dd' — واحد شمارش روزهای چالش.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// seed قطعی از تاریخ روز.
  static int _seed(DateTime today) =>
      today.year * 10000 + today.month * 100 + today.day;

  /// انتخاب کارت‌های چالش: اول کارت‌های سررسیدشده‌ی امروز، بعد تکمیل با بقیه.
  /// ترتیب نهایی با shuffle قطعیِ seed روز تعیین می‌شود.
  static List<FlashCard> selectDailyCards(
    List<FlashCard> cards,
    DateTime today, {
    int maxCards = cardCount,
  }) {
    if (cards.isEmpty || maxCards <= 0) return const [];

    final due = <FlashCard>[];
    final rest = <FlashCard>[];
    for (final c in cards) {
      (c.isDueAt(today) ? due : rest).add(c);
    }

    final rng = Random(_seed(today));
    due.shuffle(rng);
    rest.shuffle(rng);
    return [...due, ...rest].take(maxCards).toList();
  }

  /// آیا چالش امروز کامل شده؟
  static bool isCompletedToday(AppSettings settings, DateTime today) =>
      settings.lastChallengeDay == dayKey(today);

  /// استریک پس از کامل‌کردن چالشِ امروز:
  /// دیروز → +۱، امروز (ثبت دوباره) → بدون تغییر، قبل از دیروز → ریست به ۱.
  static ({int streak, int best}) completionStreak(
    AppSettings settings,
    DateTime today,
  ) {
    if (isCompletedToday(settings, today)) {
      return (
        streak: settings.challengeStreak,
        best: settings.challengeBestStreak,
      );
    }
    final yesterday = dayKey(today.subtract(const Duration(days: 1)));
    final streak =
        settings.lastChallengeDay == yesterday ? settings.challengeStreak + 1 : 1;
    return (streak: streak, best: max(streak, settings.challengeBestStreak));
  }

  /// تنظیمات جدید پس از کامل‌شدن چالش امروز.
  static AppSettings markCompleted(AppSettings settings, DateTime today) {
    final r = completionStreak(settings, today);
    return settings.copyWith(
      challengeStreak: r.streak,
      challengeBestStreak: r.best,
      lastChallengeDay: dayKey(today),
    );
  }
}
