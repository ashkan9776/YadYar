import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()

if (hasReleaseSigning) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // انتشار با کلید release در صورت وجود، وگرنه با کلید debug.
            signingConfig = if (hasReleaseSigning) {
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

    // SDK رسمی پرداخت درون‌برنامه‌ای کافه‌بازار — AAR محلی.
    // دلیل: jitpack در این شبکه قابل دسترس نیست و مخزن جایگزین گوگل خطای 403
    // می‌دهد؛ به‌علاوه پلاگین pub آن (flutter_poolakey) به‌خاطر jcenter با
    // AGP 9 ناسازگار است. پل فلاتر در billing/PoolakeyBridge.kt است.
    implementation(files("libs/poolakey-2.2.0.aar"))
    // تنها وابستگی ترانزیتیو پولکی (androidx.fragment) + ComponentActivity
    // برای PaymentActivity — نسخه‌های موجود در کش گریدل (شبکه به مخازن
    // گوگل دسترسی ندارد و دانلود مجدد ممکن نیست).
    implementation("androidx.fragment:fragment:1.8.9")
    implementation("androidx.activity:activity:1.9.0")
}
