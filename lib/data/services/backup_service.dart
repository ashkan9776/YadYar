import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/app_snapshot.dart';

/// سرویس پشتیبان‌گیری و بازیابی — خواندن/نوشتن کل دیتابیس به‌صورت JSON.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// ساخت عکس‌فوری از کل دیتابیس.
  Future<AppSnapshot> exportSnapshot() async {
    final categories = await AppDatabase.categories.find(_db.db);
    final books = await AppDatabase.books.find(_db.db);
    final decks = await AppDatabase.decks.find(_db.db);
    final cards = await AppDatabase.cards.find(_db.db);
    final reviews = await AppDatabase.reviews.find(_db.db);
    final settingsRec =
        await AppDatabase.settings.record('app').get(_db.db);

    return AppSnapshot(
      version: AppSnapshot.currentVersion,
      exportedAt: DateTime.now().millisecondsSinceEpoch,
      categories: categories.map((r) => r.value).toList(),
      books: books.map((r) => r.value).toList(),
      decks: decks.map((r) => r.value).toList(),
      cards: cards.map((r) => r.value).toList(),
      reviews: reviews.map((r) => r.value).toList(),
      settings: settingsRec,
    );
  }

  /// ذخیره‌ی عکس‌فوری در فایل موقت و بازگرداندن مسیر آن.
  Future<String> saveToFile(AppSnapshot snapshot) async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName = 'yadyar_backup_${now.millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(snapshot.toJson());
    return file.path;
  }

  /// بارگذاری عکس‌فوری و بازنویسی کل دیتابیس (درون یک تراکنش اتمیک).
  Future<void> importSnapshot(AppSnapshot snapshot) async {
    await _db.db.transaction((txn) async {
      // پاک‌سازی کامل.
      await AppDatabase.categories.delete(txn);
      await AppDatabase.books.delete(txn);
      await AppDatabase.decks.delete(txn);
      await AppDatabase.cards.delete(txn);
      await AppDatabase.reviews.delete(txn);
      await AppDatabase.settings.delete(txn);

      // بازسازی دسته‌بندی‌ها (نسخه ۲ به بعد).
      for (final record in snapshot.categories ?? const []) {
        await AppDatabase.categories.add(txn, record);
      }

      // بازسازی کتاب‌ها (نسخه ۲ به بعد).
      for (final record in snapshot.books ?? const []) {
        await AppDatabase.books.add(txn, record);
      }

      // بازسازی دک‌ها.
      for (final record in snapshot.decks) {
        await AppDatabase.decks.add(txn, record);
      }

      // بازسازی کارت‌ها.
      for (final record in snapshot.cards) {
        await AppDatabase.cards.add(txn, record);
      }

      // بازسازی مرورها.
      for (final record in snapshot.reviews) {
        await AppDatabase.reviews.add(txn, record);
      }

      // بازسازی تنظیمات.
      if (snapshot.settings != null) {
        await AppDatabase.settings.record('app').put(txn, snapshot.settings!);
      }
    });
  }

  /// خواندن عکس‌فوری از فایل روی دیسک.
  static AppSnapshot loadFromFile(String path) {
    final content = File(path).readAsStringSync();
    return AppSnapshot.fromJson(content);
  }
}
