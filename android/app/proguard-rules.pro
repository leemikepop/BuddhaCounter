# Flutter and general rules
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep R class and drawable resource identifiers
-keep class com.yichung.lee.buddha_counter.R$* { *; }
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep AudioService and Media session classes
-keep class com.ryanheise.audioservice.** { *; }
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }

# Keep MainActivity
-keep class com.yichung.lee.buddha_counter.MainActivity { *; }

# Suppress missing Play Core references from Flutter deferred components
-dontwarn com.google.android.play.core.**


