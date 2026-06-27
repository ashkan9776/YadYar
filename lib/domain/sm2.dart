import '../data/models/flashcard.dart';

/// نتیجه‌ی یک گام از الگوریتم SM-2.
class Sm2Result {
  const Sm2Result({
    required this.interval,
    required this.easeFactor,
    required this.repetitions,
    required this.nextReview,
  });

  final int interval;
  final double easeFactor;
  final int repetitions;
  final DateTime nextReview;
}

/// پیاده‌سازی الگوریتم تکرار فاصله‌دار SuperMemo-2 (SM-2).
///
/// ورودی [quality] کیفیت پاسخ است (۰ تا ۵)؛ در یادیار از سه دکمه استفاده می‌شود:
/// سخت=۳، خوب=۴، آسون=۵. اگر کیفیت کمتر از ۳ باشد کارت «فراموش‌شده» تلقی شده و
/// شمارش تکرار صفر و فاصله به ۱ روز بازنشانی می‌شود.
class Sm2 {
  Sm2._();

  static const double minEaseFactor = 1.3;
  static const double defaultEaseFactor = 2.5;

  static Sm2Result schedule({
    required int quality,
    required int repetitions,
    required double easeFactor,
    required int interval,
    DateTime? now,
  }) {
    assert(quality >= 0 && quality <= 5, 'quality باید بین ۰ تا ۵ باشد');
    final today = _dateOnly(now ?? DateTime.now());

    int reps = repetitions;
    double ef = easeFactor;
    int ivl = interval;

    if (quality < 3) {
      // پاسخ نادرست — از نو شروع کن.
      reps = 0;
      ivl = 1;
    } else {
      if (reps == 0) {
        ivl = 1;
      } else if (reps == 1) {
        ivl = 6;
      } else {
        ivl = (ivl * ef).round();
      }
      reps += 1;
    }

    // به‌روزرسانی ضریب سهولت طبق فرمول استاندارد SM-2.
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (ef < minEaseFactor) ef = minEaseFactor;

    if (ivl < 1) ivl = 1;

    return Sm2Result(
      interval: ivl,
      easeFactor: ef,
      repetitions: reps,
      nextReview: today.add(Duration(days: ivl)),
    );
  }

  /// اعمال نتیجه SM-2 روی یک کارت و بازگرداندن نسخه به‌روزشده.
  static FlashCard apply(FlashCard card, int quality, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final r = schedule(
      quality: quality,
      repetitions: card.repetitions,
      easeFactor: card.easeFactor,
      interval: card.interval,
      now: at,
    );
    return card.copyWith(
      interval: r.interval,
      easeFactor: r.easeFactor,
      repetitions: r.repetitions,
      nextReview: r.nextReview,
      lastReviewed: at,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
