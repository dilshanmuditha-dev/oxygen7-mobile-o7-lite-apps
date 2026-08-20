package com.oxpay.o7lite

import android.os.Bundle
import android.os.SystemClock
import com.oxpay.o7lite.enums.MethodChannelType
import com.oxpay.o7lite.security.ActivityGuard
import com.oxpay.o7lite.security.LoginDeepLinkBridge
import com.oxpay.o7lite.utils.LogUtil
import com.oxpay.o7lite.utils.Utils
import com.oxpay.o7lite.utils.Utils.CHANNEL
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Mobile-specific MainActivityRefactored that does NOT depend on any POS SDK libraries.
 * 
 * This class is used for the "mobile" flavor build which targets standard Android
 * phones/tablets without POS hardware. It provides system method channels
 * (SHA, Android System) and printer stub channels that return "PRINTER_NOT_AVAILABLE"
 * error for any printer method calls.
 * 
 * Key differences from main source set MainActivityRefactored:
 * - NO POS SDK imports (OmniDriver, OmniConnection, LandiPrinterService)
 * - NO Landi OmniDriver initialization code
 * - NO actual POS printer functionality
 * - Printer channels return "PRINTER_NOT_AVAILABLE" error instead
 * - System channels (SHA, Android System) remain functional
 * 
 * This enables the mobile flavor APK to exclude POS SDK native libraries (.so files)
 * for Google Play Store 16KB page alignment compliance.
 * 
 * @see Requirements 3.1, 3.2, 3.3, 3.4, 6.3 from mobile-flavor-pos-exclusion spec
 */
