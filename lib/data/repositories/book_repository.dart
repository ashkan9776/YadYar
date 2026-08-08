import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/book.dart';

/// عملیات داده‌ای روی کتاب‌ها.
class BookRepository {
  BookRepository(this._db);

  final AppDatabase _db;
  StoreRef<int, Map<String, Object?>> get _store => AppDatabase.books;

  Future<int> add(Book book) => _store.add(_db.db, book.toMap());

  Future<void> update(Book book) async {
    await _store.record(book.id!).put(_db.db, book.toMap());
  }

  /// حذف آبشاری: کتاب → دک‌ها → کارت‌ها و مرورها.
  Future<void> delete(int id) async {
    await _db.db.transaction((txn) async {
      // پیدا کردن همه دک‌های این کتاب.
      final decks = await AppDatabase.decks
          .find(txn, finder: Finder(filter: Filter.equals('bookId', id)));
      for (final deck in decks) {
        // حذف کارت‌ها و مرورهای هر دک.
        await AppDatabase.cards.delete(txn,
            finder: Finder(filter: Filter.equals('deckId', deck.key)));
        await AppDatabase.reviews.delete(txn,
            finder: Finder(filter: Filter.equals('deckId', deck.key)));
        await AppDatabase.decks.record(deck.key).delete(txn);
      }
      await _store.record(id).delete(txn);
    });
  }

  Future<Book?> getById(int id) async {
    final rec = await _store.record(id).get(_db.db);
    return rec == null ? null : Book.fromMap(id, rec);
  }

  Future<List<Book>> getAll() async {
    final records = await _store.find(_db.db,
        finder: Finder(sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')]));
    return records.map((r) => Book.fromMap(r.key, r.value)).toList();
  }

  Future<List<Book>> getByCategory(int categoryId) async {
    final records = await _store.find(_db.db,
        finder: Finder(
            filter: Filter.equals('categoryId', categoryId),
            sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')]));
    return records.map((r) => Book.fromMap(r.key, r.value)).toList();
  }

  /// جریان زنده‌ی همه‌ی کتاب‌ها.
  Stream<List<Book>> watchAll() {
    return _store
        .query(finder: Finder(sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')]))
        .onSnapshots(_db.db)
        .map((records) =>
            records.map((r) => Book.fromMap(r.key, r.value)).toList());
  }

  /// جریان زنده‌ی کتاب‌های یک دسته‌بندی.
  Stream<List<Book>> watchByCategory(int categoryId) {
    return _store
        .query(finder: Finder(
            filter: Filter.equals('categoryId', categoryId),
            sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')]))
        .onSnapshots(_db.db)
        .map((records) =>
            records.map((r) => Book.fromMap(r.key, r.value)).toList());
  }

  Future<int> count() => _store.count(_db.db);
}
