import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// سرویس افکت‌های صوتی — با SystemSound و HapticFeedback سیستمی.
/// صداها فقط زمانی پخش می‌شوند که `enabled` فعال باشد.
/// الگوی سینگلتون مطابق `TtsService`.
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  bool _enabled = true;

  /// فعال/غیرفعال‌کردن صدا از روی تنظیمات کاربر.
  set enabled(bool value) => _enabled = value;

  /// صدای کلیک ملایم — برای فلیپ کارت و ارزیابی «درست/خوب».
  Future<void> playClick() async {
    if (!_enabled) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('SoundService.playClick failed: $e');
    }
  }

  /// صدای فلیپ کارت — همان کلیک ملایم.
  Future<void> playFlip() => playClick();

  /// صدای هشدار برای جواب اشتباه — ترکیب لرزش سنگین + کلیک.
  /// لرزش مستقل از HapticFeedback gating نیست چون نشانه‌ی خطاست.
  Future<void> playWrong() async {
    if (!_enabled) return;
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('SoundService.playWrong failed: $e');
    }
  }

  /// صدای موفقیت برای پایان نشست تمرکز — چند کلیک با تأخیر (حالت جشن).
  Future<void> playSuccess() async {
    if (!_enabled) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      Timer(const Duration(milliseconds: 150), () => SystemSound.play(SystemSoundType.click));
      Timer(const Duration(milliseconds: 300), () => SystemSound.play(SystemSoundType.click));
    } catch (e) {
      debugPrint('SoundService.playSuccess failed: $e');
    }
  }
}
