import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// سرویس نوتیفیکیشن محلی: یادآوری روزانه، هشدار استریک، لول‌آپ و دستاورد.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // شناسه‌ی نوتیفیکیشن‌ها — بازه‌ی مجزا برای هر نوع.
  static const _dailyId = 1001; // یادآوری روزانه‌ی تکرارشونده
  static const _streakId = 1002; // هشدار یک‌بارمصرف حفظ استریک
  static const _levelUpId = 2001; // لول‌آپ
  static const _achievementId = 2002; // آنلاک دستاورد

  /// ساعت «آخرین فرصت» برای هشدار استریک (شب).
  static const streakGuardHour = 21;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Tehran'));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings: settings);

      // مجوز نمایش نوتیفیکیشن (Android 13+).
      await _android?.requestNotificationsPermission();
      // مجوز زنگ دقیق (Android 12+) تا یادآوری سرِ ساعت شلیک شود.
      await _android?.requestExactAlarmsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  /// سبک مشترک نوتیفیکیشن‌های فارسی — BigTextStyle برای نمایش کامل متن.
  static NotificationDetails _persianDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: const BigTextStyleInformation(''),
        // نمایش فارسی درست — اندروید ۱۳+ از فونت اپ استفاده می‌کند.
      ),
    );
  }

  static final _dailyDetails = _persianDetails(
    channelId: 'daily_review',
    channelName: 'یادآوری مرور روزانه',
    channelDescription: 'یادآوری برای انجام مرور فلش‌کارت‌ها',
  );

  static final _streakDetails = _persianDetails(
    channelId: 'streak_guard',
    channelName: 'حفظ استریک',
    channelDescription: 'هشدار وقتی استریک روزانه در خطر از دست رفتن است',
  );

  static final _celebrationDetails = _persianDetails(
    channelId: 'celebration',
    channelName: 'جشن و دستاورد',
    channelDescription: 'لول‌آپ و آنلاک دستاوردها',
  );

  /// نمایش فوری یک نوتیفیکیشن نمونه تا کاربر روی گوشی صحت کار را ببیند.
  Future<void> showTestNotification() async {
    if (!_ready) await init();
    try {
      await _plugin.show(
        id: 9999,
        title: 'یادیار',
        body: 'نوتیفیکیشن‌ها درست کار می‌کنن ✅ سرِ ساعت یادآوری می‌بینی‌شون.',
        notificationDetails: _dailyDetails,
      );
    } catch (e) {
      debugPrint('showTestNotification failed: $e');
    }
  }

  /// نمایش نوتیفیکیشن لول‌آپ — پس از ثبت مرور که سطح جدیدی باز می‌شود.
  Future<void> showLevelUpNotification(int newLevel) async {
    if (!_ready) await init();
    try {
      await _plugin.show(
        id: _levelUpId,
        title: 'لول‌آپ! 🎉',
        body: 'تبریک! به سطح $newLevel رسیدی. ادامه بده! 💪',
        notificationDetails: _celebrationDetails,
      );
    } catch (e) {
      debugPrint('showLevelUpNotification failed: $e');
    }
  }

  /// نمایش نوتیفیکیشن آنلاک دستاورد.
  Future<void> showAchievementNotification(
      String title, String description) async {
    if (!_ready) await init();
    try {
      await _plugin.show(
        id: _achievementId,
        title: 'دستاورد جدید! 🏆',
        body: '$title — $description',
        notificationDetails: _celebrationDetails,
      );
    } catch (e) {
      debugPrint('showAchievementNotification failed: $e');
    }
  }

  /// اعمال تنظیمات یادآوری روزانه: فعال‌سازی در ساعت مشخص یا لغو کامل.
  Future<void> applyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (enabled) {
      await scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await cancelDailyReminder();
    }
  }

  Future<void> cancelDailyReminder() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _dailyId);
    } catch (e) {
      debugPrint('cancelDailyReminder failed: $e');
    }
  }

  /// زمان‌بندی یادآوری روزانه‌ی تکرارشونده سرِ ساعت دقیق.
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: _dailyId,
        title: 'یادیار',
        body: 'وقت مروره! کارت‌هات منتظرتن 🧠',
        scheduledDate: _nextInstanceOf(hour, minute),
        notificationDetails: _dailyDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleDailyReminder failed: $e');
    }
  }

  /// یادآوری هوشمند استریک: فقط وقتی استریک فعال است و کاربر هنوز امروز مرور
  /// نکرده، یک هشدار شبانه‌ی یک‌بارمصرف می‌گذارد؛ در غیر این صورت آن را لغو می‌کند.
  /// باید هنگام باز شدن اپ و بعد از هر تغییر در مرور صدا زده شود.
  Future<void> updateStreakReminder({
    required bool reviewedToday,
    required int streakDays,
    required int dueCount,
  }) async {
    if (!_ready) return;
    try {
      // اگر امروز مرور انجام شده یا استریکی برای محافظت نیست → لغو.
      if (reviewedToday || streakDays < 1 || dueCount <= 0) {
        await _plugin.cancel(id: _streakId);
        return;
      }

      final when = _nextInstanceOf(streakGuardHour, 0);
      // اگر زمان هشدار تا فردا فاصله دارد (یعنی امروز گذشته)، بهتر است امشب
      // مزاحم نشویم؛ ولی برای فردا هم برنامه‌ریزی نگه می‌داریم تا استریک حفظ شود.
      final body = streakDays >= 2
          ? 'استریک $streakDays روزه‌ت داره می‌پره! 🔥 فقط $dueCount کارت مونده.'
          : 'امروز هنوز مرور نکردی — $dueCount کارت منتظرته 🔥';
      await _plugin.zonedSchedule(
        id: _streakId,
        title: 'استریکت رو از دست نده!',
        body: body,
        scheduledDate: when,
        notificationDetails: _streakDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('updateStreakReminder failed: $e');
    }
  }

  /// لغو هشدار استریک — وقتی کاربر امروز مرور کرد، استریک امروز امن است.
  Future<void> cancelStreakReminder() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _streakId);
    } catch (e) {
      debugPrint('cancelStreakReminder failed: $e');
    }
  }

  /// نزدیک‌ترین رخداد آینده‌ی ساعت/دقیقه‌ی داده‌شده در منطقه‌ی زمانی محلی.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
