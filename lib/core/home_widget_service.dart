import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// سرویس هماهنگی با ویجت صفحه‌ی خانه‌ی اندروید.
/// تعداد کارت‌های سررسید امروز را به ویجت می‌فرستد.
class HomeWidgetService {
  HomeWidgetService._();

  /// نام BroadcastReceiver ویجت (مطابق کاتلین).
  static const _androidProvider =
      'com.ahoura.yadyar.YadyarWidgetProvider';

  /// کلید ذخیره‌ی تعداد سررسیدها در SharedPreferences مشترک.
  static const _dueCountKey = 'dueCount';

  /// به‌روزرسانی تعداد کارت‌های سررسید در ویجت.
  /// فقط روی Android/iOS اجرا می‌شود؛ روی سایر پلتفرم‌ها بی‌اثر است.
  static Future<void> updateDueCount(int count) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await HomeWidget.saveWidgetData(_dueCountKey, count);
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (e) {
      // ویجت اختیاری است — نباید اپ را خراب کند.
      debugPrint('HomeWidgetService.updateDueCount failed: $e');
    }
  }
}
