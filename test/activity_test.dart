import 'package:flutter_test/flutter_test.dart';
import 'package:yadyar/data/models/flashcard.dart';
import 'package:yadyar/data/models/review_log.dart';
import 'package:yadyar/domain/activity.dart';

FlashCard _cardDue(DateTime when) =>
    FlashCard(deckId: 1, front: 'س', back: 'ج', nextReview: when);

ReviewLog _log(DateTime at) => ReviewLog(
    cardId: 1, deckId: 1, quality: 4, reviewedAt: at, durationMs: 1000);

void main() {
  test('dailyCounts مرورها را به تفکیک روز می‌شمارد', () {
    final counts = Activity.dailyCounts([
      _log(DateTime(2026, 6, 22, 9)),
      _log(DateTime(2026, 6, 22, 21)),
      _log(DateTime(2026, 6, 20, 12)),
    ]);
    expect(counts[DateTime(2026, 6, 22)], 2);
    expect(counts[DateTime(2026, 6, 20)], 1);
  });

  test('forecast کارت‌ها را در روز درست قرار می‌دهد', () {
    final now = DateTime(2026, 6, 22, 10);
    final cards = [
      _cardDue(DateTime(2026, 6, 22)), // امروز
      _cardDue(DateTime(2026, 6, 23)), // فردا
      _cardDue(DateTime(2026, 6, 23)),
    ];
    final f = Activity.forecast(cards, days: 7, now: now);
    expect(f[0], 1);
    expect(f[1], 2);
    expect(f.length, 7);
  });

  test('forecast کارت‌های عقب‌افتاده را در امروز می‌شمارد', () {
    final now = DateTime(2026, 6, 22, 10);
    final cards = [_cardDue(DateTime(2026, 6, 18))]; // گذشته
    final f = Activity.forecast(cards, days: 7, now: now);
    expect(f[0], 1);
  });
}
