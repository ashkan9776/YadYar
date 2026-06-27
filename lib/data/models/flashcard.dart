/// یک فلش‌کارت. مطابق جدول FlashCard در PRD به‌علاوه فیلدهای کمکی SM-2.
class FlashCard {
  const FlashCard({
    this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.nextReview,
    this.interval = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.lastReviewed,
  });

  final int? id;
  final int deckId;
  final String front; // سوال (روی کارت)
  final String back; // جواب (پشت کارت)
  final DateTime nextReview; // زمان مرور بعدی
  final int interval; // فاصله فعلی (روز)
  final double easeFactor; // ضریب سهولت SM-2
  final int repetitions; // تعداد مرورهای موفق پیاپی
  final DateTime? lastReviewed;

  /// آیا کارت تا پایان امروز سررسید مرور دارد؟
  bool isDueAt(DateTime now) {
    final endOfToday = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    return nextReview.isBefore(endOfToday);
  }

  /// کارت جدیدی که هنوز مرور نشده است.
  bool get isNew => repetitions == 0 && lastReviewed == null;

  FlashCard copyWith({
    int? id,
    int? deckId,
    String? front,
    String? back,
    DateTime? nextReview,
    int? interval,
    double? easeFactor,
    int? repetitions,
    DateTime? lastReviewed,
  }) {
    return FlashCard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      nextReview: nextReview ?? this.nextReview,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }

  Map<String, Object?> toMap() => {
        'deckId': deckId,
        'front': front,
        'back': back,
        'nextReview': nextReview.millisecondsSinceEpoch,
        'interval': interval,
        'easeFactor': easeFactor,
        'repetitions': repetitions,
        'lastReviewed': lastReviewed?.millisecondsSinceEpoch,
      };

  factory FlashCard.fromMap(int id, Map<String, Object?> map) => FlashCard(
        id: id,
        deckId: map['deckId'] as int,
        front: map['front'] as String,
        back: map['back'] as String,
        nextReview:
            DateTime.fromMillisecondsSinceEpoch(map['nextReview'] as int),
        interval: map['interval'] as int? ?? 0,
        easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
        repetitions: map['repetitions'] as int? ?? 0,
        lastReviewed: map['lastReviewed'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['lastReviewed'] as int),
      );
}
