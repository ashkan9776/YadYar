import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/review_log.dart';

/// عملیات داده‌ای روی لاگ مرورها (برای آمار و استریک).
class ReviewRepository {
  ReviewRepository(this._db);

  final AppDatabase _db;
  StoreRef<int, Map<String, Object?>> get _store => AppDatabase.reviews;

  Future<int> add(ReviewLog log) => _store.add(_db.db, log.toMap());

  /// حذف یک لاگ مرور (برای قابلیت «بازگشت» در نشست مرور).
  Future<void> delete(int id) => _store.record(id).delete(_db.db);

  Future<List<ReviewLog>> getAll() async {
    final records = await _store.find(_db.db,
        finder: Finder(sortOrders: [SortOrder('reviewedAt')]));
    return records.map((r) => ReviewLog.fromMap(r.key, r.value)).toList();
  }

  Stream<List<ReviewLog>> watchAll() {
    return _store
        .query(finder: Finder(sortOrders: [SortOrder('reviewedAt')]))
        .onSnapshots(_db.db)
        .map((records) =>
            records.map((r) => ReviewLog.fromMap(r.key, r.value)).toList());
  }
}
