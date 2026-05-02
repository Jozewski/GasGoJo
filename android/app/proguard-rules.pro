# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Crashlytics
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Google Maps
-keep class com.google.android.gms.maps.** { *; }

# Kotlin serialization
-keepattributes Signature
-keepattributes *Annotation*

# Hive
-keep class hive.** { *; }
-keep class ** extends hive.HiveObject { *; }
