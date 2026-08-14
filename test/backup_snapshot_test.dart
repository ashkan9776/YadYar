import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yadyar/data/models/app_snapshot.dart';
import 'package:yadyar/data/services/backup_service.dart';

void main() {
  Map<String, Object?> category(int id) => {
    'id': id,
    'title': 'Category $id',
    'colorHex': 0,
    'createdAt': 1,
  };
  Map<String, Object?> book(int id, int categoryId) => {
    'id': id,
    'categoryId': categoryId,
    'title': 'Book $id',
    'colorHex': 0,
    'createdAt': 1,
  };
  Map<String, Object?> deck(int id, int bookId) => {
    'id': id,
    'bookId': bookId,
    'title': 'Deck $id',
    'colorHex': 0,
    'createdAt': 1,
  };
  Map<String, Object?> card(int id, int deckId) => {
    'id': id,
    'deckId': deckId,
    'front': 'front',
    'back': 'back',
    'nextReview': 1,
  };
  Map<String, Object?> review(int id, int cardId, int deckId) => {
    'id': id,
    'cardId': cardId,
    'deckId': deckId,
    'quality': 4,
    'reviewedAt': 1,
  };

  AppSnapshot validSnapshot() => AppSnapshot(
    version: AppSnapshot.currentVersion,
    exportedAt: 1,
    categories: [category(4)],
    books: [book(8, 4)],
    decks: [deck(12, 8)],
    cards: [card(16, 12)],
    reviews: [review(20, 16, 12)],
    settings: null,
  );

  test('round trips explicitly stored record IDs', () {
    final snapshot = validSnapshot();

    final parsed = AppSnapshot.fromJson(snapshot.toJson());

    expect(parsed.categories!.single['id'], 4);
    expect(parsed.books!.single['id'], 8);
    expect(parsed.decks.single['id'], 12);
    expect(parsed.cards.single['id'], 16);
    expect(parsed.reviews.single['id'], 20);
    expect(parsed.cards.single['deckId'], parsed.decks.single['id']);
    expect(parsed.reviews.single['cardId'], parsed.cards.single['id']);
  });

  test('rejects snapshots with broken references before import', () {
    final snapshot = validSnapshot();
    snapshot.cards.single['deckId'] = 999;

    expect(snapshot.validateForImport, throwsFormatException);
  });

  test('rejects legacy snapshots that cannot preserve record IDs', () {
    final legacyJson = '''
      {
        "app": "یادیار",
        "version": 2,
        "exportedAt": 1,
        "categories": [],
        "books": [],
        "decks": [],
        "cards": [],
        "reviews": [],
        "settings": null
      }
    ''';

    expect(() => AppSnapshot.fromJson(legacyJson), throwsFormatException);
  });

  test('loadFromFile rejects oversized or non-file input safely', () async {
    final directory = Directory.systemTemp.createTempSync(
      'yadyar_backup_test_',
    );
    addTearDown(directory.deleteSync);

    await expectLater(
      BackupService.loadFromFile(directory.path),
      throwsFormatException,
    );
  });
}
