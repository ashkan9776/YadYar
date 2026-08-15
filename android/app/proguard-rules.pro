# قوانین R8/ProGuard برای بیلد release کوچک‌سازی‌شده‌ی یادیار.

# نگه‌داشتن کلاس‌های flutter_local_notifications (از GSON/Reflection استفاده می‌کند).
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod

# جلوگیری از حذف کلاس‌های مدلِ موردنیاز GSON.
-keep class com.google.gson.** { *; }

# نگه‌داشتن کلاس‌های ویجت صفحه‌ی خانه (با نام صریح ارجاع داده می‌شوند).
-keep class com.ahoura.yadyar.YadyarWidgetProvider { *; }
-keep class es.antonborri.home_widget.** { *; }

# نگه‌داشتن کلاس‌های WorkManager (home_widget برای بک‌گراند از آن استفاده می‌کند).
-keep class androidx.work.** { *; }
-keep class androidx.datastore.** { *; }
-dontwarn androidx.work.**

# هشدارهای بی‌اهمیتِ کلاس‌های اختیاری را نادیده بگیر.
-dontwarn com.google.errorprone.annotations.**

# SDK پرداخت کافه‌بازار (Poolakey) — از Rx و annotation استفاده می‌کند؛
# کوچک‌سازی رادیکال می‌تواند callback های DSL را بشکند.
-keep class ir.cafebazaar.poolakey.** { *; }
-dontwarn ir.cafebazaar.poolakey.**
# پل پرداخت یادیار (PaymentActivity از طریق manifest و companion ارجاع می‌شود).
-keep class com.ahoura.yadyar.billing.** { *; }
