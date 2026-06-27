import '../db/app_database.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../repositories/card_repository.dart';
import '../repositories/deck_repository.dart';

/// داده‌های اولیه: سه دک آماده مطابق PRD (کنکور / IELTS / استخدامی).
class SeedData {
  SeedData._();

  /// اگر دیتابیس خالی است، دک‌ها و کارت‌های نمونه را می‌سازد.
  static Future<void> ensureSeeded(AppDatabase db) async {
    final deckRepo = DeckRepository(db);
    final cardRepo = CardRepository(db);
    if (await deckRepo.count() > 0) return;

    final now = DateTime.now();

    for (final spec in _decks) {
      final deckId = await deckRepo.add(Deck(
        title: spec.title,
        description: spec.description,
        colorHex: spec.colorHex,
        createdAt: now,
        isBuiltIn: true,
      ));
      final cards = spec.cards
          .map((qa) => FlashCard(
                deckId: deckId,
                front: qa.$1,
                back: qa.$2,
                nextReview: now,
              ))
          .toList();
      await cardRepo.addAll(cards);
    }
  }

  static final _decks = <_DeckSpec>[
    _DeckSpec(
      title: 'کنکور ریاضی ۱۴۰۴',
      description: 'فرمول‌ها و مفاهیم کلیدی ریاضی کنکور',
      colorHex: 0xFF7F77DD,
      cards: const [
        (r'مشتق $\sin(x)$ چیست؟', r'$\cos(x)$'),
        (r'مشتق $\cos(x)$ چیست؟', r'$-\sin(x)$'),
        ('فرمول حل معادله درجه دو', r'$x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$'),
        (r'مساحت دایره به شعاع $r$', r'$\pi r^2$'),
        (r'انتگرال $\frac{1}{x}$ چیست؟', r'$\ln|x| + C$'),
        ('قضیه فیثاغورس', r'$a^2 + b^2 = c^2$ در مثلث قائم‌الزاویه'),
        (r'مجموع $n$ جمله اول تصاعد حسابی', r'$S_n = \frac{n}{2}(a_1 + a_n)$'),
        (r'حد $\frac{\sin x}{x}$ وقتی $x \to 0$', r'برابر $1$ است'),
        (r'لگاریتم حاصل‌ضرب: $\log(ab)$', r'$\log a + \log b$'),
        (r'مشتق $e^x$ چیست؟', r'$e^x$ (بدون تغییر)'),
        (r'حجم کره به شعاع $r$', r'$\frac{4}{3}\pi r^3$'),
        ('تعریف تابع زوج', r'$f(-x) = f(x)$ برای همه $x$'),
      ],
    ),
    _DeckSpec(
      title: 'لغات IELTS',
      description: 'واژگان پرکاربرد آزمون آیلتس',
      colorHex: 0xFF5DCAA5,
      cards: const [
        ('Ubiquitous', 'همه‌جا حاضر، فراگیر'),
        ('Meticulous', 'دقیق و موشکافانه'),
        ('Inevitable', 'اجتناب‌ناپذیر'),
        ('Profound', 'عمیق، ژرف'),
        ('Ambiguous', 'مبهم، دوپهلو'),
        ('Diligent', 'کوشا، سخت‌کوش'),
        ('Reluctant', 'بی‌میل، اکراه‌دار'),
        ('Coherent', 'منسجم، هماهنگ'),
        ('Pragmatic', 'عمل‌گرا، واقع‌بین'),
        ('Scrutinize', 'به‌دقت بررسی کردن'),
        ('Mitigate', 'کاهش دادن، تخفیف دادن'),
        ('Resilient', 'انعطاف‌پذیر، تاب‌آور'),
        ('Tedious', 'خسته‌کننده، ملال‌آور'),
        ('Versatile', 'همه‌کاره، چندمنظوره'),
      ],
    ),
    _DeckSpec(
      title: 'آزمون استخدامی',
      description: 'اطلاعات عمومی و دانش حقوقی پایه',
      colorHex: 0xFFEF9F27,
      cards: const [
        ('پایتخت استان فارس کدام شهر است؟', 'شیراز'),
        ('قانون اساسی ایران در چه سالی بازنگری شد؟', 'سال ۱۳۶۸'),
        ('بلندترین قله ایران', 'قله دماوند'),
        ('سه قوه نظام جمهوری اسلامی', 'مقننه، مجریه، قضائیه'),
        ('نویسنده «بوف کور»', 'صادق هدایت'),
        ('واحد پول رسمی ایران', 'ریال'),
        ('بزرگ‌ترین دریاچه ایران', 'دریاچه ارومیه'),
        ('سال شروع جنگ تحمیلی', 'سال ۱۳۵۹'),
        ('تعداد نمایندگان مجلس شورای اسلامی', '۲۹۰ نماینده'),
        ('شاعر «شاهنامه»', 'فردوسی'),
        ('قدیمی‌ترین دانشگاه ایران', 'دانشگاه تهران'),
        ('واحد اندازه‌گیری شدت زلزله', 'مقیاس ریشتر'),
      ],
    ),
  ];
}

class _DeckSpec {
  const _DeckSpec({
    required this.title,
    required this.description,
    required this.colorHex,
    required this.cards,
  });

  final String title;
  final String description;
  final int colorHex;
  final List<(String, String)> cards;
}
