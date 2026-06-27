import 'package:shamsi_date/shamsi_date.dart';

/// ابزارهای کمکی فارسی‌سازی: ارقام، اعداد، و تاریخ شمسی.
class Fa {
  Fa._();

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  /// تبدیل ارقام لاتین به فارسی در یک رشته.
  static String digits(Object input) {
    final s = input.toString();
    final buffer = StringBuffer();
    for (final ch in s.runes) {
      if (ch >= 48 && ch <= 57) {
        buffer.write(_faDigits[ch - 48]);
      } else {
        buffer.writeCharCode(ch);
      }
    }
    return buffer.toString();
  }

  /// عدد با جداکننده هزارگان فارسی، مثل ۱٬۲۴۰.
  static String number(num value) {
    final isNegative = value < 0;
    final intPart = value.abs().truncate().toString();
    final chars = intPart.split('');
    final out = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i != 0 && (chars.length - i) % 3 == 0) out.add('٬');
      out.add(chars[i]);
    }
    final result = digits(out.join());
    return isNegative ? '−$result' : result;
  }

  static const _months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  static const _weekdaysShort = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  /// نام ماه شمسی + سال، مثل «تیر ۱۴۰۴».
  static String monthYear(DateTime date) {
    final j = Jalali.fromDateTime(date);
    return '${_months[j.month - 1]} ${digits(j.year)}';
  }

  /// تاریخ کامل شمسی، مثل «۱۴ تیر ۱۴۰۴».
  static String fullDate(DateTime date) {
    final j = Jalali.fromDateTime(date);
    return '${digits(j.day)} ${_months[j.month - 1]} ${digits(j.year)}';
  }

  /// حرف کوتاه روز هفته شمسی (ش، ی، د، …) برای یک تاریخ.
  static String weekdayShort(DateTime date) {
    final j = Jalali.fromDateTime(date);
    // weekDay در Jalali: ۱=شنبه ... ۷=جمعه
    return _weekdaysShort[(j.weekDay - 1) % 7];
  }

  /// ساعت به‌صورت فارسی، مثل «۲۰:۰۵».
  static String clock(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return digits('$h:$m');
  }

  /// تخمین زمان مرور بر اساس تعداد کارت (تقریباً ۴۰ ثانیه برای هر کارت).
  static String estimateDuration(int cardCount) {
    final minutes = (cardCount * 40 / 60).ceil();
    if (minutes <= 1) return 'حدود ۱ دقیقه';
    return 'حدود ${digits(minutes)} دقیقه';
  }
}
