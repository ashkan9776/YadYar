import 'package:flutter_test/flutter_test.dart';
import 'package:yadyar/data/models/flashcard.dart';
import 'package:yadyar/data/models/review_log.dart';
import 'package:yadyar/domain/weak_cards.dart';

FlashCard _card(int id, {double ease = 2.5, int reps = 1}) => FlashCard(
      id: id,
      deckId: 1,
      front: 'س$id',
      back: 'ج$id',
      nextReview: DateTime(2026),
      easeFactor: ease,
      repetitions: reps,
    );

/// دقیقه‌ها ترتیب زمانی لاگ‌ها را مشخص می‌کنند.
ReviewLog _log(int cardId, int quality, {int min = 0}) => ReviewLog(
      cardId: cardId,
      deckId: 1,
      quality: quality,
      reviewedAt: DateTime(2026, 1, 1).add(Duration(minutes: min)),
      durationMs: 1000,
    );

void main() {
  test('کارت با دو «سخت» متوالی ضعیف شمرده می‌شود', () {
    final cards = [_card(1), _card(2)];
    final logs = [_log(1, 3, min: 1), _log(1, 3, min: 2), _log(2, 5)];
    final weak = WeakCards.select(cards, logs);
    expect(weak.map((c) => c.id), [1]);
  });

  test('یک «سخت» همراه ضریب سهولت پایین، ضعیف است', () {
    final cards = [_card(1, ease: 2.0)];
    final weak = WeakCards.select(cards, [_log(1, 3)]);
    expect(weak.map((c) => c.id), [1]);
  });

  test('کارت آسان با ضریب بالا ضعیف نیست', () {
    final cards = [_card(1, ease: 2.6)];
    final weak = WeakCards.select(cards, [_log(1, 5), _log(1, 4)]);
    expect(weak, isEmpty);
  });

  test('ضعیف‌ترها بر اساس «سخت»های متوالی مرتب می‌شوند', () {
    final cards = [_card(1), _card(2), _card(3)];
    final logs = [
      _log(1, 3, min: 1), _log(1, 3, min: 2), // ۲ سخت متوالی
      _log(2, 3, min: 3), _log(2, 3, min: 4), _log(2, 3, min: 5), // ۳ سخت متوالی
      _log(3, 3, min: 6), _log(3, 3, min: 7), // ۲ سخت متوالی
    ];
    final weak = WeakCards.select(cards, logs);
    expect(weak.first.id, 2); // بیشترین «سخت» متوالی اول
  });

  group('خروج از نقاط ضعف پس از مرور موفق', () {
    test('مرور خوب بعد از سخت‌ها، ریست می‌کند و کارت ضعیف نیست', () {
      final cards = [_card(1)];
      final logs = [
        _log(1, 3, min: 1),
        _log(1, 3, min: 2),
        _log(1, 4, min: 3), // مرور موفق → ریست
      ];
      expect(WeakCards.select(cards, logs), isEmpty);
    });

    test('سخت‌های قدیمی قبل از آخرین مرور موفق حساب نمی‌شوند', () {
      final cards = [_card(1)];
      final logs = [
        _log(1, 3, min: 1),
        _log(1, 3, min: 2),
        _log(1, 5, min: 3), // آسون → ریست
        _log(1, 3, min: 4), // فقط یک سخت اخیر
      ];
      // یک سختِ اخیر + ضریب پایین ضعیف است؛ با ضریب بالا (۲.۵) نه.
      expect(WeakCards.select(cards, logs), isEmpty);
    });

    test('سختِ اخیر با ضریب پایین همچنان ضعیف است', () {
      final cards = [_card(1, ease: 2.0)];
      final logs = [
        _log(1, 3, min: 1),
        _log(1, 4, min: 2), // ریست
        _log(1, 3, min: 3), // یک سخت اخیر + ضریب ۲.۰
      ];
      final weak = WeakCards.select(cards, logs);
      expect(weak.map((c) => c.id), [1]);
    });

    test('لاگ‌ها با ترتیب ورودی به‌هم‌ریخته هم درست حساب می‌شوند', () {
      final cards = [_card(1)];
      final logs = [
        _log(1, 4, min: 5), // آخر از همه: موفق → ریست
        _log(1, 3, min: 1),
        _log(1, 3, min: 2),
      ];
      expect(WeakCards.select(cards, logs), isEmpty);
    });
  });
}
