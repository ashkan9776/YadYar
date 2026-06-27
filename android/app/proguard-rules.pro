# قوانین R8/ProGuard برای بیلد release کوچک‌سازی‌شده‌ی یادیار.

# نگه‌داشتن کلاس‌های flutter_local_notifications (از GSON/Reflection استفاده می‌کند).
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod

# جلوگیری از حذف کلاس‌های مدلِ موردنیاز GSON.
-keep class com.google.gson.** { *; }

# هشدارهای بی‌اهمیتِ کلاس‌های اختیاری را نادیده بگیر.
-dontwarn com.google.errorprone.annotations.**
