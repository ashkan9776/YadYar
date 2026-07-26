import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/models/review_log.dart';
import '../../domain/quiz.dart';
import '../../domain/sm2.dart';
import '../../providers/providers.dart';
import '../review/review_controller.dart' show kAllDecks;

/// وضعیت یک نشست آزمون چندگزینه‌ای.
class QuizState {
  const QuizState({
    this.loading = true,
    this.questions = const [],
    this.index = 0,
    this.selectedIndex,
    this.correct = 0,
  });

  final bool loading;
  final List<QuizQuestion> questions;
  final int index;
  final int? selectedIndex; // انتخاب فعلی؛ null یعنی هنوز جواب نداده
  final int correct;

  bool get answered => selectedIndex != null;
  bool get finished => !loading && questions.isNotEmpty && index >= questions.length;
  bool get isEmpty => !loading && questions.isEmpty;
  int get total => questions.length;
  int get position => index + 1;
  double get progress => total == 0 ? 0 : index / total;
  QuizQuestion? get current =>
      index < questions.length ? questions[index] : null;
}

class QuizController extends StateNotifier<QuizState> {
  QuizController(this._ref, this.deckId) : super(const QuizState()) {
    _load();
  }

  final Ref _ref;
  final int deckId;

  /// نگاشت index سوال به کارت متناظر (برای ثبت لاگ SM-2).
  final List<int> _cardIds = [];

  Future<void> _load() async {
    final repo = _ref.read(cardRepositoryProvider);
    final cards = deckId == kAllDecks
        ? await repo.getAll()
        : await repo.getByDeck(deckId);
    final questions = Quiz.build(cards);
    // ذخیره‌ی شناسه‌ی کارت متناظر با هر سوال (به‌همان ترتیب).
    _cardIds.clear();
    for (final q in questions) {
      _cardIds.add(q.card.id ?? -1);
    }
    state = QuizState(
      loading: false,
      questions: questions,
      index: 0,
      correct: 0,
    );
  }

  void select(int i) async {
    if (state.answered || state.current == null) return;
    final isCorrect = i == state.current!.correctIndex;
    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    // ثبت لاگ مرور و اعمال SM-2 — کوییز هم روی زمان‌بندی تأثیر می‌گذارد.
    await _recordAnswer(isCorrect);

    state = QuizState(
      loading: false,
      questions: state.questions,
      index: state.index,
      selectedIndex: i,
      correct: state.correct + (isCorrect ? 1 : 0),
    );
  }

  /// ثبت جواب کوییز به‌عنوان لاگ مرور و اعمال SM-2.
  /// جواب درست → کیفیت ۴ (خوب)، جواب اشتباه → کیفیت ۳ (سخت).
  Future<void> _recordAnswer(bool isCorrect) async {
    if (state.index >= _cardIds.length) return;
    final cardId = _cardIds[state.index];
    final cardRepo = _ref.read(cardRepositoryProvider);
    final reviewRepo = _ref.read(reviewRepositoryProvider);

    // یافتن کارت متناظر برای اعمال SM-2.
    final allCards = await cardRepo.getAll();
    final card = allCards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return;

    final quality = isCorrect ? 4 : 3; // ۴ = خوب، ۳ = سخت
    final now = DateTime.now();
    final updated = Sm2.apply(card, quality, now: now);
    await cardRepo.update(updated);
    await reviewRepo.add(ReviewLog(
      cardId: cardId,
      deckId: card.deckId,
      quality: quality,
      reviewedAt: now,
      durationMs: 0, // کوییز زمان‌سنجی ندارد.
    ));
  }

  void next() {
    if (!state.answered) return;
    state = QuizState(
      loading: false,
      questions: state.questions,
      index: state.index + 1,
      selectedIndex: null,
      correct: state.correct,
    );
  }

  void restart() {
    state = QuizState(
      loading: false,
      questions: state.questions,
      index: 0,
      correct: 0,
    );
  }
}

final quizControllerProvider = StateNotifierProvider.autoDispose
    .family<QuizController, QuizState, int>((ref, deckId) {
  return QuizController(ref, deckId);
});
