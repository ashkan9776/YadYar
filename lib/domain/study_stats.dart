import '../data/models/review_log.dart';

/// وضعیت یک روز در نوار استریک هفتگی.
enum DayStatus { done, missed, today, future }

class WeekDay {
  const WeekDay(this.label, this.status);
  final String label;
  final DayStatus status;
}

/// آمار مطالعه‌ی محاسبه‌شده از روی لاگ مرورها.
class StudyStats {
  const StudyStats({
    required this.streakDays,
    required this.weeklyAccuracy,
    required this.weekDays,
    required this.monthCardsReviewed,
    required this.monthStudyMinutes,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    required this.totalCards,
    required this.todayReviewed,
  });

  final int streakDays;
  final double weeklyAccuracy; // ۰..۱
  final List<WeekDay> weekDays;
  final int monthCardsReviewed;
  final int monthStudyMinutes;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final int totalCards;

  /// تعداد مرورهای ثبت‌شده‌ی امروز (مبنای هدف روزانه).
  final int todayReviewed;

  int get totalRated => hardCount + goodCount + easyCount;
  double get hardPct => totalRated == 0 ? 0 : hardCount / totalRated;
  double get goodPct => totalRated == 0 ? 0 : goodCount / totalRated;
  double get easyPct => totalRated == 0 ? 0 : easyCount / totalRated;

  static StudyStats compute({
    required List<ReviewLog> logs,
    required int totalCards,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    // مجموعه‌ی روزهایی که در آن‌ها مرور انجام شده + شمارش مرورهای امروز.
    final reviewedDays = <DateTime>{};
    var todayReviewed = 0;
    for (final l in logs) {
      final day = _dateOnly(l.reviewedAt);
      reviewedDays.add(day);
      if (day == today) todayReviewed++;
    }

    // استریک: تعداد روزهای پیاپی منتهی به امروز (یا دیروز) که مرور داشته‌اند.
    int streak = 0;
    var cursor = today;
    if (!reviewedDays.contains(today)) {
      cursor = today.subtract(const Duration(days: 1));
    }
    while (reviewedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // روزهای هفته جاری (شنبه تا جمعه).
    const labels = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    // weekday Dart: Mon=1..Sun=7. شنبه = Sat = 6.
    final daysSinceSaturday = (today.weekday - DateTime.saturday) % 7;
    final saturday = today.subtract(Duration(days: daysSinceSaturday));
    final weekDays = <WeekDay>[];
    for (var i = 0; i < 7; i++) {
      final day = saturday.add(Duration(days: i));
      DayStatus status;
      if (day == today) {
        status = DayStatus.today;
      } else if (day.isAfter(today)) {
        status = DayStatus.future;
      } else if (reviewedDays.contains(day)) {
        status = DayStatus.done;
      } else {
        status = DayStatus.missed;
      }
      weekDays.add(WeekDay(labels[i], status));
    }

    // دقت هفتگی: نسبت مرورهای «خوب/آسون» به کل مرورهای ۷ روز اخیر.
    final weekAgo = today.subtract(const Duration(days: 6));
    final weekLogs =
        logs.where((l) => !_dateOnly(l.reviewedAt).isBefore(weekAgo));
    final weekTotal = weekLogs.length;
    final weekGood = weekLogs.where((l) => l.quality >= 4).length;
    final weeklyAccuracy = weekTotal == 0 ? 0.0 : weekGood / weekTotal;

    // آمار ماه جاری.
    final monthStart = DateTime(today.year, today.month, 1);
    final monthLogs =
        logs.where((l) => !_dateOnly(l.reviewedAt).isBefore(monthStart));
    var monthCards = 0;
    var monthMs = 0;
    var hard = 0, good = 0, easy = 0;
    for (final l in monthLogs) {
      monthCards++;
      monthMs += l.durationMs;
      switch (l.quality) {
        case 3:
          hard++;
        case 4:
          good++;
        case 5:
          easy++;
      }
    }

    return StudyStats(
      streakDays: streak,
      weeklyAccuracy: weeklyAccuracy,
      weekDays: weekDays,
      monthCardsReviewed: monthCards,
      monthStudyMinutes: (monthMs / 60000).round(),
      hardCount: hard,
      goodCount: good,
      easyCount: easy,
      totalCards: totalCards,
      todayReviewed: todayReviewed,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
