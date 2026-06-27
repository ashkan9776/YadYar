import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications.dart';
import 'data/db/app_database.dart';
import 'data/repositories/card_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/seed/seed_data.dart';
import 'domain/study_stats.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // باز کردن دیتابیس و کاشت داده‌های اولیه.
  final db = await AppDatabase.open();
  await SeedData.ensureSeeded(db);

  // راه‌اندازی نوتیفیکیشن و زمان‌بندی یادآوری روزانه طبق تنظیمات کاربر.
  final settings = await SettingsRepository(db).load();
  await NotificationService.instance.init();
  await NotificationService.instance.applyReminder(
    enabled: settings.reminderEnabled,
    hour: settings.reminderHour,
    minute: settings.reminderMinute,
  );

  // یادآوری هوشمند استریک را بر اساس وضعیت امروز به‌روزرسانی کن.
  final cards = await CardRepository(db).getAll();
  final logs = await ReviewRepository(db).getAll();
  final stats = StudyStats.compute(logs: logs, totalCards: cards.length);
  final now = DateTime.now();
  final dueCount = cards.where((c) => c.isDueAt(now)).length;
  await NotificationService.instance.updateStreakReminder(
    reviewedToday: stats.todayReviewed > 0,
    streakDays: stats.streakDays,
    dueCount: dueCount,
  );

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const YadyarApp(),
    ),
  );
}
