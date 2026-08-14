import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

import 'data/db/app_database.dart';

import 'data/seed/seed_data.dart';

import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // باز کردن دیتابیس و کاشت داده‌های اولیه.
  final db = await AppDatabase.open();
  await SeedData.ensureSeeded(db);

  // کارهای غیرضروری (نوتیفیکیشن، آمار و ویجت) پس از نمایش نخستین UI
  // و در چرخه‌ی عمر featureهای مربوط انجام می‌شوند.

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const YadyarApp(),
    ),
  );
}
