import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/notifications.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/rating.dart';
import '../../data/models/review_log.dart';
import '../../domain/answer_match.dart';
import '../../domain/sm2.dart';
import '../../domain/weak_cards.dart';
import '../../providers/providers.dart';

/// شناسه‌ی ساختگی برای «مرور همه‌ی دک‌ها».
const int kAllDecks = -1;

/// شناسه‌ی ساختگی برای «مرور نقاط ضعف» (کارت‌های سخت در همه‌ی دک‌ها).
const int kWeakCards = -2;

/// وضعیت یک نشست مرور.
class ReviewState {
  const ReviewState({
    this.loading = true,
    this.cards = const [],
    this.index = 0,
    this.showAnswer = false,
    this.hard = 0,
    this.good = 0,
    this.easy = 0,
    this.canUndo = false,
    this.typedAnswer = '',
    this.typedCorrect = false,
  });

  final bool loading;
  final List<FlashCard> cards;
  final int index;
  final bool showAnswer;
  final int hard;
  final int good;
  final int easy;

  /// آیا می‌توان آخرین ارزیابی را لغو کرد؟
  final bool canUndo;

  /// جوابِ تایپ‌شده‌ی کاربر در حالت تایپ (خالی یعنی هنوز جواب نداده).
  final String typedAnswer;

  /// آیا جوابِ تایپ‌شده درست بود؟
  final bool typedCorrect;

  int get total => cards.length;
  int get position => index + 1;
  bool get finished => !loading && index >= cards.length;
  FlashCard? get current =>
      index < cards.length ? cards[index] : null;
  double get progress => total == 0 ? 0 : index / total;

  ReviewState copyWith({
    bool? loading,
    List<FlashCard>? cards,
    int? index,
    bool? showAnswer,
    int? hard,
    int? good,
    int? easy,
    bool? canUndo,
    String? typedAnswer,
    bool? typedCorrect,
  }) {
    return ReviewState(
      loading: loading ?? this.loading,
      cards: cards ?? this.cards,
      index: index ?? this.index,
      showAnswer: showAnswer ?? this.showAnswer,
      hard: hard ?? this.hard,
      good: good ?? this.good,
      easy: easy ?? this.easy,
      canUndo: canUndo ?? this.canUndo,
      typedAnswer: typedAnswer ?? this.typedAnswer,
      typedCorrect: typedCorrect ?? this.typedCorrect,
    );
  }
}

/// یک گام قابل‌بازگشت: کارت پیش از ارزیابی + شناسه‌ی لاگ ثبت‌شده.
class _UndoEntry {
  const _UndoEntry({
    required this.previousCard,
    required this.reviewLogId,
    required this.atIndex,
    required this.rating,
  });

  final FlashCard previousCard;
  final int reviewLogId;
  final int atIndex;
  final Rating rating;
}

class ReviewController extends StateNotifier<ReviewState> {
  ReviewController(this._ref, this.deckId) : super(const ReviewState()) {
    _load();
  }

  final Ref _ref;
  final int deckId;
  DateTime _cardShownAt = DateTime.now();
  final List<_UndoEntry> _undoStack = [];

  Future<void> _load() async {
    final cardRepo = _ref.read(cardRepositoryProvider);
    final now = DateTime.now();

    List<FlashCard> queue;
    if (deckId == kWeakCards) {
      // نشست نقاط ضعف: کارت‌های سخت در همه‌ی دک‌ها، فارغ از سررسید.
      final cards = await cardRepo.getAll();
      final logs = await _ref.read(reviewRepositoryProvider).getAll();
      queue = WeakCards.select(cards, logs);
    } else {
      final all = deckId == kAllDecks
          ? await cardRepo.getAll()
          : await cardRepo.getByDeck(deckId);
      queue = all.where((c) => c.isDueAt(now)).toList()
        ..sort((a, b) => a.nextReview.compareTo(b.nextReview));
    }

    _cardShownAt = DateTime.now();
    state = state.copyWith(loading: false, cards: queue, index: 0);
  }

  void flip() {
    if (state.showAnswer) return;
    HapticFeedback.lightImpact();
    state = state.copyWith(showAnswer: true);
  }

  /// در حالت تایپ: جواب کاربر را بررسی و نتیجه را نمایش می‌دهد (هنوز جلو نمی‌رود).
  void submitTyped(String answer) {
    final card = state.current;
    if (card == null || state.showAnswer) return;
    final correct = AnswerMatcher.matches(answer, card.back);
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    state = state.copyWith(
      showAnswer: true,
      typedAnswer: answer.trim().isEmpty ? '—' : answer.trim(),
      typedCorrect: correct,
    );
  }

  /// در حالت تایپ پس از دیدن نتیجه: بر اساس درستیِ جواب امتیاز می‌دهد.
  Future<void> continueTyped() => rate(state.typedCorrect ? Rating.good : Rating.hard);

  Future<void> rate(Rating rating) async {
    final card = state.current;
    if (card == null) return;

    HapticFeedback.mediumImpact();
    // کاربر امروز مرور کرد → استریک امروز امن است، هشدار را لغو کن.
    NotificationService.instance.cancelStreakReminder();

    final now = DateTime.now();
    final updated = Sm2.apply(card, rating.quality, now: now);
    await _ref.read(cardRepositoryProvider).update(updated);
    final logId = await _ref.read(reviewRepositoryProvider).add(ReviewLog(
          cardId: card.id!,
          deckId: card.deckId,
          quality: rating.quality,
          reviewedAt: now,
          durationMs: now.difference(_cardShownAt).inMilliseconds,
        ));

    // ذخیره‌ی وضعیت پیش از ارزیابی برای امکان بازگشت.
    _undoStack.add(_UndoEntry(
      previousCard: card,
      reviewLogId: logId,
      atIndex: state.index,
      rating: rating,
    ));

    var hard = state.hard, good = state.good, easy = state.easy;
    switch (rating) {
      case Rating.hard:
        hard++;
      case Rating.good:
        good++;
      case Rating.easy:
        easy++;
    }

    _cardShownAt = DateTime.now();
    state = state.copyWith(
      index: state.index + 1,
      showAnswer: false,
      hard: hard,
      good: good,
      easy: easy,
      canUndo: true,
      typedAnswer: '',
      typedCorrect: false,
    );
  }

  /// لغو آخرین ارزیابی: بازگرداندن کارت به وضعیت قبلی و حذف لاگ آن.
  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final entry = _undoStack.removeLast();

    await _ref.read(cardRepositoryProvider).update(entry.previousCard);
    await _ref.read(reviewRepositoryProvider).delete(entry.reviewLogId);

    var hard = state.hard, good = state.good, easy = state.easy;
    switch (entry.rating) {
      case Rating.hard:
        hard--;
      case Rating.good:
        good--;
      case Rating.easy:
        easy--;
    }

    _cardShownAt = DateTime.now();
    state = state.copyWith(
      index: entry.atIndex,
      showAnswer: true,
      hard: hard,
      good: good,
      easy: easy,
      canUndo: _undoStack.isNotEmpty,
      typedAnswer: '',
      typedCorrect: false,
    );
  }
}

final reviewControllerProvider = StateNotifierProvider.autoDispose
    .family<ReviewController, ReviewState, int>((ref, deckId) {
  return ReviewController(ref, deckId);
});
