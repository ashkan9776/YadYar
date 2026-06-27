import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications.dart';
import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_settings.dart';
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
