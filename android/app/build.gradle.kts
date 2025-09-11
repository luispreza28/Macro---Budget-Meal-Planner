plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Note: For production builds, create key.properties file with signing configuration
// See android/key.properties.template for the required format

android {
    namespace = "com.macrobudget.macro_budget_meal_planner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.macrobudget.macro_budget_meal_planner"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex for large apps
        multiDexEnabled = true
        
        // Performance optimizations
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    // Signing configs will be added when key.properties is created

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
        
        getByName("release") {
            // For now, use debug signing for development builds
            // In production, replace with proper release signing configuration
            signingConfig = signingConfigs.getByName("debug")
            
            // Disable obfuscation for now to avoid R8 issues
            // In production, enable with proper ProGuard rules
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Disable debugging and logging in release
            isDebuggable = false
        }
    }
}

flutter {
    source = "../.."
}
