# Keep LogUtil class and methods
-keep class com.oxpay.o7lite.* { *; }
-dontwarn com.oxpay.o7lite.*

# Keep MainActivity and related classes
-keep class com.oxpay.o7lite.MainActivity { *; }

# Keep classes referenced in the MainActivity
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
} 