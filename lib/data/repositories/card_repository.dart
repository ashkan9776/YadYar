import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/flashcard.dart';

/// عملیات داده‌ای روی فلش‌کارت‌ها.
class CardRepository {
  CardRepository(this._db);

  final AppDatabase _db;
  StoreRef<int, Map<String, Object?>> get _store => AppDatabase.cards;

  Future<int> add(FlashCard card) => _store.add(_db.db, card.toMap());

  Future<void> addAll(List<FlashCard> cards) async {
    await _db.db.transaction((txn) async {
      for (final c in cards) {
        await _store.add(txn, c.toMap());
      }
    });
  }

  Future<void> update(FlashCard card) async {
    await _store.record(card.id!).put(_db.db, card.toMap());
  }

  Future<void> delete(int id) async {
    await _store.record(id).delete(_db.db);
    await AppDatabase.reviews
        .delete(_db.db, finder: Finder(filter: Filter.equals('cardId', id)));
  }

  Future<List<FlashCard>> getByDeck(int deckId) async {
    final records = await _store.find(_db.db,
        finder: Finder(filter: Filter.equals('deckId', deckId)));
    return records.map((r) => FlashCard.fromMap(r.key, r.value)).toList();
  }

  Stream<List<FlashCard>> watchAll() {
    return _store.query().onSnapshots(_db.db).map(
        (records) => records.map((r) => FlashCard.fromMap(r.key, r.value)).toList());
  }

  Stream<List<FlashCard>> watchByDeck(int deckId) {
    return _store
        .query(finder: Finder(filter: Filter.equals('deckId', deckId)))
        .onSnapshots(_db.db)
        .map((records) =>
            records.map((r) => FlashCard.fromMap(r.key, r.value)).toList());
  }

  Future<List<FlashCard>> getAll() async {
    final records = await _store.find(_db.db);
    return records.map((r) => FlashCard.fromMap(r.key, r.value)).toList();
  }
}
