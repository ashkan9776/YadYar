import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/notifications.dart';
import '../../core/sound.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/rating.dart';
import '../../data/models/review_log.dart';
import '../../domain/answer_match.dart';
import '../../domain/daily_challenge.dart';
import '../../domain/sm2.dart';
import '../../domain/weak_cards.dart';
import '../../providers/providers.dart';

/// شناسه‌ی ساختگی برای «مرور همه‌ی دک‌ها».
const int kAllDecks = -1;

/// شناسه‌ی ساختگی برای «مرور نقاط ضعف» (کارت‌های سخت در همه‌ی دک‌ها).
const int kWeakCards = -2;

/// وضعیت یک نشست مرور.
class ReviewState {
  const ReviewState({
    this.loading = true,
    this.cards = const [],
    this.index = 0,
    this.showAnswer = false,
    this.hard = 0,
    this.good = 0,
    this.easy = 0,
    this.canUndo = false,
    this.typedAnswer = '',
    this.typedCorrect = false,
    this.focusActive = false,
    this.focusRemainingSeconds = 0,
    this.focusTotalSeconds = 0,
    this.focusEnded = false,
  });

  final bool loading;
  final List<FlashCard> cards;
  final int index;
  final bool showAnswer;
  final int hard;
  final int good;
  final int easy;

  /// آیا می‌توان آخرین ارزیابی را لغو کرد؟
  final bool canUndo;

  /// جوابِ تایپ‌شده‌ی کاربر در حالت تایپ (خالی یعنی هنوز جواب نداده).
  final String typedAnswer;

  /// آیا جوابِ تایپ‌شده درست بود؟
  final bool typedCorrect;

  /// آیا حالت تمرکز فعال است؟
  final bool focusActive;

  /// ثانیه‌های باقیمانده‌ی تمرکز.
  final int focusRemainingSeconds;

  /// کل ثانیه‌های انتخاب‌شده برای تمرکز.
  final int focusTotalSeconds;

  /// آیا نشست به‌خاطر پایان زمان تمرکز تمام شده؟
  final bool focusEnded;

  int get total => cards.length;
  int get position => index + 1;

  /// نشست تمام شده یا با رسیدن به انتهای صف یا با پایان زمان تمرکز.
  bool get finished => !loading && (index >= cards.length || focusEnded);
  FlashCard? get current => index < cards.length ? cards[index] : null;
  double get progress => total == 0 ? 0 : index / total;

  ReviewState copyWith({
    bool? loading,
    List<FlashCard>? cards,
    int? index,
    bool? showAnswer,
    int? hard,
    int? good,
    int? easy,
    bool? canUndo,
    String? typedAnswer,
    bool? typedCorrect,
    bool? focusActive,
    int? focusRemainingSeconds,
    int? focusTotalSeconds,
    bool? focusEnded,
  }) {
    return ReviewState(
      loading: loading ?? this.loading,
      cards: cards ?? this.cards,
      index: index ?? this.index,
      showAnswer: showAnswer ?? this.showAnswer,
      hard: hard ?? this.hard,
      good: good ?? this.good,
      easy: easy ?? this.easy,
      canUndo: canUndo ?? this.canUndo,
      typedAnswer: typedAnswer ?? this.typedAnswer,
      typedCorrect: typedCorrect ?? this.typedCorrect,
      focusActive: focusActive ?? this.focusActive,
      focusRemainingSeconds:
          focusRemainingSeconds ?? this.focusRemainingSeconds,
      focusTotalSeconds: focusTotalSeconds ?? this.focusTotalSeconds,
      focusEnded: focusEnded ?? this.focusEnded,
    );
  }
}

/// یک گام قابل‌بازگشت: کارت پیش از ارزیابی + شناسه‌ی لاگ ثبت‌شده.
class _UndoEntry {
  const _UndoEntry({
    required this.previousCard,
    required this.reviewLogId,
    required this.atIndex,
    required this.rating,
  });

  final FlashCard previousCard;
  final int reviewLogId;
  final int atIndex;
  final Rating rating;
}

class ReviewController extends StateNotifier<ReviewState> {
  ReviewController(this._ref, this.deckId) : super(const ReviewState()) {
    // فعال‌سازی سرویس‌ها طبق تنظیمات فعلی.
    SoundService.instance.enabled = settings.soundEnabled;
    _load();
  }

  final Ref _ref;
  final int deckId;
  DateTime _cardShownAt = DateTime.now();
  final List<_UndoEntry> _undoStack = [];
  Timer? _focusTimer;

  bool get haptics => settings.hapticsEnabled;
  AppSettings get settings => _ref.read(settingsProvider);

  Future<void> _load() async {
    final cardRepo = _ref.read(cardRepositoryProvider);
    final now = DateTime.now();

    List<FlashCard> queue;
    if (deckId == kWeakCards) {
      // نشست نقاط ضعف: کارت‌های سخت در همه‌ی دک‌ها، فارغ از سررسید.
      final cards = await cardRepo.getAll();
      final logs = await _ref.read(reviewRepositoryProvider).getAll();
      queue = WeakCards.select(cards, logs);
    } else if (deckId == kDailyChallenge) {
      // چالش روزانه: کارت‌های قطعیِ امروز از همه‌ی دک‌ها، فارغ از سررسید.
      final cards = await cardRepo.getAll();
      queue = DailyChallenge.selectDailyCards(cards, now);
    } else {
      final all = deckId == kAllDecks
          ? await cardRepo.getAll()
          : await cardRepo.getByDeck(deckId);
      queue = all.where((c) => c.isDueAt(now)).toList()
        ..sort((a, b) => a.nextReview.compareTo(b.nextReview));
    }

    _cardShownAt = DateTime.now();
    state = state.copyWith(loading: false, cards: queue, index: 0);
  }

