# Flutter and Dart specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift database rules
-keep class drift.** { *; }
-keep class moor.** { *; }
-keepclassmembers class * extends drift.** { *; }

# Riverpod rules
-keep class com.riverpod.** { *; }
-keep class flutter_riverpod.** { *; }

# In-app purchase rules
-keep class com.android.billingclient.api.** { *; }
-keep class io.flutter.plugins.inapppurchase.** { *; }

# JSON serialization rules
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.fasterxml.jackson.annotation.JsonProperty *;
    @com.fasterxml.jackson.annotation.JsonCreator *;
}

# Keep entity classes for Drift
-keep class **.g.dart { *; }
-keep class **$** { *; }

# General Android rules
-keep class androidx.** { *; }
-keep class com.google.android.material.** { *; }

# Prevent obfuscation of Flutter engine
-keep class io.flutter.embedding.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Optimize and remove unused code
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
-dontskipnonpubliclibraryclassmembers

# Keep line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Google Play Core library rules
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Play Store split compatibility
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
