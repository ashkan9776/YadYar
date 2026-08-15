import 'package:flutter_test/flutter_test.dart';
import 'package:yadyar/data/models/app_settings.dart';
import 'package:yadyar/data/models/flashcard.dart';
import 'package:yadyar/domain/daily_challenge.dart';

FlashCard _card(int id, {DateTime? due}) => FlashCard(
      id: id,
      deckId: 1,
      front: 'س$id',
      back: 'ج$id',
      nextReview: due ?? DateTime(2026, 1, 1),
    );

void main() {
  final today = DateTime(2026, 8, 15);

  group('selectDailyCards', () {
    test('انتخاب در طول روز قطعی است', () {
      final cards = List.generate(30, (i) => _card(i, due: today));
      final a = DailyChallenge.selectDailyCards(cards, today);
      final b = DailyChallenge.selectDailyCards(cards, today);
      expect(a.map((c) => c.id), b.map((c) => c.id));
      expect(a.length, DailyChallenge.cardCount);
    });

    test('در روزهای مختلف انتخاب متفاوت است', () {
      final cards = List.generate(30, (i) => _card(i, due: today));
      final a = DailyChallenge.selectDailyCards(cards, today);
      final b =
          DailyChallenge.selectDailyCards(cards, today.add(const Duration(days: 1)));
      expect(a.map((c) => c.id), isNot(b.map((c) => c.id)));
    });

    test('کارت سررسیدشده بر کارت غیرسررسید اولویت دارد', () {
      final cards = [
        ...List.generate(12, (i) => _card(i, due: today)), // سررسیدشده
        ...List.generate(12, (i) => _card(100 + i,
            due: today.add(const Duration(days: 30)))), // آینده
      ];
      final picked = DailyChallenge.selectDailyCards(cards, today);
      expect(picked.length, DailyChallenge.cardCount);
      // هر ۱۰ کارت انتخابی باید از گروه سررسیدشده باشند.
      expect(picked.every((c) => c.id! < 100), isTrue);
    });

    test('با کارت کمتر از سقف، همه انتخاب می‌شوند', () {
      final cards = List.generate(4, (i) => _card(i, due: today));
      expect(DailyChallenge.selectDailyCards(cards, today).length, 4);
    });

    test('لیست خالی → خالی', () {
      expect(DailyChallenge.selectDailyCards(const [], today), isEmpty);
    });
  });

  group('استریک چالش', () {
    test('اولین چالش → استریک ۱', () {
      final s = DailyChallenge.markCompleted(const AppSettings(), today);
      expect(s.challengeStreak, 1);
      expect(s.challengeBestStreak, 1);
      expect(s.lastChallengeDay, '2026-08-15');
    });

    test('چالش دیروز → استریک +۱', () {
      final s = const AppSettings(
        challengeStreak: 4,
        challengeBestStreak: 6,
        lastChallengeDay: '2026-08-14',
      );
      final r = DailyChallenge.markCompleted(s, today);
      expect(r.challengeStreak, 5);
      expect(r.challengeBestStreak, 6);
    });

    test('شکستن استریک → ریست به ۱ و حفظ رکورد', () {
      final s = const AppSettings(
        challengeStreak: 7,
        challengeBestStreak: 7,
        lastChallengeDay: '2026-08-10',
      );
      final r = DailyChallenge.markCompleted(s, today);
      expect(r.challengeStreak, 1);
      expect(r.challengeBestStreak, 7);
    });

    test('ثبت دوباره در همان روز → بدون تغییر', () {
      final s = const AppSettings(
        challengeStreak: 3,
        challengeBestStreak: 5,
        lastChallengeDay: '2026-08-15',
      );
      expect(DailyChallenge.isCompletedToday(s, today), isTrue);
      final r = DailyChallenge.markCompleted(s, today);
      expect(r.challengeStreak, 3);
      expect(r.challengeBestStreak, 5);
    });

    test('استریک جدید از رکورد رد می‌شود → رکورد آپدیت', () {
      final s = const AppSettings(
        challengeStreak: 9,
        challengeBestStreak: 9,
        lastChallengeDay: '2026-08-14',
      );
      final r = DailyChallenge.markCompleted(s, today);
      expect(r.challengeStreak, 10);
      expect(r.challengeBestStreak, 10);
    });
  });
}
