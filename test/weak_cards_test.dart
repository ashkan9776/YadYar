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

ReviewLog _log(int cardId, int quality) => ReviewLog(
      cardId: cardId,
      deckId: 1,
      quality: quality,
      reviewedAt: DateTime(2026),
      durationMs: 1000,
    );

void main() {
  test('کارت با دو بار «سخت» ضعیف شمرده می‌شود', () {
    final cards = [_card(1), _card(2)];
    final logs = [_log(1, 3), _log(1, 3), _log(2, 5)];
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

  test('ضعیف‌ترها بر اساس تعداد «سخت» مرتب می‌شوند', () {
    final cards = [_card(1), _card(2), _card(3)];
    final logs = [
      _log(1, 3), _log(1, 3), // ۲ سخت
      _log(2, 3), _log(2, 3), _log(2, 3), // ۳ سخت
      _log(3, 3), _log(3, 3), // ۲ سخت
    ];
    final weak = WeakCards.select(cards, logs);
    expect(weak.first.id, 2); // بیشترین «سخت» اول
  });
}
