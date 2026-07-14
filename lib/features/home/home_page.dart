import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/celebrations/celebration_overlay.dart';
import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/gamification.dart';
import '../../domain/study_stats.dart';
import '../../providers/providers.dart';
import '../review/review_controller.dart';

/// صفحه‌ی خانه — اولین چیزی که کاربر هر روز می‌بیند.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// آخرین سطحی که مشاهده شده — اگر تغییر کند، جشن لول‌آپ نمایش داده می‌شود.
  int _lastSeenLevel = -1;

  @override
  Widget build(BuildContext context) {
    final due = ref.watch(totalDueProvider);
    final stats = ref.watch(statsProvider);
    final goal = ref.watch(settingsProvider).dailyGoal;
    final weakCount = ref.watch(weakCardsProvider).length;
    final level = ref.watch(levelProvider);

    // بررسی لول‌آپ: فقط وقتی سطح جدیدی کشف شود (نه اولین بار).
    if (_lastSeenLevel >= 1 && level.level > _lastSeenLevel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CelebrationOverlay.showLevelUp(context, level.level);
      });
    }
    _lastSeenLevel = level.level;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _Header(dueCount: due, level: level),
            const SizedBox(height: 16),
            _DailyGoalCard(done: stats.todayReviewed, goal: goal),
            const SizedBox(height: 24),
            _SectionLabel('استریک هفتگی'),
            const SizedBox(height: 12),
            _StreakRow(days: stats.weekDays),
            const SizedBox(height: 24),
            _StartReviewButton(dueCount: due),
            if (weakCount > 0) ...[
              const SizedBox(height: 12),
              _WeakPointsButton(count: weakCount),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: Fa.digits(stats.streakDays),
                    label: 'روز استریک',
                    color: context.colors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    value: '${Fa.digits((stats.weeklyAccuracy * 100).round())}٪',
                    label: 'دقت این هفته',
                    color: context.colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dueCount, required this.level});
  final int dueCount;
  final LevelInfo level;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'صبح بخیر 👋';
    if (h < 17) return 'ظهر بخیر 👋';
    if (h < 20) return 'عصر بخیر 👋';
    return 'شب بخیر 👋';
  }

  @override
  Widget build(BuildContext context) {
    final sub = dueCount > 0
        ? 'امروز ${Fa.digits(dueCount)} کارت منتظرته'
        : 'همه‌ی کارت‌های امروزت رو مرور کردی 🎉';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [context.colors.purple600, context.colors.accent],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colors.accent.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'یادیار',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
                    tooltip: 'جستجو',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    tooltip: 'تنظیمات',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_greeting,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 16),
          _LevelBar(level: level),
        ],
      ),
    );
  }
}

/// نوار سطح و XP داخل هدر خانه.
class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.level});
  final LevelInfo level;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text('سطح ${Fa.digits(level.level)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
            Text('${Fa.digits(level.xpIntoLevel)} / ${Fa.digits(level.xpForNext)} XP',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                  height: 8, color: Colors.white.withValues(alpha: 0.25)),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: level.progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  widthFactor: value,
                  child: Container(height: 8, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(fontSize: 12, color: context.colors.textMuted));
  }
}

/// کارت پیشرفت هدف روزانه — چند کارت از هدف امروز مرور شده.
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.done, required this.goal});
  final int done;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final reached = goal > 0 && done >= goal;
    final pct = goal == 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);
    final color = reached ? context.colors.teal : context.colors.accent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(reached ? 'به هدف امروز رسیدی 🎯' : 'هدف امروز',
                  style: TextStyle(
                      fontSize: 13, color: context.colors.textSecondary)),
              Text('${Fa.digits(done)} از ${Fa.digits(goal)}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 10, color: context.colors.bg3),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(height: 10, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.days});
  final List<WeekDay> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final d in days) _StreakDot(d),
      ],
    );
  }
}

class _StreakDot extends StatelessWidget {
  const _StreakDot(this.day);
  final WeekDay day;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (day.status) {
      case DayStatus.done:
        bg = context.colors.teal600.withValues(alpha: 0.4);
        fg = context.colors.teal;
      case DayStatus.today:
        bg = context.colors.accent;
        fg = Colors.white;
      case DayStatus.missed:
      case DayStatus.future:
        bg = context.colors.bg3;
        fg = context.colors.textMuted;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(day.label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _StartReviewButton extends StatelessWidget {
  const _StartReviewButton({required this.dueCount});
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final enabled = dueCount > 0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled
            ? () => context.push('/review/$kAllDecks')
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.accent,
          disabledBackgroundColor: context.colors.bg3,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Text(
          enabled
              ? 'شروع مرور — ${Fa.digits(dueCount)} کارت  ←  ${Fa.estimateDuration(dueCount)}'
              : 'فعلاً کارتی برای مرور نیست',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.white : context.colors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// دکمه‌ی مرور نقاط ضعف — وقتی کارت سختی برای تمرین وجود دارد.
class _WeakPointsButton extends StatelessWidget {
  const _WeakPointsButton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => context.push('/review/$kWeakCards'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.bolt_rounded, color: c.amber, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تمرین نقاط ضعف — ${Fa.digits(count)} کارت سخت',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: c.amber),
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: c.amber),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: context.colors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: context.colors.textMuted)),
        ],
      ),
    );
  }
}
