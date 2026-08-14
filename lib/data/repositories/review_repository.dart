import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/flashcard.dart';
import '../models/review_log.dart';

/// عملیات داده‌ای روی لاگ مرورها (برای آمار و استریک).
class ReviewRepository {
  ReviewRepository(AppDatabase database) : _database = database.db;

  /// سازنده‌ی مخصوص تست‌های دیتابیس درون‌حافظه‌ای.
  ReviewRepository.withDatabase(this._database);

  final Database _database;
  StoreRef<int, Map<String, Object?>> get _store => AppDatabase.reviews;

  Future<int> add(ReviewLog log) => _store.add(_database, log.toMap());

  /// ثبت ارزیابی کارت و لاگ آن به‌صورت اتمیک.
  Future<int> recordReview({
    required FlashCard updatedCard,
    required ReviewLog log,
  }) {
    return _database.transaction((txn) async {
      await AppDatabase.cards
          .record(updatedCard.id!)
          .put(txn, updatedCard.toMap());
      return _store.add(txn, log.toMap());
    });
  }

  /// لغو ارزیابی با بازیابی کارت و حذف لاگ آن به‌صورت اتمیک.
  Future<void> undoReview({
    required FlashCard previousCard,
    required int reviewLogId,
  }) {
    return _database.transaction((txn) async {
      await AppDatabase.cards
          .record(previousCard.id!)
          .put(txn, previousCard.toMap());
      await _store.record(reviewLogId).delete(txn);
    });
  }

  /// حذف یک لاگ مرور.
  Future<void> delete(int id) => _store.record(id).delete(_database);

  Future<List<ReviewLog>> getAll() async {
    final records = await _store.find(
      _database,
      finder: Finder(sortOrders: [SortOrder('reviewedAt')]),
    );
    return records.map((r) => ReviewLog.fromMap(r.key, r.value)).toList();
  }

  Stream<List<ReviewLog>> watchAll() {
    return _store
        .query(finder: Finder(sortOrders: [SortOrder('reviewedAt')]))
        .onSnapshots(_database)
        .map(
          (records) =>
              records.map((r) => ReviewLog.fromMap(r.key, r.value)).toList(),
        );
  }
}
