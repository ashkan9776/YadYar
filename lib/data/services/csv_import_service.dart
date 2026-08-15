import '../models/deck_share.dart';

/// ایمپورت CSV/متن از Anki و Quizlet — تبدیل به [DeckShare] برای فلوی
/// `importDeck` موجود. بدون پکیج خارجی.
///
/// پشتیبانی:
/// - تشخیص خودکار جداکننده (Tab > کاما > سمی‌کالن) از خط اول
/// - فیلدهای داخل کوتیشن (استاندارد CSV)
/// - حذف ردیف هدر (front/back/term/پیش/پشت و...)
/// - پاکسازی HTML خروجی Anki (`<br>` → خط جدید، حذف تگ‌ها، entityها)
class CsvImportService {
  CsvImportService._();

  /// حداقل تعداد کارت لازم تا فایل معتبر شمرده شود.
  static const int minCards = 1;

  /// تجزیه‌ی محتوای CSV/TXT و ساخت دک قابل ایمپورت.
  /// [fileName] فقط برای عنوان دک است (بدون پسوند).
  static DeckShare parse(String content, {required String fileName}) {
    final rows = _parseRows(content);
    final cards = <({String front, String back})>[];
    for (final row in rows) {
      if (row.length < 2) continue;
      final front = _clean(row[0]);
      final back = _clean(row[1]);
      if (front.isEmpty || back.isEmpty) continue;
      cards.add((front: front, back: back));
    }
    if (cards.length < minCards) {
      throw Exception('هیچ کارت معتبری در فایل پیدا نشد (هر خط باید «سوال، جواب» باشد)');
    }

    final title = _titleFromFileName(fileName);
    return DeckShare(
      title: title,
      description: 'واردشده از فایل $fileName',
      colorHex: 0xFF7F77DD,
      cards: cards,
    );
  }

  /// تجزیه‌ی ردیف‌ها: تشخیص جداکننده، حذف هدر، پشتیبانی کوتیشن.
  static List<List<String>> _parseRows(String content) {
    final lines = content
        .split('\n')
        .map((l) => l.trimRight().replaceAll('\r', ''))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final delimiter = _sniffDelimiter(lines.first);
    final rows = lines.map((l) => _splitLine(l, delimiter)).toList();
    if (rows.isNotEmpty && _isHeader(rows.first)) {
      rows.removeAt(0);
    }
    return rows;
  }

  /// جداکننده با اولویت ثابت: Tab (فرمت خام Anki) > کاما > سمی‌کالن.
  /// اولویت به‌جای شمارش، چون entityهای HTML خودشان «;» دارند و شمارش
  /// سمی‌کالن را غلط بالا می‌برد.
  static String _sniffDelimiter(String line) {
    int countOf(String d) => line.split(d).length - 1;
    if (countOf('\t') > 0) return '\t';
    if (countOf(',') > 0) return ',';
    if (countOf(';') > 0) return ';';
    return '\t'; // بدون جداکننده → پیش‌فرض فرمت خام Anki
  }

  /// تقسیم یک خط با پشتیبانی از فیلدهای کوتیشن‌دار استاندارد CSV.
  static List<String> _splitLine(String line, String delimiter) {
    final fields = <String>[];
    final current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"'); // کوتیشن فراری "" داخل فیلد
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == delimiter && !inQuotes) {
        fields.add(current.toString());
        current.clear();
      } else {
        current.write(ch);
      }
    }
    fields.add(current.toString());
    return fields;
  }

  /// آیا ردیف اول هدر است؟ (front/back/term/definition/پیش/پشت/سوال/جواب...)
  static bool _isHeader(List<String> row) {
    if (row.length < 2) return false;
    final h = row.map((f) => f.trim().toLowerCase()).toList();
    const known = {
      'front', 'back', 'term', 'definition', 'word', 'meaning',
      'question', 'answer', 'پیش', 'پشت', 'سوال', 'جواب', 'روی', 'کارت',
    };
    // هدر است اگر هر دو ستون اول (یا حداقل یکی + ستون سوم شناخته‌شده) نام‌های معلوم باشند.
    return known.contains(h[0]) &&
        (known.contains(h[1]) ||
            (h.length > 2 && known.contains(h[2])));
  }

  /// پاکسازی HTML خروجی Anki: شکست خط، تگ‌ها و entityهای رایج.
  /// نکته‌ی ترتیب: تگ‌های واقعی اول حذف می‌شوند و بعد entityها دیکود؛
  /// وگرنه «&lt;» به «<» تبدیل شده و مثل تگ حذف می‌شود.
  static String _clean(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;
    s = s
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(div|p|li)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '') // بقیه‌ی تگ‌های واقعی
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return s;
  }

  /// «my-deck.csv» → «My deck»؛ اگر نام بی‌معنی بود، پیش‌فرض.
  static String _titleFromFileName(String fileName) {
    final base = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final t = base.trim().replaceAll(RegExp(r'[-_]+'), ' ').trim();
    if (t.isEmpty) return 'دک واردشده';
    return t;
  }
}
