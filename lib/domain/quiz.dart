import 'dart:math' as math;

import '../data/models/flashcard.dart';

/// یک پرسش چندگزینه‌ای ساخته‌شده از روی یک فلش‌کارت.
class QuizQuestion {
  const QuizQuestion({
    required this.card,
    required this.options,
    required this.correctIndex,
  });

  final FlashCard card;
  final List<String> options; // گزینه‌ها (بُر خورده)
  final int correctIndex;

  String get prompt => card.front;
  String get correctAnswer => options[correctIndex];
}

/// سازنده‌ی آزمون چندگزینه‌ای از روی کارت‌ها — منطق خالص و قابل‌تست.
class Quiz {
  Quiz._();

  /// از روی [cards] آزمون می‌سازد: جواب درست همان پشت کارت است و گزینه‌های
  /// نادرست از پشت سایر کارت‌ها انتخاب می‌شوند. اگر کارت کافی نباشد، فهرست
  /// خالی برمی‌گردد.
  static List<QuizQuestion> build(
    List<FlashCard> cards, {
    int maxQuestions = 15,
    int optionCount = 4,
    math.Random? random,
  }) {
    final rnd = random ?? math.Random();
    final valid = cards
        .where((c) => c.front.trim().isNotEmpty && c.back.trim().isNotEmpty)
        .toList();
    if (valid.length < 2) return const [];

    final allBacks = valid.map((c) => c.back).toList();
    final order = List<FlashCard>.from(valid)..shuffle(rnd);

    final questions = <QuizQuestion>[];
    for (final card in order.take(maxQuestions)) {
      final correct = card.back;
      final pool = allBacks.where((b) => b != correct).toSet().toList()
        ..shuffle(rnd);
      final distractors = pool.take(optionCount - 1).toList();
      final options = <String>[correct, ...distractors]..shuffle(rnd);
      questions.add(QuizQuestion(
        card: card,
        options: options,
        correctIndex: options.indexOf(correct),
      ));
    }
    return questions;
  }
}
