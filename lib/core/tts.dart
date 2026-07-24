import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// تبدیل متن به گفتار — فقط برای لغات انگلیسی.
/// متن‌های فارسی، ریاضی (LaTeX) و نمادها تلفظ نمی‌شوند.
class TtsService {
  TtsService._();
  static final instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  static final _latin = RegExp(r'[A-Za-z]');
  static final _arabicScript = RegExp(r'[\u0600-\u06FF\u0750-\u077F]');
  // نمادهای ریاضی/LaTeX که در لغات عادی انگلیسی نیستند.
  static final _mathSymbols = RegExp(r'[\^_=\\${}<>|√∑∫πθαβγδ∞±×÷·]');

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    } catch (e) {
      debugPrint('TtsService init failed: $e');
    }
  }

  /// حذف بلاک‌های LaTeX (`$...$` و `$$...$$`) از متن.
  static String _stripLatex(String text) {
    return text
        .replaceAll(RegExp(r'\$\$[^$]*\$\$'), '')
        .replaceAll(RegExp(r'\$[^$]*\$'), '')
        .trim();
  }

  /// آیا متن قابل تلفظ است؟
  /// فقط لغات انگلیسی واقعی (بدون فارسی و بدون نماد ریاضی) قابل تلفظ‌اند.
  static bool isSpeakable(String text) {
    final value = text.trim();
    if (value.isEmpty) return false;
    // حذف LaTeX برای بررسی محتوای واقعی.
    final cleaned = _stripLatex(value);
    if (cleaned.isEmpty) return false;
    // نباید حروف فارسی/عربی داشته باشد.
    if (_arabicScript.hasMatch(cleaned)) return false;
    // باید حداقل یک حرف لاتین داشته باشد.
    if (!_latin.hasMatch(cleaned)) return false;
    // نباید نمادهای ریاضی داشته باشد.
    if (_mathSymbols.hasMatch(cleaned)) return false;
    return true;
  }

  Future<void> speak(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    // فقط لغات انگلیسی تلفظ می‌شوند.
    if (!isSpeakable(value)) return;
    await _ensureReady();
    try {
      await _tts.stop();
      await _tts.setLanguage('en-US');
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
