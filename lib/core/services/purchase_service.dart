import 'package:flutter/services.dart';

/// سرویس خرید نسخه حرفه‌ای از کافه‌بازار (Poolakey).
///
/// پل نیتیو در `android/app/.../billing/PoolakeyBridge.kt` قرار دارد و همان
/// API کتابخانه‌ی رسمی flutter_poolakey را از طریق MethodChannel فراهم می‌کند
/// (پلاگین pub به‌خاطر jcenter در build.gradle با AGP 9 ناسازگار است).
///
/// تا زمان جایگزینی [rsaPublicKey] با کلید واقعی از پنل پیشخان بازار،
/// پرداخت غیرفعال می‌ماند تا دسترسی حرفه‌ای بدون خرید واقعی اعطا نشود.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const MethodChannel _channel =
      MethodChannel('com.ahoura.yadyar/poolakey');

  static const String _rsaPlaceholder = 'YOUR_RSA_PUBLIC_KEY';

  /// کلید RSA پرداخت درون‌برنامه‌ای از پنل پیشخان بازار (صفحه اطلاعات
  /// برنامه، تب «پرداخت درون‌برنامه‌ای»). کلیدی عمومی است و طبق مستندات
  /// بازار باید داخل برنامه قرار بگیرد.
  static const String rsaPublicKey =
      'MIHNMA0GCSqGSIb3DQEBAQUAA4G7ADCBtwKBrwCtF0vF0GYNQA3i+wPeUQPkgxW+gjQ/2TzgnXvKvOaMILpVhAXX3/BaCOzs4v8FohE5n0d08ilIGPY1/qorXtGYjI50TLkq8HMNWoAA4tu9fed35Jur67WG9djVUnaxRJlD2g24kt5W15SsEhle0aklo/NDSS2Ue6Ya9Yiqm7vgh/fqVYVs/Ja2aFZykTlwgqGCrfTbXPyMBXnIxuZ98soD8mToOIaaaAuVjLsYZIkCAwEAAQ==';

  /// شناسه محصول پرو در کافه‌بازار.
  static const String premiumProductId = 'yadyar_premium';

  /// آیا کلید واقعی تنظیم شده و پرداخت واقعی فعال است؟
  static bool get isBillingConfigured =>
      rsaPublicKey != _rsaPlaceholder && rsaPublicKey.isNotEmpty;

  /// پرداخت فقط پس از تنظیم کلید واقعی فعال می‌شود.
  static bool get isAvailable => isBillingConfigured;

  bool _connected = false;

  /// اتصال به سرویس پرداخت بازار. اگر بازار نصب نباشد بی‌صدا رد می‌شود.
  Future<void> init() async {
    if (!isBillingConfigured || _connected) return;
    try {
      await _channel
          .invokeMethod('connect', {'in_app_billing_key': rsaPublicKey});
      _connected = true;
    } on PlatformException {
      _connected = false; // بازار نصب نیست یا در دسترس نیست
    } on MissingPluginException {
      _connected = false; // پلتفرم اندروید نیست (تست دسکتاپ)
    }
  }

  /// شروع جریان خرید محصول پرو. جریان بازار باز می‌شود و نتیجه برمی‌گردد.
  /// لغو توسط کاربر و خطاهای بازار هر دو false برمی‌گردانند.
  Future<bool> purchasePremium() async {
    if (!isBillingConfigured) return false;
    await init();
    if (!_connected) return false;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'purchase',
        {
          'product_id': premiumProductId,
          'payload': 'yadyar-premium',
          // توکن تخفیف پویا (JWT امضاشده سمت سرور) — در صورت پیاده‌سازی آینده.
          'dynamicPriceToken': null,
        },
      );
      return result?['productId'] == premiumProductId;
    } on PlatformException {
      return false; // شامل PURCHASE_CANCELLED و خطاهای بازار
    }
  }

  /// بازیابی خرید قبلی (مثلاً بعد از نصب مجدد) از سابقه‌ی بازار.
  Future<bool> restorePurchase() async {
    if (!isBillingConfigured) return false;
    await init();
    if (!_connected) return false;
    try {
      final list = await _channel
          .invokeMethod<List<dynamic>>('get_all_purchased_products');
      return list?.any((p) => p['productId'] == premiumProductId) ?? false;
    } on PlatformException {
      return false; // مثلاً ورود نبودن کاربر به حساب بازار
    }
  }

  Future<void> dispose() async {
    if (!_connected) return;
    _connected = false;
    try {
      await _channel.invokeMethod('disconnect');
    } catch (_) {
      // بی‌اهمیت — اتصال در حال بسته‌شدن است.
    }
  }
}
