/// حالت تم اپ. مقدار ذخیره‌شده در دیتابیس همین نام‌هاست.
enum AppThemeMode { system, light, dark }

/// تنظیمات کاربر — یادآوری روزانه، هدف مطالعه، تم، صدا و لرزش.
class AppSettings {
  const AppSettings({
    this.reminderEnabled = true,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.dailyGoal = 20,
    this.themeMode = AppThemeMode.dark,
    this.typedAnswerMode = false,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.onboardingDone = false,
  });

  /// آیا یادآوری روزانه فعال است؟
  final bool reminderEnabled;

  /// ساعت و دقیقه‌ی یادآوری روزانه (۲۴ ساعته).
  final int reminderHour;
  final int reminderMinute;

  /// تعداد کارت هدف برای هر روز.
  final int dailyGoal;

  /// حالت تم (سیستم/روشن/تاریک).
  final AppThemeMode themeMode;

  /// حالت «تایپ جواب» در مرور (به‌جای فلیپ و خودارزیابی).
  final bool typedAnswerMode;

  /// آیا افکت‌های صوتی فعال هستند؟
  final bool soundEnabled;

  /// آیا لرزش (هپتیک) فعال است؟
  final bool hapticsEnabled;

  /// آیا کاربر آنبوردینگ را دیده است؟
  final bool onboardingDone;

  static const defaults = AppSettings();

  AppSettings copyWith({
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? dailyGoal,
    AppThemeMode? themeMode,
    bool? typedAnswerMode,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? onboardingDone,
  }) {
    return AppSettings(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      themeMode: themeMode ?? this.themeMode,
      typedAnswerMode: typedAnswerMode ?? this.typedAnswerMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  Map<String, Object?> toMap() => {
        'reminderEnabled': reminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'dailyGoal': dailyGoal,
        'themeMode': themeMode.name,
        'typedAnswerMode': typedAnswerMode,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'onboardingDone': onboardingDone,
      };

  factory AppSettings.fromMap(Map<String, Object?> map) => AppSettings(
        reminderEnabled: (map['reminderEnabled'] as bool?) ?? true,
        reminderHour: (map['reminderHour'] as int?) ?? 20,
        reminderMinute: (map['reminderMinute'] as int?) ?? 0,
        dailyGoal: (map['dailyGoal'] as int?) ?? 20,
        themeMode: AppThemeMode.values.firstWhere(
          (m) => m.name == map['themeMode'],
          orElse: () => AppThemeMode.dark,
        ),
        typedAnswerMode: (map['typedAnswerMode'] as bool?) ?? false,
        soundEnabled: (map['soundEnabled'] as bool?) ?? true,
        hapticsEnabled: (map['hapticsEnabled'] as bool?) ?? true,
        onboardingDone: (map['onboardingDone'] as bool?) ?? false,
      );
}
