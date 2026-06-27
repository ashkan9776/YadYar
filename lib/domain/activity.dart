import '../data/models/flashcard.dart';
import '../data/models/review_log.dart';

/// محاسبات فعالیت مطالعه: نقشه‌ی حرارتی روزانه و پیش‌بینی سررسید مرورها.
/// منطق خالص و قابل‌تست.
class Activity {
  Activity._();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// تعداد مرور به تفکیک روز (کلید: تاریخِ بدون ساعت).
  static Map<DateTime, int> dailyCounts(List<ReviewLog> logs) {
    final map = <DateTime, int>{};
    for (final l in logs) {
      final d = _dateOnly(l.reviewedAt);
      map[d] = (map[d] ?? 0) + 1;
    }
    return map;
  }

  /// پیش‌بینی تعداد کارتِ سررسید برای [days] روز آینده (از امروز).
  /// کارت‌های عقب‌افتاده در «امروز» (اندیس ۰) شمرده می‌شوند.
  static List<int> forecast(
    List<FlashCard> cards, {
    int days = 7,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final counts = List<int>.filled(days, 0);
    for (final c in cards) {
      var idx = _dateOnly(c.nextReview).difference(today).inDays;
      if (idx < 0) idx = 0; // عقب‌افتاده → امروز
      if (idx >= 0 && idx < days) counts[idx]++;
    }
    return counts;
  }
}
