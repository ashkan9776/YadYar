import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// خواندن اطلاعات کلید امضای ریلیز از android/key.properties.
// این فایل در گیت نادیده گرفته می‌شود (نباید commit شود).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ahoura.yadyar"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // لازم برای flutter_local_notifications (desugaring کتابخانه‌های Java 8+)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ahoura.yadyar"
        // flutter_local_notifications نسخه ۲۲ به minSdk ۲۴ یا بالاتر نیاز دارد.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // تنظیمات امضای ریلیز — فقط وقتی key.properties موجود باشد فعال می‌شود.
        // مسیر storeFile نسبت به پوشه‌ی ماژول app حل می‌شود (android/app/).
        if (keystoreProperties.isNotEmpty()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // امضا با کلید ریلیز واقعی (اگر موجود باشد)؛ وگرنه fallback به debug.
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // کوچک‌سازی کد (R8) و حذف منابع بلااستفاده برای کم‌کردن حجم APK.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
