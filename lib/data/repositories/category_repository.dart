import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/category.dart';

/// عملیات داده‌ای روی دسته‌بندی‌ها.
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;
  StoreRef<int, Map<String, Object?>> get _store => AppDatabase.categories;

  Future<int> add(Category category) => _store.add(_db.db, category.toMap());

  Future<void> update(Category category) async {
    await _store.record(category.id!).put(_db.db, category.toMap());
  }

  /// حذف آبشاری: دسته → کتاب‌ها → دک‌ها → کارت‌ها و مرورها.
  Future<void> delete(int id) async {
    await _db.db.transaction((txn) async {
      // پیدا کردن همه کتاب‌های این دسته.
      final books = await AppDatabase.books
          .find(txn, finder: Finder(filter: Filter.equals('categoryId', id)));
      for (final book in books) {
        // پیدا کردن همه دک‌های هر کتاب.
        final decks = await AppDatabase.decks
            .find(txn, finder: Finder(filter: Filter.equals('bookId', book.key)));
        for (final deck in decks) {
          // حذف کارت‌ها و مرورهای هر دک.
          await AppDatabase.cards.delete(txn,
              finder: Finder(filter: Filter.equals('deckId', deck.key)));
          await AppDatabase.reviews.delete(txn,
              finder: Finder(filter: Filter.equals('deckId', deck.key)));
          await AppDatabase.decks.record(deck.key).delete(txn);
        }
        await AppDatabase.books.record(book.key).delete(txn);
      }
      await _store.record(id).delete(txn);
    });
  }

  Future<Category?> getById(int id) async {
    final rec = await _store.record(id).get(_db.db);
    return rec == null ? null : Category.fromMap(id, rec);
  }

  Future<List<Category>> getAll() async {
    final records = await _store.find(_db.db,
        finder: Finder(sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')]));
    return records.map((r) => Category.fromMap(r.key, r.value)).toList();
  }

  /// جریان زنده‌ی همه‌ی دسته‌بندی‌ها (مرتب‌شده).
  Stream<List<Category>> watchAll() {
    return _store
        .query(finder: Finder(sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')]))
        .onSnapshots(_db.db)
        .map((records) =>
            records.map((r) => Category.fromMap(r.key, r.value)).toList());
  }

  Future<int> count() => _store.count(_db.db);
}
