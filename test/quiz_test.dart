import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:yadyar/data/models/flashcard.dart';
import 'package:yadyar/domain/quiz.dart';

FlashCard _card(String front, String back) =>
    FlashCard(deckId: 1, front: front, back: back, nextReview: DateTime(2026));

void main() {
  final cards = [
    _card('سوال ۱', 'جواب ۱'),
    _card('سوال ۲', 'جواب ۲'),
    _card('سوال ۳', 'جواب ۳'),
    _card('سوال ۴', 'جواب ۴'),
    _card('سوال ۵', 'جواب ۵'),
  ];

  test('Quiz هر سوال جواب درست معتبر و گزینه‌ها بدون تکرار دارد', () {
    final quiz = Quiz.build(cards, random: math.Random(1));
    expect(quiz.length, cards.length);
    for (final q in quiz) {
      // جواب درست همان پشت کارت است.
      expect(q.correctAnswer, q.card.back);
      // ایندکس درست در محدوده است.
      expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
      // گزینه‌ها تکراری نیستند.
      expect(q.options.toSet().length, q.options.length);
      // گزینه‌ها حداکثر ۴ تا هستند.
      expect(q.options.length, lessThanOrEqualTo(4));
    }
  });

  test('Quiz با کمتر از ۲ کارت خالی برمی‌گردد', () {
    expect(Quiz.build([_card('تنها', 'یک')]), isEmpty);
    expect(Quiz.build(const []), isEmpty);
  });

  test('Quiz تعداد سوال‌ها را به maxQuestions محدود می‌کند', () {
    final many = List.generate(30, (i) => _card('س$i', 'ج$i'));
    final quiz = Quiz.build(many, maxQuestions: 10, random: math.Random(2));
    expect(quiz.length, 10);
  });

  test('Quiz کارت‌های با متن خالی را نادیده می‌گیرد', () {
    final withBlank = [...cards, _card('  ', 'خالی'), _card('پر', '   ')];
    final quiz = Quiz.build(withBlank, random: math.Random(3));
    expect(quiz.length, cards.length);
  });
}
