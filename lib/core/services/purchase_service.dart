/// سرویس خرید نسخه حرفه‌ای.
///
/// تا زمان اتصال به SDK رسمی فروشگاه، خرید عمداً غیرفعال است. هر اتصال
/// واقعی باید مالکیت محصول را در فروشگاه تأیید کند؛ مقدار محلی به‌تنهایی
/// نباید برای اعطای دسترسی حرفه‌ای استفاده شود.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// شناسه محصول پرو در کافه‌بازار.
  static const String premiumProductId = 'yadyar_premium';

  /// تا زمان پیاده‌سازی پرداخت تأییدشده، رابط خرید نباید فعال شود.
  static const bool isAvailable = false;

  /// راه‌اندازی جایگزین آینده برای اتصال به فروشگاه.
  Future<void> init() async {}

  /// خرید بدون یک فروشگاه تأییدشده هرگز نباید دسترسی حرفه‌ای اعطا کند.
  Future<bool> purchasePremium() async => false;

  /// بازیابی خرید نیز تا زمان اتصال به API رسمی غیرفعال است.
  Future<bool> restorePurchase() async => false;

  Future<void> dispose() async {}
}
