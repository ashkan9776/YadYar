import '../data/models/flashcard.dart';
import '../data/models/review_log.dart';

/// انتخاب «کارت‌های ضعیف» — کارت‌هایی که کاربر الان در آن‌ها می‌لنگد.
///
/// سیگنال‌ها: تعداد «سخت»های **متوالی** از آخرین مرور موفق به بعد (مرور
/// خوب/آسون ریست می‌کند) و ضریب سهولت SM-2 (هرچه کمتر، کارت سخت‌تر).
/// با یک مرور موفق، کارت از فهرست نقاط ضعف خارج می‌شود. منطق خالص و قابل‌تست.
class WeakCards {
  WeakCards._();

  static List<FlashCard> select(
    List<FlashCard> cards,
    List<ReviewLog> logs, {
    int maxCards = 40,
  }) {
    // لاگ‌ها به تفکیک کارت.
    final logsByCard = <int, List<ReviewLog>>{};
    for (final l in logs) {
      (logsByCard[l.cardId] ??= []).add(l);
    }

    // streak: تعداد «سخت»های متوالی از آخرین مرور موفق (کیفیت ≥ ۴) به بعد.
    final hardStreak = <int, int>{};
    logsByCard.forEach((cardId, cardLogs) {
      cardLogs.sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
      var streak = 0;
      for (final l in cardLogs) {
        streak = l.quality <= 3 ? streak + 1 : 0;
      }
      hardStreak[cardId] = streak;
    });

    bool isWeak(FlashCard c) {
      if (c.id == null) return false;
      final h = hardStreak[c.id] ?? 0;
      if (h >= 2) return true; // چند بار سخت پشت‌سرهم
      if (h >= 1 && c.easeFactor < 2.3) return true; // سخت + ضریب پایین
      if (c.repetitions > 0 && c.easeFactor <= 1.6) return true; // ضریب خیلی پایین
      return false;
    }

    final weak = cards.where(isWeak).toList();
    weak.sort((a, b) {
      final ha = hardStreak[a.id] ?? 0;
      final hb = hardStreak[b.id] ?? 0;
      if (hb != ha) return hb.compareTo(ha);
      return a.easeFactor.compareTo(b.easeFactor);
    });
    return weak.take(maxCards).toList();
  }
}
