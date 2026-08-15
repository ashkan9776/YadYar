import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/daily_challenge.dart';
import '../../providers/providers.dart';
import '../premium/premium_dialog.dart';

/// کارت چالش روزانه در صفحه‌ی خانه — قابلیت نسخه حرفه‌ای.
///
/// سه حالت: چالش امروز (شروع)، کامل‌شده (نمایش استریک) و کاربر رایگان
/// (نشان 👑 → دیالوگ خرید). بدون هیچ کارتی در اپ، کارت نمایش داده نمی‌شود.
class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(settingsProvider);
    final cards = ref.watch(allCardsStreamProvider).value;
    if (cards == null || cards.isEmpty) return const SizedBox.shrink();

    final done = DailyChallenge.isCompletedToday(settings, DateTime.now());
    final count = cards.length < DailyChallenge.cardCount
        ? cards.length
        : DailyChallenge.cardCount;

    if (done) {
      // چالش امروز کامل شده — نمایش استریک، بدون اکشن.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.teal.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.teal.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: c.teal, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'چالش امروز کامل شد — استریک: ${Fa.digits(settings.challengeStreak)} روز 🔥',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.teal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isPro = settings.isPro;
    return InkWell(
      onTap: () {
        if (!isPro) {
          showPremiumDialog(context, ref,
              reason: 'چالش روزانه مخصوص نسخه حرفه‌ای است');
          return;
        }
        context.push('/review/$kDailyChallenge');
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.local_fire_department_rounded,
                color: c.accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'چالش امروز — ${Fa.digits(count)} کارت از همه‌ی دک‌ها',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
            ),
            if (isPro)
              Icon(Icons.chevron_right_rounded, color: c.accent)
            else
              const Text('👑', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
