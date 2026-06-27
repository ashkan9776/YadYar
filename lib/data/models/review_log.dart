/// رکورد یک مرور انجام‌شده — مبنای محاسبه آمار و استریک.
class ReviewLog {
  const ReviewLog({
    this.id,
    required this.cardId,
    required this.deckId,
    required this.quality,
    required this.reviewedAt,
    required this.durationMs,
  });

  final int? id;
  final int cardId;
  final int deckId;

  /// کیفیت SM-2: ۳ سخت، ۴ خوب، ۵ آسون.
  final int quality;
  final DateTime reviewedAt;
  final int durationMs;

  Map<String, Object?> toMap() => {
        'cardId': cardId,
        'deckId': deckId,
        'quality': quality,
        'reviewedAt': reviewedAt.millisecondsSinceEpoch,
        'durationMs': durationMs,
      };

  factory ReviewLog.fromMap(int id, Map<String, Object?> map) => ReviewLog(
        id: id,
        cardId: map['cardId'] as int,
        deckId: map['deckId'] as int,
        quality: map['quality'] as int,
        reviewedAt:
            DateTime.fromMillisecondsSinceEpoch(map['reviewedAt'] as int),
        durationMs: map['durationMs'] as int? ?? 0,
      );
}
