plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ppb2026.umkmap"
    // Build-time only: must be >= the highest compileSdk required by resolved
    // AndroidX deps (currently 36). Runtime target compatibility stays at 34;
    // Flutter 3.41 currently resolves flutter.minSdkVersion to 24.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.ppb2026.umkmap"
        // minSdk 24 (Android 7.0), per revised NFR-06. Android 6.0 (API 23) was
        // dropped because image_picker_android and shared_preferences_android
        // both hard-require minSdk 24. flutter.minSdkVersion resolves to 24.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
