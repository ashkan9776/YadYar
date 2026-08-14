import 'package:flutter_test/flutter_test.dart';

import 'package:sembast/sembast_memory.dart';
import 'package:yadyar/data/models/flashcard.dart';
import 'package:yadyar/data/models/review_log.dart';
import 'package:yadyar/data/repositories/card_repository.dart';
import 'package:yadyar/data/repositories/review_repository.dart';

void main() {
  var databaseNumber = 0;
  late Database database;
  late CardRepository cards;
  late ReviewRepository reviews;

  setUp(() async {
    database = await databaseFactoryMemory.openDatabase(
      'transaction-test-${databaseNumber++}',
    );
    cards = CardRepository.withDatabase(database);
    reviews = ReviewRepository.withDatabase(database);
  });

  tearDown(() => database.close());

  FlashCard card({int? id, int interval = 0}) => FlashCard(
    id: id,
    deckId: 1,
    front: 'front',
    back: 'back',
    nextReview: DateTime(2026, 1, 1),
    interval: interval,
  );

  test(
    'recordReview persists the card update and review log together',
    () async {
      final cardId = await cards.add(card());
      final updated = card(id: cardId, interval: 3);

      final logId = await reviews.recordReview(
        updatedCard: updated,
        log: ReviewLog(
          cardId: cardId,
          deckId: 1,
          quality: 4,
          reviewedAt: DateTime(2026, 1, 2),
          durationMs: 500,
        ),
      );

      expect((await cards.getAll()).single.interval, 3);
      final savedLog = (await reviews.getAll()).single;
      expect(savedLog.id, logId);
      expect(savedLog.cardId, cardId);
    },
  );

  test(
    'undoReview restores the card and removes its review log together',
    () async {
      final cardId = await cards.add(card());
      final original = card(id: cardId);
      final logId = await reviews.recordReview(
        updatedCard: card(id: cardId, interval: 3),
        log: ReviewLog(
          cardId: cardId,
          deckId: 1,
          quality: 4,
          reviewedAt: DateTime(2026, 1, 2),
          durationMs: 500,
        ),
      );

      await reviews.undoReview(previousCard: original, reviewLogId: logId);

      expect((await cards.getAll()).single.interval, 0);
      expect(await reviews.getAll(), isEmpty);
    },
  );

  test('delete removes a card and its review logs together', () async {
    final cardId = await cards.add(card());
    await reviews.add(
      ReviewLog(
        cardId: cardId,
        deckId: 1,
        quality: 4,
        reviewedAt: DateTime(2026, 1, 2),
        durationMs: 500,
      ),
    );

    await cards.delete(cardId);

    expect(await cards.getAll(), isEmpty);
    expect(await reviews.getAll(), isEmpty);
  });
}
