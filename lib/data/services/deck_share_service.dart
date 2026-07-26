import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/deck_share.dart';

/// سرویس اشتراک‌گذاری دک — خروجی و ورودی دک به‌صورت JSON.
class DeckShareService {
  DeckShareService(this._db);

  final AppDatabase _db;

  /// ساخت خروجی قابل اشتراک‌گذاری از یک دک و کارت‌هایش.
  Future<DeckShare> exportDeck({
    required int deckId,
    required String title,
    required String? description,
    required int colorHex,
  }) async {
    final cardRecords = await AppDatabase.cards
        .find(_db.db, finder: Finder(filter: Filter.equals('deckId', deckId)));

    final cards = cardRecords.map((r) {
      final map = r.value;
      return (
        front: map['front'] as String? ?? '',
        back: map['back'] as String? ?? '',
      );
    }).where((c) => c.front.isNotEmpty && c.back.isNotEmpty).toList();

    return DeckShare(
      title: title,
      description: description,
      colorHex: colorHex,
      cards: cards,
    );
  }

  /// وارد کردن دک از فایل JSON — ساخت دک جدید با کارت‌های تمیز.
  /// برمی‌گرداند: شناسه‌ی دک ساخته‌شده.
  Future<int> importDeck(DeckShare share) async {
    // ساخت دک جدید.
    final deckMap = <String, Object?>{
      'title': share.title,
      'description': share.description,
      'colorHex': share.colorHex,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isBuiltIn': false,
    };
    final newDeckId = await AppDatabase.decks.add(_db.db, deckMap);

    // افزودن کارت‌ها با schedule تمیز (کارتی که تازه وارد شده).
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final card in share.cards) {
      await AppDatabase.cards.add(_db.db, {
        'deckId': newDeckId,
        'front': card.front,
        'back': card.back,
        'nextReview': now,
        'interval': 0,
        'easeFactor': 2.5,
        'repetitions': 0,
        'lastReviewed': null,
      });
    }

    return newDeckId;
  }
}
