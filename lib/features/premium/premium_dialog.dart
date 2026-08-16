import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persian.dart';
import '../../core/services/purchase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_settings.dart';
import '../../providers/providers.dart';

/// نمایش دیالوگ خرید نسخه حرفه‌ای.
///
/// [reason] دلیل نمایش دیالوگ (مثلاً: محدودیت دسته‌بندی).
Future<void> showPremiumDialog(
  BuildContext context,
  WidgetRef ref, {
  String reason = '',
}) {
  return showDialog(context: context, builder: (ctx) => const _PremiumDialog());
}

/// نمایش دیالوگ وضعیت و ویژگی‌های فعال نسخه حرفه‌ای برای کاربر پرو.
Future<void> showProStatusDialog(BuildContext context, AppSettings settings) {
  return showDialog(
    context: context,
    builder: (ctx) => _ProStatusDialog(settings: settings),
  );
}

class _ProStatusDialog extends StatelessWidget {
  const _ProStatusDialog({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final date = settings.proActivatedAt;

    return Dialog(
      backgroundColor: palette.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.border2, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // نشان فعال بودن
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 36,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'نسخه حرفه‌ای فعال است',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded,
                    color: palette.teal, size: 22),
              ],
            ),
            if (date != null) ...[
              const SizedBox(height: 6),
              Text(
                'از ${Fa.fullDate(date)}',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ویژگی‌های فعال
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _BenefitRow(
                    Icons.all_inclusive_rounded,
                    'دسته‌بندی، کتاب و دک نامحدود',
                  ),
                  const SizedBox(height: 10),
                  _BenefitRow(Icons.style_rounded, 'کارت نامحدود در هر دک'),
                  const SizedBox(height: 10),
                  _BenefitRow(Icons.block_rounded, 'بدون تبلیغات'),
                  const SizedBox(height: 10),
                  _BenefitRow(
                    Icons.local_fire_department_rounded,
                    'چالش روزانه با استریک مخصوص 🔥',
                  ),
                  const SizedBox(height: 10),
                  _BenefitRow(Icons.sync_rounded, 'اشتراک‌گذاری و ایمپورت دک'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumDialog extends ConsumerStatefulWidget {
  const _PremiumDialog();

  @override
  ConsumerState<_PremiumDialog> createState() => _PremiumDialogState();
}

class _PremiumDialogState extends ConsumerState<_PremiumDialog> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;

    return Dialog(
      backgroundColor: palette.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.border2, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // آیکون طلایی
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 36,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),

            // عنوان
            Text(
              'نسخه حرفه‌ای یادیار',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'محدودیت‌ها را بردارید و از تمام قابلیت‌ها استفاده کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: palette.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // لیست مزایا
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _BenefitRow(
                    Icons.all_inclusive_rounded,
                    'دسته‌بندی، کتاب و دک نامحدود',
                  ),
                  const SizedBox(height: 10),
                  _BenefitRow(Icons.style_rounded, 'کارت نامحدود در هر دک'),
                  const SizedBox(height: 10),
                  _BenefitRow(Icons.block_rounded, 'بدون تبلیغات'),
                  const SizedBox(height: 10),
                  _BenefitRow(
                    Icons.local_fire_department_rounded,
                    'چالش روزانه با استریک مخصوص 🔥',
                  ),
                  const SizedBox(height: 10),
                  _BenefitRow(Icons.mic_rounded, 'تمرین مکالمه (قابلیت آینده)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // پرداخت فقط پس از اتصال به یک فروشگاه با تأیید مالکیت فعال می‌شود.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: PurchaseService.isAvailable && !_purchasing
                    ? _purchase
                    : null,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  PurchaseService.isAvailable
                      ? 'خرید از کافه‌بازار'
                      : 'پرداخت به‌زودی فعال می‌شود',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // دکمه بعداً
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'بعداً',
                style: TextStyle(color: palette.textMuted, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase() async {
    if (!PurchaseService.isAvailable) return;
    setState(() => _purchasing = true);

    try {
      final success = await PurchaseService.instance.purchasePremium();

      if (success && mounted) {
        // خرید موفق — ذخیره در تنظیمات
        final repo = ref.read(settingsRepositoryProvider);
        final current = ref.read(settingsProvider);
        await repo.save(
          current.copyWith(isPro: true, proActivatedAt: DateTime.now()),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خرید انجام نشد. دوباره تلاش کنید.')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, size: 18, color: context.colors.teal),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: context.colors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: context.colors.textPrimary),
          ),
        ),
      ],
    );
  }
}
