/// تطبیق جوابِ تایپ‌شده‌ی کاربر با جوابِ کارت — با چشم‌پوشی از تفاوت‌های جزئی
/// (فاصله، نشانه‌ها، نیم‌فاصله، حروف عربی/فارسی) و کمی غلط املایی. منطق خالص.
class AnswerMatcher {
  AnswerMatcher._();

  /// نرمال‌سازی متن برای مقایسه.
  static String normalize(String s) {
    var t = s.trim().toLowerCase();
    t = t
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه') // ة → ه
        .replaceAll('‌', ' ') // نیم‌فاصله
        .replaceAll('\u200F', '')
        .replaceAll('\u200E', '')
        .replaceAll(RegExp('[ً-ْٰ]'), ''); // اعراب
    // حذف نشانه‌گذاری.
    t = t.replaceAll(RegExp(r'''[.,،؛:!؟?()\[\]{}«»"'\-_/\\]'''), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  /// فاصله‌ی لِوِنشتاین بین دو رشته.
  static int distance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        var m = curr[j] + 1;
        if (prev[j + 1] + 1 < m) m = prev[j + 1] + 1;
        if (prev[j] + cost < m) m = prev[j] + cost;
        curr[j + 1] = m;
      }
      for (var k = 0; k <= b.length; k++) {
        prev[k] = curr[k];
      }
    }
    return prev[b.length];
  }

  /// آیا [input] جوابِ [expected] را (با کمی اغماض) درست تطبیق می‌دهد؟
  /// جواب‌های چندبخشی (جداشده با «،» یا «/») هرکدام جداگانه پذیرفته می‌شوند.
  static bool matches(String input, String expected) {
    final ni = normalize(input);
    if (ni.isEmpty) return false;

    final options = <String>{normalize(expected)};
    for (final part in expected.split(RegExp(r'[،,/؛]'))) {
      final n = normalize(part);
      if (n.isNotEmpty) options.add(n);
    }

    for (final opt in options) {
      if (opt.isEmpty) continue;
      if (ni == opt) return true;
      // تحمل غلط: کلمات کوتاه باید دقیق باشند، بلندتر‌ها کمی اغماض دارند.
      final tol = opt.length <= 3 ? 0 : (opt.length <= 7 ? 1 : 2);
      if (distance(ni, opt) <= tol) return true;
    }
    return false;
  }
}
