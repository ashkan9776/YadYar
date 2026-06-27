import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/quiz.dart';
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

  Future<void> _load() async {
    final repo = _ref.read(cardRepositoryProvider);
    final cards = deckId == kAllDecks
        ? await repo.getAll()
        : await repo.getByDeck(deckId);
    state = QuizState(
      loading: false,
      questions: Quiz.build(cards),
      index: 0,
      correct: 0,
    );
  }

  void select(int i) {
    if (state.answered || state.current == null) return;
    final correct = i == state.current!.correctIndex;
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    state = QuizState(
      loading: false,
      questions: state.questions,
      index: state.index,
      selectedIndex: i,
      correct: state.correct + (correct ? 1 : 0),
    );
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
