import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/celebrations/celebration_overlay.dart';
import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/gamification.dart';
import '../../providers/providers.dart';

/// داشبورد آمار پیشرفت.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  /// شناسه‌های دستاوردهایی که قبلاً باز شده و جشنشان نمایش داده شده.
  final Set<String> _celebratedIds = {};

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final forecast = ref.watch(forecastProvider);
    final activity = ref.watch(dailyActivityProvider);
    final achievements = ref.watch(achievementsProvider);

    // بررسی دستاوردهای جدید — اگر دستاوردی تازه باز شده، جشن نمایش بده.
    for (final a in achievements) {
      if (a.unlocked && !_celebratedIds.contains(a.id)) {
        _celebratedIds.add(a.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            CelebrationOverlay.showAchievement(
                context, a.title, a.description);
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('آمار'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(Fa.monthYear(DateTime.now()),
                style: TextStyle(
                    fontSize: 13, color: context.colors.textMuted)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _BigStat(
                    value: Fa.number(stats.monthCardsReviewed),
                    label: 'کارت مرور شده',
                    color: context.colors.accent,
                    icon: Icons.style_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BigStat(
                    value: _formatTime(stats.monthStudyMinutes),
                    label: 'زمان مطالعه',
                    color: context.colors.teal,
                    icon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BigStat(
                    value: Fa.digits(stats.streakDays),
                    label: 'روز استریک',
                    color: context.colors.amber,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BigStat(
                    value: Fa.number(stats.totalCards),
                    label: 'کل کارت‌ها',
                    color: context.colors.purple200,
                    icon: Icons.collections_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('توزیع دقت',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 16),
            if (stats.totalRated == 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.bg2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.colors.border),
                ),
                child: Center(
                  child: Text('هنوز این ماه مروری ثبت نشده',
                      style: TextStyle(color: context.colors.textMuted)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.bg2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  children: [
                    _AccuracyBar(
                        label: 'آسون',
                        pct: stats.easyPct,
                        color: context.colors.teal),
                    const SizedBox(height: 12),
                    _AccuracyBar(
                        label: 'خوب',
                        pct: stats.goodPct,
                        color: context.colors.accent),
                    const SizedBox(height: 12),
                    _AccuracyBar(
                        label: 'سخت',
                        pct: stats.hardPct,
                        color: context.colors.red),
                  ],
                ),
              ),
            const SizedBox(height: 28),
            Text('پیش‌بینی مرور (۷ روز آینده)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 16),
            _ForecastChart(counts: forecast),
            const SizedBox(height: 28),
            Text('نقشه‌ی فعالیت',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 16),
            _ActivityHeatmap(counts: activity),
            const SizedBox(height: 28),
            Text('دستاوردها',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 16),
            _AchievementsGrid(achievements: achievements),
          ],
        ),
      ),
    );
  }

  static String _formatTime(int minutes) {
    if (minutes < 60) return '${Fa.digits(minutes)} دقیقه';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${Fa.digits(h)} ساعت';
    return '${Fa.digits(h)}س ${Fa.digits(m)}د';
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: context.colors.textMuted)),
        ],
      ),
    );
  }
}

class _AccuracyBar extends StatelessWidget {
  const _AccuracyBar(
      {required this.label, required this.pct, required this.color});
  final String label;
  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, color: context.colors.textSecondary)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 12, color: context.colors.bg3),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(height: 12, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text('${Fa.digits((pct * 100).round())}٪',
              textAlign: TextAlign.left,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ),
      ],
    );
  }
}

/// نمودار میله‌ای پیش‌بینی کارت‌های سررسید ۷ روز آینده.
class _ForecastChart extends StatelessWidget {
  const _ForecastChart({required this.counts});
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxVal = counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b);
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: c.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: maxVal == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('کارتی برای روزهای آینده زمان‌بندی نشده',
                    style: TextStyle(color: c.textMuted)),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < counts.length; i++)
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + i * 80),
                      curve: Curves.easeOut,
                      builder: (context, val, child) => Opacity(
                        opacity: val.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - val)),
                          child: child,
                        ),
                      ),
                      child: _ForecastBar(
                        count: counts[i],
                        maxVal: maxVal,
                        label: i == 0
                            ? 'امروز'
                            : Fa.weekdayShort(today.add(Duration(days: i))),
                        highlight: i == 0,
                        index: i,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ForecastBar extends StatelessWidget {
  const _ForecastBar({
    required this.count,
    required this.maxVal,
    required this.label,
    required this.highlight,
    required this.index,
  });
  final int count;
  final int maxVal;
  final String label;
  final bool highlight;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = highlight ? c.accent : c.teal;
    final frac = maxVal == 0 ? 0.0 : count / maxVal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count == 0 ? '' : Fa.digits(count),
            style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: frac),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Container(
            height: 8 + value * 80,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: count == 0 ? c.bg3 : color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(5),
              boxShadow: count == 0
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 10, color: c.textMuted)),
      ],
    );
  }
}

