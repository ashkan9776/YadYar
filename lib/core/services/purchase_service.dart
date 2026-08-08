/// سرویس خرید نسخه حرفه‌ای.
///
/// فعلاً Mock است (بدون SDK واقعی). وقتی آماده انتشار در کافه‌بازار بودید:
/// 1. وابستگی cafebazaar_flutter یا poolakey را اضافه کنید.
/// 2. متدهای این کلاس را با API واقعی جایگزین کنید.
///
///PUBLIC_KEY باید از پنل توسعه‌دهنده کافه‌بازار دریافت شود.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// شناسه محصول پرو در کافه‌بازار.
  static const String premiumProductId = 'yadyar_premium';

  bool _initialized = false;

  /// آیا سرویس آماده است؟
  bool get isReady => _initialized;

  /// راه‌اندازی سرویس خرید.
  /// در نسخه واقعی: اتصال به کافه‌بازار.
  Future<void> init() async {
    _initialized = true;
  }

  /// بررسی آیا کاربر نسخه پرو را خریداری کرده.
  /// [localIsPro]: مقدار ذخیره‌شده در دیتابیس محلی.
  ///
  /// در نسخه واقعی: getPurchasedProducts() کافه‌بازار را چک می‌کند.
  Future<bool> checkPurchaseStatus({bool localIsPro = false}) async {
    return localIsPro;
  }

  /// خرید نسخه حرفه‌ای.
  ///
  /// در نسخه واقعی: خرید از طریق کافه‌بازار انجام می‌شود.
  /// فعلاً همیشه true برمی‌گرداند (شبیه‌سازی خرید موفق).
  Future<bool> purchasePremium() async {
    // TODO: جایگزین با API واقعی کافه‌بازار
    // final result = await InAppPurchase.purchase(premiumProductId);
    // return result != null;
    return true; // Mock: شبیه‌سازی خرید موفق
  }

  /// بازیابی خرید قبلی.
  ///
  /// در نسخه واقعی: getPurchasedProducts() کافه‌بازار.
  Future<bool> restorePurchase() async {
    // TODO: جایگزین با API واقعی کافه‌بازار
    // final purchased = await InAppPurchase.getPurchasedProducts();
    // return purchased.any((p) => p.productId == premiumProductId);
    return false; // Mock: خریدی برای بازیابی نیست
  }

  /// قطع اتصال.
  Future<void> dispose() async {
    _initialized = false;
  }
}
