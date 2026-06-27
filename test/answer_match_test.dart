import 'package:flutter_test/flutter_test.dart';
import 'package:yadyar/domain/answer_match.dart';

void main() {
  test('تطبیق دقیق', () {
    expect(AnswerMatcher.matches('cos(x)', 'cos(x)'), isTrue);
  });

  test('چشم‌پوشی از فاصله و حروف بزرگ/کوچک', () {
    expect(AnswerMatcher.matches('  COS X ', 'cos(x)'), isTrue);
  });

  test('تحمل غلط املایی جزئی در کلمه‌ی بلند', () {
    expect(AnswerMatcher.matches('inevitible', 'inevitable'), isTrue);
  });

  test('کلمه‌ی کوتاهِ غلط رد می‌شود', () {
    expect(AnswerMatcher.matches('cot', 'cos'), isFalse);
  });

  test('جواب چندبخشی: هر بخش پذیرفته می‌شود', () {
    expect(AnswerMatcher.matches('فراگیر', 'همه‌جا حاضر، فراگیر'), isTrue);
    expect(AnswerMatcher.matches('همه جا حاضر', 'همه‌جا حاضر، فراگیر'), isTrue);
  });

  test('یکسان‌سازی ي/ك عربی با ی/ک فارسی', () {
    expect(AnswerMatcher.matches('كوشا', 'کوشا'), isTrue);
  });

  test('جواب خالی رد می‌شود', () {
    expect(AnswerMatcher.matches('   ', 'چیزی'), isFalse);
  });
}
