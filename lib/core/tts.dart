import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// تبدیل متن به گفتار — تلفظ کلمه/جواب روی کارت‌ها.
/// زبان به‌صورت خودکار از روی نوشتار حدس زده می‌شود (انگلیسی یا فارسی).
class TtsService {
  TtsService._();
  static final instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  static final _latin = RegExp(r'[A-Za-z]');

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    } catch (e) {
      debugPrint('TtsService init failed: $e');
    }
  }

  /// آیا متن (عمدتاً) انگلیسی است؟
  static bool isLatin(String text) => _latin.hasMatch(text);

  Future<void> speak(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    await _ensureReady();
    try {
      await _tts.stop();
      await _tts.setLanguage(isLatin(value) ? 'en-US' : 'fa-IR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.speak(value);
    } catch (e) {
      debugPrint('TtsService speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TtsService stop failed: $e');
    }
  }
}
