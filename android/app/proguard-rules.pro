# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# For Dio and related networking libraries
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# For Firebase
-keep class com.google.firebase.** { *; }

# For general model classes (if needed, adds safety for JSON serialization)
-keepclassmembers class ** {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Preserve line numbers for better crash reporting
-keepattributes SourceFile,LineNumberTable

# Ignore missing Play Core classes (referenced by Flutter engine but often not used)
-dontwarn com.google.android.play.core.**
