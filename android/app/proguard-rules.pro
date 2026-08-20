-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }

-keep class com.oxpay.o7lite.** { *; }
-dontwarn com.oxpay.o7lite.**

-keep class android.window.** { *; }
-dontwarn android.window.**

-keep class android.window.OnBackInvokedCallback
-dontwarn android.window.OnBackInvokedCallback

# Keep LogUtil class instead of just dontwarn
-keep class com.oxpay.o7lite.utils.LogUtil { *; }
-keep class com.oxpay.o7lite.utils.** { *; }
-keep class com.oxpay.o7lite.utils.sunmi_printer.BytesUtil { *; }
-keep class com.oxpay.o7lite.utils.sunmi_printer.SunmiPrintHelper { *; }
-keep class com.oxpay.o7lite.* { *; }
-keep class com.oxpay.o7lite.** { *; }
## Flutter wrapper
 -keep class io.flutter.app.** { *; }
 -keep class io.flutter.plugin.** { *; }
 -keep class io.flutter.util.** { *; }
 -keep class io.flutter.view.** { *; }
 -keep class io.flutter.** { *; }
 -keep class io.flutter.plugins.** { *; }
 -dontwarn io.flutter.embedding.**
 -ignorewarnings

-dontwarn afu.org.checkerframework.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn javax.lang.model.element.**
-dontwarn javax.naming.**
-dontwarn javax.servlet.**
-dontwarn org.apache.avalon.**
-dontwarn org.apache.log.**
-dontwarn org.apache.log4j.**
-dontwarn org.ietf.jgss.**

# Keep baseline profile related classes
-keep class com.android.tools.profgen.** { *; }
-keep class androidx.profileinstaller.** { *; }

# Add project specific ProGuard rules here.

# Keep React Native classes
-keep class com.facebook.react.** { *; }
-keep class com.facebook.hermes.** { *; }
-keep class com.facebook.jni.** { *; }

# Keep app specific classes
-keep class com.oxpay.o7lite.** { *; }

# Keep JavascriptInterface methods
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Preserve the special static methods that are required in all enumeration classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Prevent stripping of methods invoked on WebView
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# ============================================================================
# POS PRINTER SDK RULES
# These SDKs are loaded from local .jar/.aar files and MUST be kept intact
# in release builds. Without these rules, R8 obfuscates/strips SDK classes
# causing printer operations to fail silently on release APKs.
# ============================================================================

# Landi OmniDriver SDK (landi_omnidriver_sdk_0.0.1.aar)
-keep class com.sdksuite.omnidriver.** { *; }
-keepclassmembers class com.sdksuite.omnidriver.** { *; }
-dontwarn com.sdksuite.omnidriver.**

# Coherent / Centerm SmartPOS SDK (coherent_smartpos_sdk_3.1.5.jar)
-keep class com.centerm.smartpos.** { *; }
-keepclassmembers class com.centerm.smartpos.** { *; }
-dontwarn com.centerm.smartpos.**

# WizarPOS CloudPOS SDK (wizarpos_printer_sdk_1.7.5.1.aar)
-keep class com.cloudpos.** { *; }
-keepclassmembers class com.cloudpos.** { *; }
-dontwarn com.cloudpos.**

# Castle Printer SDK (castle_printer_sdk_0.0.3.jar)
-keep class com.castle.** { *; }
-keepclassmembers class com.castle.** { *; }
-dontwarn com.castle.**

# Sunmi Printer Plus (Flutter plugin - may have its own rules, but keep for safety)
-keep class com.sunmi.** { *; }
-keepclassmembers class com.sunmi.** { *; }
-dontwarn com.sunmi.**

# ============================================================================

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions
-keepattributes InnerClasses
