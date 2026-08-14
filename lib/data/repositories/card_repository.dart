import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/flashcard.dart';

/// عملیات داده‌ای روی فلش‌کارت‌ها.
class CardRepository {
  CardRepository(AppDatabase database) : _database = database.db;

  /// سازنده‌ی مخصوص تست‌های دیتابیس درون‌حافظه‌ای.
  CardRepository.withDatabase(this._database);

  final Database _database;
  StoreRef<int, Map<String, Object?>> get _store => AppDatabase.cards;

  Future<int> add(FlashCard card) => _store.add(_database, card.toMap());

  Future<void> addAll(List<FlashCard> cards) async {
    await _database.transaction((txn) async {
      for (final c in cards) {
        await _store.add(txn, c.toMap());
      }
    });
  }

  Future<void> update(FlashCard card) async {
    await _store.record(card.id!).put(_database, card.toMap());
  }

  /// حذف کارت و تمام لاگ‌های وابسته به آن در یک تراکنش.
  Future<void> delete(int id) async {
    await _database.transaction((txn) async {
      await _store.record(id).delete(txn);
      await AppDatabase.reviews.delete(
        txn,
        finder: Finder(filter: Filter.equals('cardId', id)),
      );
    });
  }

  Future<List<FlashCard>> getByDeck(int deckId) async {
    final records = await _store.find(
      _database,
      finder: Finder(filter: Filter.equals('deckId', deckId)),
    );
    return records.map((r) => FlashCard.fromMap(r.key, r.value)).toList();
  }

  Stream<List<FlashCard>> watchAll() {
    return _store
        .query()
        .onSnapshots(_database)
        .map(
          (records) =>
              records.map((r) => FlashCard.fromMap(r.key, r.value)).toList(),
        );
  }

  Stream<List<FlashCard>> watchByDeck(int deckId) {
    return _store
        .query(finder: Finder(filter: Filter.equals('deckId', deckId)))
        .onSnapshots(_database)
        .map(
          (records) =>
              records.map((r) => FlashCard.fromMap(r.key, r.value)).toList(),
        );
  }

  Future<List<FlashCard>> getAll() async {
    final records = await _store.find(_database);
    return records.map((r) => FlashCard.fromMap(r.key, r.value)).toList();
  }
}
