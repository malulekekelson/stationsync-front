# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# For Dio and networking
-keep class com.android.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# For image_picker and file_picker
-keep class androidx.exifinterface.** { *; }
-keep class androidx.core.** { *; }

# For geolocator
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# For Flutter Secure Storage
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**
-keep class androidx.security.** { *; }

# Keep our models
-keep class com.stationsync.stationsync.** { *; }