class MainActivityRefactored : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivityRefactored"
    }

    private lateinit var activityGuard: ActivityGuard

    // Note: No Landi printer state tracking needed on mobile
    // - No isLandiInitAttempted
    // - No landiRetryCount
    // - No initLandiService()
    // - No unbindLandiService()

    override fun onCreate(savedInstanceState: Bundle?) {
        // Initialize ActivityGuard before calling super.onCreate()
        // This ensures intent validation happens before any UI is displayed
        activityGuard = ActivityGuard.create(applicationContext)
        
        // Validate the incoming intent
        val validationResult = activityGuard.validateIntent(intent, callingPackage)
        
        if (validationResult.isDenied()) {
            LogUtil.w(TAG, "Intent validation failed - finishing activity")
            // Finish the activity gracefully without displaying any UI
            // Use a generic result code that doesn't reveal security mechanisms
            setResult(RESULT_CANCELED)
            finish()
            return
        }
        
        super.onCreate(savedInstanceState)
        
        LogUtil.d(TAG, "Mobile MainActivityRefactored onCreate: Device Brand=${android.os.Build.BRAND}, Model=${android.os.Build.MODEL}")
        LogUtil.d(TAG, "Mobile flavor - POS printer functionality not available")
        
        // Note: No PrinterManager initialization on mobile
        // Note: No initLandiService() call on mobile
        LoginDeepLinkBridge.handleDeepLink(intent)
    }

    override fun onResume() {
        super.onResume()
        // Note: No printerManager.initialize() on mobile
        LogUtil.d(TAG, "Mobile MainActivityRefactored onResume")
    }

    override fun onNewIntent(intent: android.content.Intent) {
        // Validate new intents that arrive while activity is running
        val validationResult = activityGuard.validateIntent(intent, callingPackage)
        
        if (validationResult.isDenied()) {
            LogUtil.w(TAG, "New intent validation failed - ignoring intent")
            // Don't process the intent, but don't finish the activity
            // since it was already running with a valid intent
            return
        }
        
        super.onNewIntent(intent)
        setIntent(intent)
        LoginDeepLinkBridge.handleDeepLink(intent)
    }

    override fun onDestroy() {
        // Note: No unbindLandiService() on mobile
        // Note: No printerManager.cleanup() on mobile
        
        super.onDestroy()
        LogUtil.d(TAG, "Mobile MainActivityRefactored onDestroy")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        setupMethodChannels(flutterEngine)
        LoginDeepLinkBridge.configure(flutterEngine)
    }

    /**
     * Sets up all method channels for mobile flavor.
     * 
     * System channels included:
     * - SHA channel (CHANNEL) - for encryption operations
     * - Android System channel (CHANNEL_ANDROID_SYSTEM) - for system operations like uptime
     * 
     * Printer stub channels (return "PRINTER_NOT_AVAILABLE" error):
     * - CHANNEL_CASTLE
     * - CHANNEL_ANFU
     * - CHANNEL_SUNMI
     * - CHANNEL_LANDI
     * - CHANNEL_WIZAR_POS
     * 
     * @param flutterEngine The Flutter engine to configure channels on
     */
    private fun setupMethodChannels(flutterEngine: FlutterEngine) {
        // System channels - these remain functional on mobile
        val channelSHA = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        val androidSystem = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, 
            Utils.CHANNEL_ANDROID_SYSTEM
        )

        // Set up system channels
        setupSystemChannel(androidSystem)
        setupSHAChannel(channelSHA)
        
        // Set up printer stub channels that return "PRINTER_NOT_AVAILABLE" error
        setupPrinterStubChannels(flutterEngine)
        
        LogUtil.d(TAG, "Mobile method channels configured (system + printer stubs)")
    }

    /**
     * Sets up the Android System method channel.
     * Handles system-level operations like getting device uptime.
     * 
     * @param channel The MethodChannel for Android System operations
     */
    private fun setupSystemChannel(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                MethodChannelType.GET_UPTIME.value -> {
                    val uptime = SystemClock.elapsedRealtime()
                    result.success(uptime)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Sets up the SHA encryption method channel.
     * Handles HMAC-SHA512 encryption operations.
     * 
     * @param channel The MethodChannel for SHA operations
     */
    private fun setupSHAChannel(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            if (call.method == MethodChannelType.ENCRYPTION_SHA512.value) {
                val encryptString = call.argument<String>("encryptString")
                val key = call.argument<String>("key")
                
                if (encryptString != null && key != null) {
                    result.success(Utils.encryptionHmacSHA512(encryptString, key))
                } else {
                    result.error(
                        "INVALID_ARGUMENTS",
                        "encryptString and key are required",
                        null
                    )
                }
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * Sets up printer stub channels for mobile flavor.
     * 
     * All printer channels are registered but return "PRINTER_NOT_AVAILABLE" error
     * for any method call. This ensures Flutter code that calls printer methods
     * receives a consistent error response rather than a channel not found error.
     * 
     * Registered channels:
     * - CHANNEL_CASTLE - Castle POS printer
     * - CHANNEL_ANFU - ANFU POS printer
     * - CHANNEL_SUNMI - Sunmi POS printer
     * - CHANNEL_LANDI - Landi POS printer
     * - CHANNEL_WIZAR_POS - WizarPOS printer
     * 
     * @param flutterEngine The Flutter engine to configure channels on
     * @see Requirements 3.4, 6.3 from mobile-flavor-pos-exclusion spec
     */
    private fun setupPrinterStubChannels(flutterEngine: FlutterEngine) {
        // List of all printer channel names
        val printerChannels = listOf(
            Utils.CHANNEL_CASTLE,
            Utils.CHANNEL_ANFU,
            Utils.CHANNEL_SUNMI,
            Utils.CHANNEL_LANDI,
            Utils.CHANNEL_WIZAR_POS,
            Utils.CHANNEL_COHERENT,
            Utils.CHANNEL_MOREFUN
        )
        
        // Register each printer channel with a stub handler
        printerChannels.forEach { channelName ->
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                channelName
            )
            
            channel.setMethodCallHandler { call, result ->
                // Log the printer method attempt for debugging
                LogUtil.w(
                    TAG, 
                    "Printer method called on mobile flavor - channel: $channelName, method: ${call.method}"
                )
                
                // Return "PRINTER_NOT_AVAILABLE" error for all printer method calls
                result.error(
                    "PRINTER_NOT_AVAILABLE",
                    "Printer functionality is not available on mobile devices",
                    null
                )
            }
        }
        
        LogUtil.d(TAG, "Printer stub channels registered: ${printerChannels.size} channels")
    }
}