/// نقشه‌ی حرارتی فعالیت مطالعه (مثل گیت‌هاب) — ۱۵ هفته‌ی اخیر.
class _ActivityHeatmap extends StatefulWidget {
  const _ActivityHeatmap({required this.counts});
  final Map<DateTime, int> counts;

  @override
  State<_ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<_ActivityHeatmap> {
  static const _weeks = 15;
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final counts = widget.counts;
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // شروع از شنبه‌ی ۱۵ هفته قبل.
    final daysSinceSaturday = (today.weekday - DateTime.saturday) % 7;
    final start =
        today.subtract(Duration(days: daysSinceSaturday + (_weeks - 1) * 7));
    final maxVal =
        counts.values.isEmpty ? 0 : counts.values.reduce((a, b) => a > b ? a : b);

    Color cellColor(DateTime day) {
      if (day.isAfter(today)) return Colors.transparent;
      final v = counts[day] ?? 0;
      if (v == 0) return c.bg3;
      final t = maxVal == 0 ? 1.0 : v / maxVal;
      return c.accent.withValues(alpha: 0.3 + 0.7 * t);
    }

    // نمایش tooltip وقتی روزی انتخاب شده.
    Widget? tooltip;
    if (_selectedDay != null && !_selectedDay!.isAfter(today)) {
      final v = counts[_selectedDay] ?? 0;
      tooltip = Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.bg3,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              v == 0
                  ? Fa.fullDate(_selectedDay!)
                  : '${Fa.digits(v)} مرور — ${Fa.fullDate(_selectedDay!)}',
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?tooltip,
          // شبکه‌ی هفته‌ها — قدیمی‌ترین چپ، جدیدترین راست (جهت LTR).
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var w = 0; w < _weeks; w++)
                  Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        GestureDetector(
                          onTap: () {
                            final day = start.add(Duration(days: w * 7 + d));
                            if (day.isAfter(today)) return;
                            setState(() {
                              _selectedDay =
                                  _selectedDay == day ? null : day;
                            });
                          },
                          child: Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: cellColor(
                                  start.add(Duration(days: w * 7 + d))),
                              borderRadius: BorderRadius.circular(3),
                              border: _selectedDay ==
                                      start.add(Duration(days: w * 7 + d))
                                  ? Border.all(color: c.textPrimary, width: 1.5)
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('کم',
                  style: TextStyle(fontSize: 10, color: c.textMuted)),
              const SizedBox(width: 6),
              for (final a in [0.0, 0.4, 0.7, 1.0])
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color:
                        a == 0 ? c.bg3 : c.accent.withValues(alpha: 0.3 + 0.7 * a),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const SizedBox(width: 6),
              Text('زیاد',
                  style: TextStyle(fontSize: 10, color: c.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// شبکه‌ی نشان‌های دستاورد (باز/قفل با میزان پیشرفت).
class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.achievements});
  final List<Achievement> achievements;

  static IconData _iconFor(AchievementKind kind) {
    switch (kind) {
      case AchievementKind.reviews:
        return Icons.school_rounded;
      case AchievementKind.streak:
        return Icons.local_fire_department_rounded;
      case AchievementKind.accuracy:
        return Icons.gps_fixed_rounded;
      case AchievementKind.cards:
        return Icons.style_rounded;
      case AchievementKind.level:
        return Icons.military_tech_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: [
        for (final a in achievements)
          _BadgeTile(achievement: a, icon: _iconFor(a.kind)),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.achievement, required this.icon});
  final Achievement achievement;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unlocked = achievement.unlocked;
    final color = unlocked ? c.amber : c.textMuted;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked ? c.amber.withValues(alpha: 0.10) : c.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: unlocked ? c.amber.withValues(alpha: 0.4) : c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: unlocked ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(achievement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: unlocked ? c.textPrimary : c.textSecondary)),
                const SizedBox(height: 4),
                if (unlocked)
                  Text('باز شد ✓',
                      style: TextStyle(fontSize: 10, color: c.amber))
                else
                  Text(
                      '${Fa.digits(achievement.current.clamp(0, achievement.goal))} / ${Fa.digits(achievement.goal)}',
                      style: TextStyle(fontSize: 10, color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
