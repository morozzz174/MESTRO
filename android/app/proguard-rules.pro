# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (Deferred Components)
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# SQLite / sqflite
-keep class org.sqlite.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# JSON / Models
-keep class com.mestro.metro_2.models.** { *; }
-keep class com.mestro.metro_2.features.floor_plan.models.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# TFLite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# HTTP / YooKassa
-keep class com.mestro.metro_2.services.PaymentService { *; }
-keep class com.mestro.metro_2.services.PaymentResult { *; }
-keep class com.mestro.metro_2.services.PricingPlan { *; }

# UUID
-keep class com.khrykin.uuid.** { *; }

# Speech to Text
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Image Picker
-keep class com.baseflow.imagepicker.** { *; }
-dontwarn com.baseflow.imagepicker.**

# PDF / Printing
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# Excel
-keep class com.martino2k.** { *; }
-dontwarn com.martino2k.**

# General
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile
-keepattributes LineNumberTable

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
