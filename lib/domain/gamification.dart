import '../data/models/review_log.dart';

/// وضعیت سطح و XP کاربر.
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.xp,
    required this.xpIntoLevel,
    required this.xpForNext,
  });

  final int level;
  final int xp; // کل XP
  final int xpIntoLevel; // XP کسب‌شده در سطح فعلی
  final int xpForNext; // XP لازم برای کل این سطح

  double get progress => xpForNext == 0 ? 1 : (xpIntoLevel / xpForNext).clamp(0, 1);
  int get xpRemaining => (xpForNext - xpIntoLevel).clamp(0, xpForNext);
}

/// محاسبات گیمیفیکیشن — XP و سطح. منطق خالص و قابل‌تست.
class Gamification {
  Gamification._();

  static const xpPerReview = 10;

  static int xpFromLogs(List<ReviewLog> logs) => logs.length * xpPerReview;

  /// مجموع XP لازم برای رسیدن به آغاز سطح [level].
  static int thresholdFor(int level) => 50 * (level - 1) * level;

  static LevelInfo levelFromXp(int xp) {
    var level = 1;
    while (xp >= thresholdFor(level + 1)) {
      level++;
    }
    final base = thresholdFor(level);
    final next = thresholdFor(level + 1);
    return LevelInfo(
      level: level,
      xp: xp,
      xpIntoLevel: xp - base,
      xpForNext: next - base,
    );
  }
}

/// دسته‌بندی دستاورد — برای انتخاب آیکن در لایه‌ی UI (دامین مستقل از Flutter).
enum AchievementKind { reviews, streak, accuracy, cards, level }

/// یک دستاورد با میزان پیشرفت فعلی.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.goal,
    required this.current,
  });

  final String id;
  final String title;
  final String description;
  final AchievementKind kind;
  final int goal;
  final int current;

  bool get unlocked => current >= goal;
  double get progress => goal == 0 ? 1 : (current / goal).clamp(0, 1);
}

class Achievements {
  Achievements._();

  static List<Achievement> evaluate({
    required int totalReviews,
    required int streakDays,
    required double weeklyAccuracy,
    required int totalCards,
    required int level,
  }) {
    return [
      Achievement(
        id: 'first',
        title: 'اولین قدم',
        description: 'اولین مرورت رو انجام بده',
        kind: AchievementKind.reviews,
        goal: 1,
        current: totalReviews,
      ),
      Achievement(
        id: 'r50',
        title: 'گرم شدی',
        description: '۵۰ مرور انجام بده',
        kind: AchievementKind.reviews,
        goal: 50,
        current: totalReviews,
      ),
      Achievement(
        id: 'r100',
        title: 'صدتایی',
        description: '۱۰۰ مرور انجام بده',
        kind: AchievementKind.reviews,
        goal: 100,
        current: totalReviews,
      ),
      Achievement(
        id: 'r500',
        title: 'حرفه‌ای',
        description: '۵۰۰ مرور انجام بده',
        kind: AchievementKind.reviews,
        goal: 500,
        current: totalReviews,
      ),
      Achievement(
        id: 's3',
        title: 'سه روز پیاپی',
        description: 'استریک ۳ روزه بساز',
        kind: AchievementKind.streak,
        goal: 3,
        current: streakDays,
      ),
      Achievement(
        id: 's7',
        title: 'یک هفته‌ی کامل',
        description: 'استریک ۷ روزه بساز',
        kind: AchievementKind.streak,
        goal: 7,
        current: streakDays,
      ),
      Achievement(
        id: 's30',
        title: 'یک ماه بی‌وقفه',
        description: 'استریک ۳۰ روزه بساز',
        kind: AchievementKind.streak,
        goal: 30,
        current: streakDays,
      ),
      Achievement(
        id: 'acc',
        title: 'دقیق',
        description: 'دقت هفتگی ۹۰٪ یا بیشتر',
        kind: AchievementKind.accuracy,
        goal: 90,
        current: (weeklyAccuracy * 100).round(),
      ),
      Achievement(
        id: 'maker',
        title: 'سازنده',
        description: '۵۰ کارت بساز',
        kind: AchievementKind.cards,
        goal: 50,
        current: totalCards,
      ),
      Achievement(
        id: 'lv5',
        title: 'سطح ۵',
        description: 'به سطح ۵ برس',
        kind: AchievementKind.level,
        goal: 5,
        current: level,
      ),
    ];
  }
}
