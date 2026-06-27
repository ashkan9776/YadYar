import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/deck.dart';

/// عملیات داده‌ای روی دک‌ها.
class DeckRepository {
  DeckRepository(this._db);

  final AppDatabase _db;
  StoreRef<int, Map<String, Object?>> get _store => AppDatabase.decks;

  Future<int> add(Deck deck) => _store.add(_db.db, deck.toMap());

  Future<void> update(Deck deck) async {
    await _store.record(deck.id!).put(_db.db, deck.toMap());
  }

  Future<void> delete(int id) async {
    await _db.db.transaction((txn) async {
      await AppDatabase.cards
          .delete(txn, finder: Finder(filter: Filter.equals('deckId', id)));
      await AppDatabase.reviews
          .delete(txn, finder: Finder(filter: Filter.equals('deckId', id)));
      await _store.record(id).delete(txn);
    });
  }

  Future<Deck?> getById(int id) async {
    final rec = await _store.record(id).get(_db.db);
    return rec == null ? null : Deck.fromMap(id, rec);
  }

  Future<List<Deck>> getAll() async {
    final records = await _store.find(_db.db,
        finder: Finder(sortOrders: [SortOrder('createdAt')]));
    return records.map((r) => Deck.fromMap(r.key, r.value)).toList();
  }

  /// جریان زنده‌ی همه‌ی دک‌ها (مرتب‌شده بر اساس تاریخ ایجاد).
  Stream<List<Deck>> watchAll() {
    return _store
        .query(finder: Finder(sortOrders: [SortOrder('createdAt')]))
        .onSnapshots(_db.db)
        .map((records) =>
            records.map((r) => Deck.fromMap(r.key, r.value)).toList());
  }

  Future<int> count() => _store.count(_db.db);
}
