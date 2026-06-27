import '../data/models/flashcard.dart';
import '../data/models/review_log.dart';

/// انتخاب «کارت‌های ضعیف» — کارت‌هایی که کاربر در آن‌ها بیشتر می‌لنگد.
///
/// سیگنال‌ها: تعداد دفعاتی که کارت «سخت» (کیفیت ≤ ۳) ارزیابی شده، و ضریب
/// سهولت SM-2 (هرچه کمتر، کارت برای کاربر سخت‌تر). منطق خالص و قابل‌تست.
class WeakCards {
  WeakCards._();

  static List<FlashCard> select(
    List<FlashCard> cards,
    List<ReviewLog> logs, {
    int maxCards = 40,
  }) {
    final hardCount = <int, int>{};
    for (final l in logs) {
      if (l.quality <= 3) {
        hardCount[l.cardId] = (hardCount[l.cardId] ?? 0) + 1;
      }
    }

    bool isWeak(FlashCard c) {
      if (c.id == null) return false;
      final h = hardCount[c.id] ?? 0;
      if (h >= 2) return true; // چند بار سخت بوده
      if (h >= 1 && c.easeFactor < 2.3) return true; // سخت + ضریب پایین
      if (c.repetitions > 0 && c.easeFactor <= 1.6) return true; // ضریب خیلی پایین
      return false;
    }

    final weak = cards.where(isWeak).toList();
    weak.sort((a, b) {
      final ha = hardCount[a.id] ?? 0;
      final hb = hardCount[b.id] ?? 0;
      if (hb != ha) return hb.compareTo(ha);
      return a.easeFactor.compareTo(b.easeFactor);
    });
    return weak.take(maxCards).toList();
  }
}
