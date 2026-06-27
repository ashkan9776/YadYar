import 'package:flutter_test/flutter_test.dart';
import 'package:yadyar/data/models/review_log.dart';
import 'package:yadyar/domain/gamification.dart';

ReviewLog _log() => ReviewLog(
    cardId: 1, deckId: 1, quality: 4, reviewedAt: DateTime(2026), durationMs: 0);

void main() {
  test('XP برابر ۱۰ به‌ازای هر مرور', () {
    expect(Gamification.xpFromLogs(List.generate(7, (_) => _log())), 70);
  });

  test('سطح ۱ برای XP صفر', () {
    final lvl = Gamification.levelFromXp(0);
    expect(lvl.level, 1);
    expect(lvl.xpIntoLevel, 0);
  });

  test('آستانه‌ها صعودی‌اند و سطح درست محاسبه می‌شود', () {
    // threshold: L2=100, L3=300, L4=600
    expect(Gamification.levelFromXp(100).level, 2);
    expect(Gamification.levelFromXp(299).level, 2);
    expect(Gamification.levelFromXp(300).level, 3);
  });

  test('پیشرفت داخل سطح بین ۰ و ۱ است', () {
    final lvl = Gamification.levelFromXp(150); // سطح ۲ (۱۰۰..۳۰۰)
    expect(lvl.level, 2);
    expect(lvl.xpIntoLevel, 50);
    expect(lvl.xpForNext, 200);
    expect(lvl.progress, closeTo(0.25, 1e-9));
  });

  test('دستاوردها بر اساس پیشرفت قفل/باز می‌شوند', () {
    final list = Achievements.evaluate(
      totalReviews: 60,
      streakDays: 4,
      weeklyAccuracy: 0.95,
      totalCards: 10,
      level: 2,
    );
    final byId = {for (final a in list) a.id: a};
    expect(byId['first']!.unlocked, isTrue);
    expect(byId['r50']!.unlocked, isTrue);
    expect(byId['r100']!.unlocked, isFalse);
    expect(byId['s3']!.unlocked, isTrue);
    expect(byId['acc']!.unlocked, isTrue);
    expect(byId['maker']!.unlocked, isFalse);
  });
}