  void flip() {
    if (state.showAnswer) return;
    if (haptics) HapticFeedback.lightImpact();
    SoundService.instance.playFlip();
    state = state.copyWith(showAnswer: true);
  }

  /// در حالت تایپ: جواب کاربر را بررسی و نتیجه را نمایش می‌دهد (هنوز جلو نمی‌رود).
  void submitTyped(String answer) {
    final card = state.current;
    if (card == null || state.showAnswer) return;
    final correct = AnswerMatcher.matches(answer, card.back);
    if (correct) {
      if (haptics) HapticFeedback.lightImpact();
      SoundService.instance.playClick();
    } else {
      if (haptics) HapticFeedback.heavyImpact();
      SoundService.instance.playWrong();
    }
    state = state.copyWith(
      showAnswer: true,
      typedAnswer: answer.trim().isEmpty ? '—' : answer.trim(),
      typedCorrect: correct,
    );
  }

  /// در حالت تایپ پس از دیدن نتیجه: بر اساس درستیِ جواب امتیاز می‌دهد.
  Future<void> continueTyped() =>
      rate(state.typedCorrect ? Rating.good : Rating.hard);

  Future<void> rate(Rating rating) async {
    final card = state.current;
    if (card == null) return;

    if (haptics) HapticFeedback.mediumImpact();
    SoundService.instance.playClick();
    // کاربر امروز مرور کرد → استریک امروز امن است، هشدار را لغو کن.
    NotificationService.instance.cancelStreakReminder();

    final now = DateTime.now();
    final updated = Sm2.apply(card, rating.quality, now: now);
    final logId = await _ref
        .read(reviewRepositoryProvider)
        .recordReview(
          updatedCard: updated,
          log: ReviewLog(
            cardId: card.id!,
            deckId: card.deckId,
            quality: rating.quality,
            reviewedAt: now,
            durationMs: now.difference(_cardShownAt).inMilliseconds,
          ),
        );

    // ذخیره‌ی وضعیت پیش از ارزیابی برای امکان بازگشت.
    _undoStack.add(
      _UndoEntry(
        previousCard: card,
        reviewLogId: logId,
        atIndex: state.index,
        rating: rating,
      ),
    );

    var hard = state.hard, good = state.good, easy = state.easy;
    switch (rating) {
      case Rating.hard:
        hard++;
      case Rating.good:
        good++;
      case Rating.easy:
        easy++;
    }

    _cardShownAt = DateTime.now();
    state = state.copyWith(
      index: state.index + 1,
      showAnswer: false,
      hard: hard,
      good: good,
      easy: easy,
      canUndo: true,
      typedAnswer: '',
      typedCorrect: false,
    );

    // چالش روزانه: پاسخ به آخرین کارت = کامل‌شدن چالش → ثبت استریک.
    if (deckId == kDailyChallenge && state.index >= state.cards.length) {
      _markChallengeCompleted();
    }
  }

  /// ثبت کامل‌شدن چالش امروز در تنظیمات (استریک + روز آخر).
  /// یکنواخت است — ثبت دوباره در همان روز تغییری ایجاد نمی‌کند.
  Future<void> _markChallengeCompleted() async {
    final repo = _ref.read(settingsRepositoryProvider);
    final current = _ref.read(settingsProvider);
    await repo.save(DailyChallenge.markCompleted(current, DateTime.now()));
  }

  /// لغو آخرین ارزیابی: بازگرداندن کارت به وضعیت قبلی و حذف لاگ آن.
  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final entry = _undoStack.last;

    await _ref
        .read(reviewRepositoryProvider)
        .undoReview(
          previousCard: entry.previousCard,
          reviewLogId: entry.reviewLogId,
        );
    _undoStack.removeLast();

    var hard = state.hard, good = state.good, easy = state.easy;
    switch (entry.rating) {
      case Rating.hard:
        hard--;
      case Rating.good:
        good--;
      case Rating.easy:
        easy--;
    }

    _cardShownAt = DateTime.now();
    state = state.copyWith(
      index: entry.atIndex,
      showAnswer: true,
      hard: hard,
      good: good,
      easy: easy,
      canUndo: _undoStack.isNotEmpty,
      typedAnswer: '',
      typedCorrect: false,
    );
  }

  // ─── حالت تمرکز ───────────────────────────────────────────────────────────

  /// شروع حالت تمرکز با مدت زمان داده‌شده (دقیقه).
  void startFocus(int minutes) {
    if (state.finished) return;
    final totalSeconds = minutes * 60;
    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickFocus(),
    );
    state = state.copyWith(
      focusActive: true,
      focusRemainingSeconds: totalSeconds,
      focusTotalSeconds: totalSeconds,
    );
  }

  void _tickFocus() {
    if (!state.focusActive) return;
    final remaining = state.focusRemainingSeconds - 1;
    if (remaining <= 0) {
      // زمان تمام شد → نشست تمام می‌شود.
      _focusTimer?.cancel();
      _focusTimer = null;
      SoundService.instance.playSuccess();
      state = state.copyWith(
        focusActive: false,
        focusRemainingSeconds: 0,
        focusEnded: true,
      );
    } else {
      state = state.copyWith(focusRemainingSeconds: remaining);
    }
  }

  /// توقف زودهنگام حالت تمرکز — نشست ادامه می‌یابد بدون محدودیت زمانی.
  void stopFocus() {
    _focusTimer?.cancel();
    _focusTimer = null;
    state = state.copyWith(focusActive: false);
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }
}

final reviewControllerProvider = StateNotifierProvider.autoDispose
    .family<ReviewController, ReviewState, int>((ref, deckId) {
      return ReviewController(ref, deckId);
    });
