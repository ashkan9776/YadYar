import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/app_snapshot.dart';

/// سرویس پشتیبان‌گیری و بازیابی — خواندن/نوشتن کل دیتابیس به‌صورت JSON.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const _maximumBackupSize = 50 * 1024 * 1024;

  /// ساخت عکس‌فوری سازگار از کل دیتابیس.
  Future<AppSnapshot> exportSnapshot() {
    return _db.db.transaction((txn) async {
      final categories = await AppDatabase.categories.find(txn);
      final books = await AppDatabase.books.find(txn);
      final decks = await AppDatabase.decks.find(txn);
      final cards = await AppDatabase.cards.find(txn);
      final reviews = await AppDatabase.reviews.find(txn);
      final settingsRec = await AppDatabase.settings.record('app').get(txn);

      return AppSnapshot(
        version: AppSnapshot.currentVersion,
        exportedAt: DateTime.now().millisecondsSinceEpoch,
        categories: categories.map(_recordWithId).toList(),
        books: books.map(_recordWithId).toList(),
        decks: decks.map(_recordWithId).toList(),
        cards: cards.map(_recordWithId).toList(),
        reviews: reviews.map(_recordWithId).toList(),
        settings: settingsRec,
      );
    });
  }

  /// ذخیره‌ی عکس‌فوری در فایل موقت و بازگرداندن مسیر آن.
  Future<String> saveToFile(AppSnapshot snapshot) async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName = 'yadyar_backup_${now.millisecondsSinceEpoch}.json';
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(snapshot.toJson(), flush: true);
    return file.path;
  }

  /// بارگذاری عکس‌فوری و بازنویسی کل دیتابیس (درون یک تراکنش اتمیک).
  Future<void> importSnapshot(AppSnapshot snapshot) async {
    // This must run before the transaction deletes any existing records.
    snapshot.validateForImport();

    await _db.db.transaction((txn) async {
      // پاک‌سازی کامل.
      await AppDatabase.categories.delete(txn);
      await AppDatabase.books.delete(txn);
      await AppDatabase.decks.delete(txn);
      await AppDatabase.cards.delete(txn);
      await AppDatabase.reviews.delete(txn);
      await AppDatabase.settings.delete(txn);

      // Restore explicit keys, rather than assigning new auto-increment keys.
      for (final record in snapshot.categories!) {
        await _putRecordWithId(AppDatabase.categories, txn, record);
      }
      for (final record in snapshot.books!) {
        await _putRecordWithId(AppDatabase.books, txn, record);
      }
      for (final record in snapshot.decks) {
        await _putRecordWithId(AppDatabase.decks, txn, record);
      }
      for (final record in snapshot.cards) {
        await _putRecordWithId(AppDatabase.cards, txn, record);
      }
      for (final record in snapshot.reviews) {
        await _putRecordWithId(AppDatabase.reviews, txn, record);
      }

      if (snapshot.settings != null) {
        await AppDatabase.settings.record('app').put(txn, snapshot.settings!);
      }
    });
  }

  static Map<String, Object?> _recordWithId(
    RecordSnapshot<int, Map<String, Object?>> record,
  ) => {'id': record.key, ...record.value};

  static Future<void> _putRecordWithId(
    StoreRef<int, Map<String, Object?>> store,
    DatabaseClient client,
    Map<String, Object?> record,
  ) {
    final id = record['id']! as int;
    final value = Map<String, Object?>.from(record)..remove('id');
    return store.record(id).put(client, value);
  }

  /// خواندن عکس‌فوری از فایل روی دیسک بدون مسدودکردن UI.
  static Future<AppSnapshot> loadFromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw const FormatException('مسیر انتخاب‌شده یک فایل پشتیبان نیست.');
      }
      final size = await file.length();
      if (size == 0) {
        throw const FormatException('فایل پشتیبان خالی است.');
      }
      if (size > _maximumBackupSize) {
        throw const FormatException('حجم فایل پشتیبان بیش از حد مجاز است.');
      }
      return AppSnapshot.fromJson(await file.readAsString());
    } on FormatException {
      rethrow;
    } on FileSystemException catch (error) {
      throw FormatException('خواندن فایل پشتیبان ممکن نشد: ${error.message}');
    }
  }
}
