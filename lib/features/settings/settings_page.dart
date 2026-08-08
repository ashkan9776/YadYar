import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications.dart';
import '../../core/persian.dart';
import '../../core/services/purchase_service.dart';
import '../../core/sound.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_settings.dart';
import '../../features/premium/premium_dialog.dart';
import '../../providers/providers.dart';

/// صفحه‌ی تنظیمات — یادآوری روزانه و هدف مطالعه.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _save(WidgetRef ref, AppSettings next) async {
    await ref.read(settingsRepositoryProvider).save(next);
    await NotificationService.instance.applyReminder(
      enabled: next.reminderEnabled,
      hour: next.reminderHour,
      minute: next.reminderMinute,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _SectionLabel('نسخه حرفه‌ای'),
            const SizedBox(height: 10),
            _PremiumCard(settings: settings),
            const SizedBox(height: 24),
            _SectionLabel('یادآوری'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: context.colors.accent,
                    title: Text('یادآوری روزانه',
                        style: TextStyle(
                            fontSize: 15, color: context.colors.textPrimary)),
                    subtitle: Text('هر روز برای مرور بهت یادآوری می‌کنیم',
                        style: TextStyle(
                            fontSize: 12, color: context.colors.textMuted)),
                    value: settings.reminderEnabled,
                    onChanged: (v) =>
                        _save(ref, settings.copyWith(reminderEnabled: v)),
                  ),
                  Divider(height: 1, color: context.colors.border),
                  Opacity(
                    opacity: settings.reminderEnabled ? 1 : 0.4,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      enabled: settings.reminderEnabled,
                      title: Text('ساعت یادآوری',
                          style: TextStyle(
                              fontSize: 15, color: context.colors.textPrimary)),
                      trailing: Text(
                        Fa.clock(settings.reminderHour, settings.reminderMinute),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.colors.accent),
                      ),
                      onTap: settings.reminderEnabled
                          ? () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: settings.reminderHour,
                                    minute: settings.reminderMinute),
                              );
                              if (picked != null) {
                                await _save(
                                  ref,
                                  settings.copyWith(
                                    reminderHour: picked.hour,
                                    reminderMinute: picked.minute,
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await NotificationService.instance.showTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('نوتیفیکیشن تست ارسال شد 🔔'),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.notifications_active_outlined,
                    size: 18, color: context.colors.accent),
                label: Text('ارسال نوتیفیکیشن تست',
                    style: TextStyle(color: context.colors.accent)),
              ),
            ),
            const SizedBox(height: 14),
            _SectionLabel('هدف روزانه'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('تعداد کارت در روز',
                          style: TextStyle(
                              fontSize: 15, color: context.colors.textPrimary)),
                      Text('${Fa.digits(settings.dailyGoal)} کارت',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.teal)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: context.colors.accent,
                      inactiveTrackColor: context.colors.bg3,
                      thumbColor: context.colors.accent,
                      overlayColor: context.colors.accentGlow,
                    ),
                    child: Slider(
                      value: settings.dailyGoal.toDouble(),
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: Fa.digits(settings.dailyGoal),
                      onChanged: (v) => _save(
                          ref, settings.copyWith(dailyGoal: v.round())),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel('مرور'),
            const SizedBox(height: 10),
            _Card(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: context.colors.accent,
                title: Text('حالت تایپ جواب',
                    style: TextStyle(
                        fontSize: 15, color: context.colors.textPrimary)),
                subtitle: Text('به‌جای فلیپ کارت، جواب رو تایپ کن و خودکار چک شه',
                    style: TextStyle(
                        fontSize: 12, color: context.colors.textMuted)),
                value: settings.typedAnswerMode,
                onChanged: (v) =>
                    _save(ref, settings.copyWith(typedAnswerMode: v)),
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel('صدا و لرزش'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: context.colors.accent,
                    title: Text('افکت صوتی',
                        style: TextStyle(
                            fontSize: 15, color: context.colors.textPrimary)),
                    subtitle: Text('صدای فلیپ، ارزیابی و جشن‌ها',
                        style: TextStyle(
                            fontSize: 12, color: context.colors.textMuted)),
                    value: settings.soundEnabled,
                    onChanged: (v) {
                      SoundService.instance.enabled = v;
                      _save(ref, settings.copyWith(soundEnabled: v));
                    },
                  ),
                  Divider(height: 1, color: context.colors.border),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: context.colors.accent,
                    title: Text('لرزش (هپتیک)',
                        style: TextStyle(
                            fontSize: 15, color: context.colors.textPrimary)),
                    subtitle: Text('لرزش دستگاه هنگام ارزیابی و فلیپ',
                        style: TextStyle(
                            fontSize: 12, color: context.colors.textMuted)),
                    value: settings.hapticsEnabled,
                    onChanged: (v) =>
                        _save(ref, settings.copyWith(hapticsEnabled: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel('داده'),
            const SizedBox(height: 10),
            _Card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => context.push('/data'),
                leading: Icon(Icons.cloud_upload_outlined,
                    color: context.colors.accent),
                title: Text('مدیریت داده',
                    style: TextStyle(
                        fontSize: 15, color: context.colors.textPrimary)),
                subtitle: Text('پشتیبان‌گیری، بازیابی و حذف داده‌ها',
                    style: TextStyle(
                        fontSize: 12, color: context.colors.textMuted)),
                trailing: Icon(Icons.chevron_left_rounded,
                    color: context.colors.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel('تم'),
            const SizedBox(height: 10),
            _Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: AppThemeMode.system, label: Text('سیستم')),
                      ButtonSegment(
                          value: AppThemeMode.light, label: Text('روشن')),
                      ButtonSegment(
                          value: AppThemeMode.dark, label: Text('تاریک')),
                    ],
                    selected: {settings.themeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        _save(ref, settings.copyWith(themeMode: s.first)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

/// بخش نسخه حرفه‌ای در تنظیمات.
class _PremiumCard extends ConsumerStatefulWidget {
  const _PremiumCard({required this.settings});
  final AppSettings settings;

  @override
  ConsumerState<_PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends ConsumerState<_PremiumCard> {
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    final isPro = widget.settings.isPro;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isPro
            ? null
            : LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.amber.withValues(alpha: 0.12),
                  context.colors.accent.withValues(alpha: 0.10),
                ],
              ),
        color: isPro ? context.colors.bg2 : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isPro
                ? context.colors.teal.withValues(alpha: 0.3)
                : Colors.amber.withValues(alpha: 0.3)),
      ),
      child: isPro ? _buildProActive(context) : _buildUpgrade(context),
    );
  }

  Widget _buildProActive(BuildContext context) {
    final date = widget.settings.proActivatedAt;
    final dateStr = date != null ? Fa.fullDate(date) : '';

    return Row(
      children: [
        const Icon(Icons.workspace_premium_rounded,
            color: Colors.amber, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نسخه حرفه‌ای فعال است',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary)),
              if (dateStr.isNotEmpty)
                Text('از $dateStr',
                    style: TextStyle(
                        fontSize: 12, color: context.colors.textMuted)),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded, color: context.colors.teal, size: 24),
      ],
    );
  }

  Widget _buildUpgrade(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text('یادیار پرو',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'محدودیت‌ها را بردارید: دسته‌بندی، کتاب و دک نامحدود، تا ۵۰ کارت به ازای هر دک.',
          style: TextStyle(
              fontSize: 12,
              color: context.colors.textSecondary,
              height: 1.5),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => showPremiumDialog(context, ref),
          icon: const Icon(Icons.workspace_premium_rounded, size: 18),
          label: const Text('ارتقا به نسخه حرفه‌ای'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _restoring ? null : _restorePurchase,
          icon: _restoring
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.restore_rounded, size: 18),
          label: Text(_restoring ? 'در حال بازیابی...' : 'بازیابی خرید',
              style: const TextStyle(fontSize: 13)),
          style: TextButton.styleFrom(
            foregroundColor: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _restorePurchase() async {
    setState(() => _restoring = true);
    try {
      final ok = await PurchaseService.instance.restorePurchase();
      if (ok && mounted) {
        final repo = ref.read(settingsRepositoryProvider);
        final current = ref.read(settingsProvider);
        await repo.save(current.copyWith(
          isPro: true,
          proActivatedAt: DateTime.now(),
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خرید شما با موفقیت بازیابی شد ✅')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خریدی برای بازیابی یافت نشد.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در بازیابی خرید.')),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}
