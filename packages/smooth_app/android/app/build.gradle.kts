import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinVersion

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.fromTarget("17")
    }
}

android {
    namespace = "org.openfoodfacts.app"
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.intelisenselabs.halalpal"
        // In debug builds, bump minSdk to at least 24 (Android 7.0+) unless explicitly overridden.
        // This avoids legacy MultiDex dexing passes and heavy Java desugaring transformations,
        // drastically speeding up incremental and cold debug builds.
        // Release builds retain flutter.minSdkVersion (API 21) for full backwards compatibility.
        val isDebugTask = gradle.startParameter.taskNames.any { it.contains("Debug", ignoreCase = true) }
        val minSdkOverride = project.findProperty("minSdk")?.toString()?.toIntOrNull()
        minSdk = minSdkOverride ?: if (isDebugTask) maxOf(flutter.minSdkVersion, 24) else flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Fixed debug key so every CI build installs over the previous one.
        // Debug use only: this key is public and must never sign a release.
        getByName("debug") {
            storeFile = file("halalpal-debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        create("release") {
            storeFile = System.getenv("SIGN_STORE_PATH")?.let { file(it) }
            storePassword = System.getenv("SIGN_STORE_PASSWORD")
            keyAlias = System.getenv("SIGN_KEY_ALIAS")
            keyPassword = System.getenv("SIGN_KEY_PASSWORD")
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // R8 shrinking can strip camera and barcode-scanner classes in
            // release builds only. Off while the scanner is being fixed.
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (System.getenv("SIGN_STORE_PATH") != null) {
                signingConfigs.getByName("release")
            } else {
                // Personal sideload builds only (CI "release APK" artifact):
                // reuse the fixed debug key so it installs over the debug
                // build. Never publish an APK signed this way.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
