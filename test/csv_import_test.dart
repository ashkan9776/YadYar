import 'package:flutter_test/flutter_test.dart';
import 'package:yadyar/data/services/csv_import_service.dart';

void main() {
  group('جداکننده‌ها', () {
    test('Tab (فرمت خام Anki)', () {
      final share = CsvImportService.parse(
        'word1\tmeaning1\nword2\tmeaning2\n',
        fileName: 'english.csv',
      );
      expect(share.cards.length, 2);
      expect(share.cards.first.front, 'word1');
      expect(share.cards.first.back, 'meaning1');
    });

    test('کاما', () {
      final share = CsvImportService.parse(
        'سوال اول,جواب اول\nسوال دوم,جواب دوم',
        fileName: 'fa.csv',
      );
      expect(share.cards.length, 2);
      expect(share.cards[1].front, 'سوال دوم');
    });

    test('سمی‌کالن', () {
      final share = CsvImportService.parse('a1;b1\na2;b2', fileName: 'x.csv');
      expect(share.cards.length, 2);
    });

    test('ستون سوم Anki (تگ‌ها) نادیده گرفته می‌شود', () {
      final share = CsvImportService.parse(
        'front1\tback1\ttag1 tag2\nfront2\tback2\ttag3',
        fileName: 'anki.txt',
      );
      expect(share.cards.length, 2);
      expect(share.cards.first.back, 'back1');
    });
  });

  group('کوتیشن و هدر', () {
    test('فیلد کوتیشن‌دار حاوی کاما', () {
      final share = CsvImportService.parse(
        '"سوال، با کاما","جواب"',
        fileName: 'q.csv',
      );
      expect(share.cards.single.front, 'سوال، با کاما');
    });

    test('کوتیشن فراری ("" → ")', () {
      final share = CsvImportService.parse(
        '"گوته گفت ""بزرگ""","نقل قول"',
        fileName: 'q.csv',
      );
      expect(share.cards.single.front, 'گوته گفت "بزرگ"');
    });

    test('ردیف هدر انگلیسی حذف می‌شود', () {
      final share = CsvImportService.parse(
        'Front\tBack\nf1\tb1',
        fileName: 'a.csv',
      );
      expect(share.cards.length, 1);
      expect(share.cards.first.front, 'f1');
    });

    test('ردیف هدر فارسی حذف می‌شود', () {
      final share = CsvImportService.parse(
        'پیش,پشت\nس,ج',
        fileName: 'a.csv',
      );
      expect(share.cards.length, 1);
      expect(share.cards.first.front, 'س');
    });

    test('ردیف اول عادی هدر تلقی نمی‌شود', () {
      final share = CsvImportService.parse('سلام,خداحافظ', fileName: 'a.csv');
      expect(share.cards.length, 1);
    });
  });

  group('پاکسازی HTML خروجی Anki', () {
    test('<br> تبدیل به خط جدید و تگ‌ها حذف می‌شوند', () {
      final share = CsvImportService.parse(
        'line1<br>line2\t<b>bold</b> text',
        fileName: 'anki.csv',
      );
      expect(share.cards.single.front, 'line1\nline2');
      expect(share.cards.single.back, 'bold text');
    });

    test('entityهای رایج دیکود می‌شوند', () {
      final share = CsvImportService.parse(
        'a &amp; b &lt;c&gt;\tx &quot;y&quot; &#39;z&#39;',
        fileName: 'anki.csv',
      );
      expect(share.cards.single.front, 'a & b <c>');
      expect(share.cards.single.back, 'x "y" \'z\'');
    });

    test('&nbsp; تبدیل به فاصله', () {
      final share = CsvImportService.parse('a&nbsp;&nbsp;b\tx', fileName: 'a.csv');
      expect(share.cards.single.front, 'a  b');
    });
  });

  group('اعتبارسنجی و عنوان', () {
    test('ردیف‌های خالی و ناقص رد می‌شوند', () {
      final share = CsvImportService.parse(
        '\n\nفقط یک ستون\n\nvalid\tanswer\n',
        fileName: 'a.csv',
      );
      expect(share.cards.length, 1);
      expect(share.cards.first.front, 'valid');
    });

    test('فایل بدون هیچ کارت معتبر → خطا', () {
      expect(
        () => CsvImportService.parse('empty file', fileName: 'a.csv'),
        throwsException,
      );
    });

    test('عنوان دک از نام فایل ساخته می‌شود', () {
      final share = CsvImportService.parse('a\tb', fileName: 'my-deck.csv');
      expect(share.title, 'my deck');
    });

    test('CRLF (ویندوز) پشتیبانی می‌شود', () {
      final share = CsvImportService.parse(
        'a1\tb1\r\na2\tb2\r\n',
        fileName: 'win.csv',
      );
      expect(share.cards.length, 2);
      expect(share.cards.first.back, 'b1');
    });
  });
}
