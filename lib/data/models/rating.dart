/// ارزیابی سه‌مرحله‌ای کاربر از یک کارت پس از دیدن جواب.
///
/// به کیفیت (quality) الگوریتم SM-2 نگاشت می‌شود:
/// سخت → ۳، خوب → ۴، آسون → ۵.
enum Rating {
  hard('سخت', 3),
  good('خوب', 4),
  easy('آسون', 5);

  const Rating(this.label, this.quality);

  final String label;
  final int quality;
}
