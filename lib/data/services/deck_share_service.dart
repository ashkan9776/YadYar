import '../models/deck.dart';
import '../models/deck_share.dart';
import '../models/flashcard.dart';
import '../repositories/card_repository.dart';
import '../repositories/deck_repository.dart';

/// سرویس اشتراک‌گذاری دک — خروجی و ورودی دک به‌صورت JSON.
class DeckShareService {
  DeckShareService(this._deckRepo, this._cardRepo);

  final DeckRepository _deckRepo;
  final CardRepository _cardRepo;

  /// ساخت خروجی قابل اشتراک‌گذاری از یک دک و کارت‌هایش.
  Future<DeckShare> exportDeck({required int deckId}) async {
    final deck = await _deckRepo.getById(deckId);
    if (deck == null) throw Exception('دک یافت نشد');

    final cards = await _cardRepo.getByDeck(deckId);
    final filtered = cards
        .where((c) => c.front.isNotEmpty && c.back.isNotEmpty)
        .map((c) => (front: c.front, back: c.back))
        .toList();

    return DeckShare(
      title: deck.title,
      description: deck.description,
      colorHex: deck.colorHex,
      cards: filtered,
    );
  }

  /// وارد کردن دک از JSON — ساخت دک جدید با کارت‌های تمیز زیر کتاب مشخص.
  /// برمی‌گرداند: شناسه‌ی دک ساخته‌شده.
  Future<int> importDeck(DeckShare share, {required int bookId}) async {
    final deck = Deck(
      bookId: bookId,
      title: share.title,
      description: share.description,
      colorHex: share.colorHex,
      createdAt: DateTime.now(),
      isBuiltIn: false,
    );
    final newDeckId = await _deckRepo.add(deck);

    for (final card in share.cards) {
      await _cardRepo.add(FlashCard(
        deckId: newDeckId,
        front: card.front,
        back: card.back,
        nextReview: DateTime.now(),
      ));
    }

    return newDeckId;
  }
}
