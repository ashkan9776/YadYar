import 'package:flutter_test/flutter_test.dart';
import 'package:yadyar/domain/sm2.dart';

void main() {
  final today = DateTime(2026, 6, 14);

  group('SM-2', () {
    test('کارت جدید با پاسخ خوب → فاصله ۱ روز', () {
      final r = Sm2.schedule(
        quality: 4,
        repetitions: 0,
        easeFactor: 2.5,
        interval: 0,
        now: today,
      );
      expect(r.interval, 1);
      expect(r.repetitions, 1);
      expect(r.nextReview, DateTime(2026, 6, 15));
    });

    test('مرور دوم موفق → فاصله ۶ روز', () {
      final r = Sm2.schedule(
        quality: 4,
        repetitions: 1,
        easeFactor: 2.5,
        interval: 1,
        now: today,
      );
      expect(r.interval, 6);
      expect(r.repetitions, 2);
    });

    test('مرور سوم → فاصله = round(interval * EF)', () {
      final r = Sm2.schedule(
        quality: 4,
        repetitions: 2,
        easeFactor: 2.5,
        interval: 6,
        now: today,
      );
      expect(r.interval, (6 * 2.5).round()); // 15
      expect(r.repetitions, 3);
    });

    test('پاسخ سخت (q=3) ضریب سهولت را کاهش می‌دهد', () {
      final r = Sm2.schedule(
        quality: 3,
        repetitions: 2,
        easeFactor: 2.5,
        interval: 6,
        now: today,
      );
      expect(r.easeFactor, lessThan(2.5));
    });

    test('پاسخ آسون (q=5) ضریب سهولت را افزایش می‌دهد', () {
      final r = Sm2.schedule(
        quality: 5,
        repetitions: 2,
        easeFactor: 2.5,
        interval: 6,
        now: today,
      );
      expect(r.easeFactor, greaterThan(2.5));
    });

    test('ضریب سهولت هرگز زیر ۱.۳ نمی‌رود', () {
      var ef = 1.3;
      for (var i = 0; i < 10; i++) {
        final r = Sm2.schedule(
          quality: 3,
          repetitions: 5,
          easeFactor: ef,
          interval: 10,
          now: today,
        );
        ef = r.easeFactor;
      }
      expect(ef, greaterThanOrEqualTo(Sm2.minEaseFactor));
    });

    test('پاسخ نادرست (q<3) شمارش را صفر و فاصله را ۱ می‌کند', () {
      final r = Sm2.schedule(
        quality: 1,
        repetitions: 5,
        easeFactor: 2.5,
        interval: 30,
        now: today,
      );
      expect(r.repetitions, 0);
      expect(r.interval, 1);
    });
  });
}
