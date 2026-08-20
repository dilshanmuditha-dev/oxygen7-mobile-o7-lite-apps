package com.oxpay.o7lite

import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Bundle
import android.os.RemoteException
import android.os.SystemClock
import android.widget.Toast
import com.oxpay.o7lite.constants.PrinterConstants
import com.oxpay.o7lite.entity.DataEntity
import com.oxpay.o7lite.entity.HeaderEntity
import com.oxpay.o7lite.entity.SummaryReportRequest
import com.oxpay.o7lite.entity.SummaryReportResponse
import com.oxpay.o7lite.enums.MethodChannelType
import com.oxpay.o7lite.factory.PrinterServiceFactory
import com.oxpay.o7lite.managers.PrinterManager
import com.oxpay.o7lite.security.ActivityGuard
import com.oxpay.o7lite.security.LoginDeepLinkBridge
import com.oxpay.o7lite.services.ApiService
import com.oxpay.o7lite.utils.LogUtil
import com.oxpay.o7lite.utils.PrintUtilRefactored
import com.oxpay.o7lite.utils.Utils
import com.oxpay.o7lite.utils.Utils.API_URL
import com.oxpay.o7lite.utils.Utils.CHANNEL
import com.oxpay.o7lite.utils.landi.LandiPrinterService
import com.sdksuite.omnidriver.OmniConnection
import com.sdksuite.omnidriver.OmniDriver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import okhttp3.OkHttpClient
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

class MainActivityRefactored : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivityRefactored"
        private const val MAX_LANDI_RETRY = 3
        private const val CHANNEL_CASTLE_REPORT_PRINT_MONITOR = "CASTLE_REPORT_PRINT_MONITOR"
        private const val METHOD_CASTLE_REPORT_PRINT_MONITOR_EVENT = "onCastleReportPrintMonitorEvent"
        private const val WIZARPOS_CARD_PAYMENT_PACKAGE = "com.wizarpos.oxpay"
    }

    private lateinit var printerManager: PrinterManager
    private lateinit var activityGuard: ActivityGuard
    private var castleReportPrintMonitorChannel: MethodChannel? = null

    // Landi printer state tracking (Requirement 2.1)
    // Note: initLandiService() is called in onCreate() but we don't block on it.
    // LandiPrinterService gets printer directly via MainApplication.getOmniDriver().getPrinter()
    @Volatile private var isLandiInitAttempted: Boolean = false
    private var landiRetryCount: Int = 0

    /**
     * Initialize OmniDriver for Landi devices.
     * Called early in onCreate() to ensure driver is ready before print requests.
     * 
     * Note: This follows the original MainActivity.kt pattern.
     * The callback may or may not fire, but LandiPrinterService works regardless
     * because it gets printer directly via MainApplication.getOmniDriver().getPrinter()
     * 
     * Requirements: 1.1, 1.2, 1.3, 2.2, 2.3
     */
    private fun initLandiService() {
        // Requirement 1.2: Check if device is Landi before attempting initialization
        if (!Utils.isLANDI()) return

        isLandiInitAttempted = true
        LogUtil.d(TAG, "initLandiService: Starting OmniDriver initialization...")

        MainApplication.getOmniDriver().init(object : OmniConnection {
            override fun onConnected() {
                landiRetryCount = 0
                LogUtil.d(TAG, "initOmniDriver--->onSuccess")
            }

            override fun onDisconnected(error: Int) {
                LogUtil.e(TAG, "initOmniDriver--->onError: error=$error")

                if (error == OmniDriver.ERROR_BIND_FAIL) {
                    LogUtil.e(TAG, "Please confirm whether OmniDriver service is installed")
                    return
                }

                // Requirement 1.3: Retry initialization up to MAX_LANDI_RETRY times
                if (landiRetryCount < MAX_LANDI_RETRY) {
                    landiRetryCount++
                    initLandiService()
                }
            }
        })
    }

    /**
     * Cleanup OmniDriver resources.
     * Called in onDestroy() to properly release Landi printer resources.
     * 
     * Requirements: 4.1, 4.2, 4.3
     */
    private fun unbindLandiService() {
        // Requirement 4.2: Only attempt cleanup if Landi init was attempted
        if (!isLandiInitAttempted) return
        
        // Requirement 4.1: Call OmniDriver.destroy() to release resources
        MainApplication.getOmniDriver().destroy()
        
        // Requirement 4.3: Reset initialization flag after cleanup
        isLandiInitAttempted = false
        LogUtil.d(TAG, "Landi service unbound successfully")
    }

    // Helper function to show Toast on UI thread
    private fun showDebugToast(message: String) {
//        runOnUiThread {
//            Toast.makeText(this, message, Toast.LENGTH_LONG).show()
//        }
        LogUtil.d(TAG, "TOAST: $message")
    }

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
        
        showDebugToast("onCreate: Device Brand=${android.os.Build.BRAND}, Model=${android.os.Build.MODEL}")
        
        printerManager = PrinterManager(this)
        showDebugToast("PrinterManager created")
        
        // Requirement 1.1: Initialize OmniDriver early for Landi devices
        showDebugToast("Calling initLandiService()...")
        initLandiService()
        showDebugToast("initLandiService() called")

        LoginDeepLinkBridge.handleDeepLink(intent)
    }

    override fun onResume() {
        super.onResume()
        printerManager.initialize()
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
        // Requirement 4.1: Cleanup Landi resources before activity destruction
        unbindLandiService()
        
        super.onDestroy()
        printerManager.cleanup()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        setupMethodChannels(flutterEngine)
        LoginDeepLinkBridge.configure(flutterEngine)
    }

    private fun setupMethodChannels(flutterEngine: FlutterEngine) {
        val channelSHA = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        val androidSystem =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Utils.CHANNEL_ANDROID_SYSTEM)

        val channelCASTLE =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Utils.CHANNEL_CASTLE)
        val channelANFU =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Utils.CHANNEL_ANFU)
        val channelSUNMI =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Utils.CHANNEL_SUNMI)
        val channelLANDI =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Utils.CHANNEL_LANDI)
        val channelWizarPos =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Utils.CHANNEL_WIZAR_POS)
        val channelCoherent =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Utils.CHANNEL_COHERENT)
        val channelMorefun =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Utils.CHANNEL_MOREFUN)
        castleReportPrintMonitorChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CASTLE_REPORT_PRINT_MONITOR)

        setupSystemChannel(androidSystem)
        setupSHAChannel(channelSHA)
        setupPrinterChannels(
            channelCASTLE,
            channelANFU,
            channelSUNMI,
            channelLANDI,
            channelWizarPos,
            channelCoherent,
            channelMorefun
        )
    }

    private fun setupSystemChannel(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                MethodChannelType.GET_UPTIME.value -> {
                    val uptime = SystemClock.elapsedRealtime()
                    result.success(uptime)
                }

                MethodChannelType.OPEN_WIZARPOS_CARD_PAYMENT_APP.value -> {
                    result.success(openWizarPosCardPaymentApp())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun openWizarPosCardPaymentApp(): Boolean {
        val launchIntent = packageManager.getLaunchIntentForPackage(
            WIZARPOS_CARD_PAYMENT_PACKAGE
        ) ?: run {
            LogUtil.w(TAG, "WizarPOS Card Payment launcher activity not found")
            return false
        }

        launchIntent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        )

        return try {
            startActivity(launchIntent)
            true
        } catch (error: Exception) {
            LogUtil.e(
                TAG,
                "Unable to open WizarPOS Card Payment app: ${error.javaClass.simpleName}"
            )
            false
        }
    }

    private fun setupSHAChannel(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            if (call.method == MethodChannelType.ENCRYPTION_SHA512.value) {
                val encryptString = call.argument<String>("encryptString")
                val key = call.argument<String>("key")
                result.success(Utils.encryptionHmacSHA512(encryptString!!, key!!))
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setupPrinterChannels(
        channelCastle: MethodChannel,
        channelAnFu: MethodChannel,
        channelSunmi: MethodChannel,
        channelLandi: MethodChannel,
        channelWizarPos: MethodChannel,
        channelCoherent: MethodChannel,
        channelMorefun: MethodChannel
    ) {
        // Castle printer channel
        channelCastle.setMethodCallHandler { call, result ->
            LogUtil.d(TAG, "=== CASTLE CHANNEL RECEIVED ===")
            LogUtil.d(TAG, "Method called: ${call.method}")
            LogUtil.d(TAG, "Expected PRINT_RECEIPT_MANUAL: ${MethodChannelType.PRINT_RECEIPT_MANUAL.value}")
            if (call.method == MethodChannelType.PRINT_SUMMARY_REPORT.value) {
                emitCastleReportPrintMonitorEvent(
                    "Native",
                    "Castle channel received method=${call.method}"
                )
            }
            showDebugToast("Castle method: ${call.method}")
            handlePrinterMethod(call.method, call, result)
        }

        // ANFU printer channel
        channelAnFu.setMethodCallHandler { call, result ->
            when (call.method) {
                MethodChannelType.PRINT_ANFU_RECEIPT_MANUAL.value -> {
                    handleReceiptPrinting(call, result)
                }

                MethodChannelType.PRINT_ANFU_SUMMARY.value -> {
                    handleSummaryPrinting(call, result)
                }

                else -> result.notImplemented()
            }
        }

        // Sunmi printer channel
        channelSunmi.setMethodCallHandler { call, result ->
            when (call.method) {
                MethodChannelType.PRINT_SUNMI_SUMMARY.value -> {
                    handleSummaryPrinting(call, result)
                }

                else -> result.notImplemented()
            }
        }

        // Landi printer channel - uses Landi-specific handlers (Requirement 3.1)
        channelLandi.setMethodCallHandler { call, result ->
            showDebugToast("LANDI CHANNEL: method=${call.method}")
            LogUtil.d(TAG, "LANDI_SUMMARY: === LANDI CHANNEL RECEIVED === method=${call.method}")
            when (call.method) {
                MethodChannelType.PRINT_LANDI_RECEIPT_MANUAL.value -> {
                    showDebugToast("LANDI: Calling handleLandiReceiptPrinting")
                    handleLandiReceiptPrinting(call, result)
                }

                MethodChannelType.PRINT_LANDI_SUMMARY.value -> {
                    showDebugToast("LANDI: Calling handleLandiSummaryPrinting")
                    LogUtil.d(TAG, "LANDI_SUMMARY: Matched PRINT_LANDI_SUMMARY, calling handleLandiSummaryPrinting()")
                    handleLandiSummaryPrinting(call, result)
                }

                "getPrinterState" -> {
                    LogUtil.d(TAG, "LANDI: Getting printer state via OmniDriver")
                    try {
                        val printer = MainApplication.getOmniDriver().getPrinter(android.os.Bundle())
                        if (printer != null) {
                            val state = printer.getStatus()
                            LogUtil.d(TAG, "LANDI: Printer state = $state")
                            result.success(state)
                        } else {
                            LogUtil.d(TAG, "LANDI: Printer is null, returning -1")
                            result.success(-1)
                        }
                    } catch (e: Exception) {
                        LogUtil.e(TAG, "LANDI: getPrinterState error: ${e.message}")
                        result.success(-1)
                    }
                }

                else -> {
                    showDebugToast("LANDI: Unknown method ${call.method}")
                    LogUtil.e(TAG, "LANDI_SUMMARY: Unknown method ${call.method}")
                    result.notImplemented()
                }
            }
        }

        // WizarPos printer channel
        channelWizarPos.setMethodCallHandler { call, result ->
            when (call.method) {
                MethodChannelType.PRINT_WIZAR_POS_RECEIPT_MANUAL.value -> {
                    handleReceiptPrinting(call, result)
                }

                MethodChannelType.PRINT_WIZAR_POS_SUMMARY.value -> {
                    handleSummaryPrinting(call, result)
                }

                else -> result.notImplemented()
            }
        }

        // Coherent printer channel
        channelCoherent.setMethodCallHandler { call, result ->
            try {
                LogUtil.d(TAG, "COHERENT::: Channel received: ${call.method}")
                when (call.method) {
                    MethodChannelType.PRINT_COHERENT_RECEIPT_MANUAL.value -> {
                        LogUtil.d(TAG, "COHERENT::: Handling receipt printing")
                        handleReceiptPrinting(call, result)
                    }

                    MethodChannelType.PRINT_COHERENT_SUMMARY.value -> {
                        LogUtil.d(TAG, "COHERENT::: Handling summary printing")
                        handleSummaryPrinting(call, result)
                    }

                    "getPrinterState" -> {
                        LogUtil.d(TAG, "COHERENT::: Getting printer state")
                        val coherentService = PrinterServiceFactory.getCurrentPrinterService()
                        if (coherentService is com.oxpay.o7lite.services.printers.CoherentPrinterService) {
                            val state = coherentService.getPrinterState()
                            LogUtil.d(TAG, "COHERENT::: Printer state = $state")
                            result.success(state)
                        } else {
                            // Service not initialized yet, return -1 (not connected)
                            LogUtil.d(TAG, "COHERENT::: Service not available, returning -1")
                            result.success(-1)
                        }
                    }

                    else -> {
                        LogUtil.d(TAG, "COHERENT::: Unknown method: ${call.method}")
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                LogUtil.e(TAG, "COHERENT::: Error: ${e.message}")
                result.error("COHERENT_ERROR", e.message, e.stackTraceToString())
            }
        }

        // Morefun (MF) printer channel
        channelMorefun.setMethodCallHandler { call, result ->
            try {
                LogUtil.d(TAG, "MOREFUN::: Channel received: ${call.method}")
                when (call.method) {
                    MethodChannelType.PRINT_MOREFUN_RECEIPT_MANUAL.value -> {
                        LogUtil.d(TAG, "MOREFUN::: Handling receipt printing (pre-rendered bitmap)")
                        handleMorefunBitmapPrinting(call, result)
                    }

                    MethodChannelType.PRINT_MOREFUN_SUMMARY.value -> {
                        LogUtil.d(TAG, "MOREFUN::: Handling summary printing")
                        handleSummaryPrinting(call, result)
                    }

                    MethodChannelType.PRINT_MOREFUN_TEST.value -> {
                        LogUtil.d(TAG, "MOREFUN::: Handling self-test print")
                        val morefunService = PrinterServiceFactory.getCurrentPrinterService()
                        if (morefunService is com.oxpay.o7lite.services.printers.MorefunPrinterService) {
                            val printResult = morefunService.printTestReceipt()
                            LogUtil.d(TAG, "MOREFUN::: Test print result = $printResult")
                            result.success(printResult)
                        } else {
                            LogUtil.d(TAG, "MOREFUN::: Service not available for test print")
                            result.success(false)
                        }
                    }

                    "getPrinterState" -> {
                        LogUtil.d(TAG, "MOREFUN::: Getting printer state")
                        val morefunService = PrinterServiceFactory.getCurrentPrinterService()
                        if (morefunService is com.oxpay.o7lite.services.printers.MorefunPrinterService) {
                            val state = morefunService.getPrinterState()
                            LogUtil.d(TAG, "MOREFUN::: Printer state = $state")
                            result.success(state)
                        } else {
                            // Service not initialized yet, return -1 (not connected)
                            LogUtil.d(TAG, "MOREFUN::: Service not available, returning -1")
                            result.success(-1)
                        }
                    }

                    else -> {
                        LogUtil.d(TAG, "MOREFUN::: Unknown method: ${call.method}")
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                LogUtil.e(TAG, "MOREFUN::: Error: ${e.message}")
                result.error("MOREFUN_ERROR", e.message, e.stackTraceToString())
            }
        }
    }

    private fun handlePrinterMethod(
        methodName: String,
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        LogUtil.d(TAG, "=== handlePrinterMethod START ===")
        LogUtil.d(TAG, "methodName: $methodName")
        showDebugToast("handlePrinterMethod: $methodName")
        
        when (methodName) {
            MethodChannelType.PRINT_RECEIPT_MANUAL.value -> {
                LogUtil.d(TAG, "MATCHED: PRINT_RECEIPT_MANUAL")
                showDebugToast("Starting receipt print...")
                handleReceiptPrinting(call, result)
            }

            MethodChannelType.PRINT_BITMAP.value -> {
                LogUtil.d(TAG, "MATCHED: PRINT_BITMAP")
                showDebugToast("Starting bitmap print...")
                val byteArray = call.argument<ByteArray>("bitmap")
                if (byteArray != null) {
                    val printResult = printerManager.printBitmap(byteArray)
                    result.success(printResult)
                } else {
                    result.error("BITMAP_NULL", "Bitmap data is null", null)
                }
            }

            MethodChannelType.PRINT_SUMMARY_REPORT.value -> {
                LogUtil.d(TAG, "MATCHED: PRINT_SUMMARY_REPORT")
                emitCastleReportPrintMonitorEvent(
                    "Native",
                    "Matched Castle summary report method"
                )
                showDebugToast("Starting summary report...")
                handleSummaryReportRequest(call, result)
            }

            else -> {
                LogUtil.e(TAG, "NO MATCH FOUND for method: $methodName")
                showDebugToast("ERROR: Unknown method: $methodName")
                result.notImplemented()
            }
        }
    }

    private fun handleReceiptPrinting(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        LogUtil.d(TAG, "=== handleReceiptPrinting START ===")
        showDebugToast("handleReceiptPrinting started")
        
        try {
            val byteArray = call.argument<ByteArray>("logoBitMap")
            LogUtil.d(TAG, "logoBitMap size: ${byteArray?.size ?: "NULL"}")
            
            val logoBitMap = byteArray ?: run {
                LogUtil.e(TAG, "ERROR: Logo bitmap is null")
                showDebugToast("ERROR: Logo bitmap is null")
                result.error("LOGO_BITMAP_NULL", "Logo bitmap is null", null)
                return
            }

            val stringCompany = call.argument<String>("stringCompany") ?: ""
            val address1 = call.argument<String>("address1") ?: ""
            val address2 = call.argument<String>("address2") ?: ""
            val address3 = call.argument<String>("address3") ?: ""
            val address4 = call.argument<String>("address4") ?: ""
            val txnState1 = call.argument<String>("txnState1") ?: ""
            val txnState2 = call.argument<String>("txnState2") ?: ""
            val txnTime = call.argument<String>("txnTime") ?: ""
            val txnDescription = call.argument<String>("txnDescription") ?: ""
            val txnTotal = call.argument<String>("txnTotal") ?: ""
            val terminalID = call.argument<String>("terminalID") ?: ""
            val txnID = call.argument<String>("txnID") ?: ""
            val brandName = call.argument<String>("brandName") ?: ""

            LogUtil.d(TAG, "Arguments parsed - Company: $stringCompany, TxnID: $txnID, Brand: $brandName")
            showDebugToast("Data parsed: $stringCompany")

            val byteArrayBarCode = call.argument<ByteArray>("bitmapBarCode")
            LogUtil.d(TAG, "bitmapBarCode size: ${byteArrayBarCode?.size ?: "NULL"}")
            
            val bitmapBarCode = byteArrayBarCode ?: run {
                LogUtil.e(TAG, "ERROR: Barcode bitmap is null")
                showDebugToast("ERROR: Barcode bitmap is null")
                result.error("BARCODE_BITMAP_NULL", "Barcode bitmap is null", null)
                return
            }

            LogUtil.d(TAG, "Calling printerManager.printReceiptManual...")
            showDebugToast("Calling printer...")
            
            val printResult = printerManager.printReceiptManual(
                logoBitMap,
                stringCompany,
                address1,
                address2,
                address3,
                address4,
                txnState1,
                txnState2,
                txnTime,
                txnDescription,
                txnTotal,
                terminalID,
                txnID,
                bitmapBarCode,
                brandName
            )

            LogUtil.d(TAG, "Print result: $printResult")
            showDebugToast("Print result: $printResult")
            result.success(printResult)
        } catch (e: Exception) {
            LogUtil.e(TAG, "Exception in handleReceiptPrinting: ${e.message}")
            LogUtil.e(TAG, "Stack trace: ${e.stackTraceToString()}")
            showDebugToast("PRINT ERROR: ${e.message}")
            result.error("PRINT_ERROR", e.message, e.stackTraceToString())
        }
    }

    /**
     * Print a pre-rendered receipt bitmap (captured from the Flutter print layout).
     * Used by Morefun: the Flutter side already lays out the receipt with the correct
     * payment logo, centered content and a defined width, so we print that bitmap
     * directly instead of re-rendering a native layout. PrinterManager forwards it to
     * MorefunPrinterService, which scales it to the printer head width.
     */
    private fun handleMorefunBitmapPrinting(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        val byteArray = call.argument<ByteArray>("bitmap")
        if (byteArray == null) {
            LogUtil.e(TAG, "MOREFUN::: Receipt bitmap is null")
            result.error("BITMAP_NULL", "Receipt bitmap is null", null)
            return
        }

        val resultBitmap = byteArray.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
            ?: run {
                result.error("LOGO_BITMAP_NULL", "Logo bitmap is null", null)
                return
            }

        val printResult = printerManager.printBitmap(byteArray)
        LogUtil.d(TAG, "MOREFUN::: printBitmap result=$printResult")
        result.success(printResult)
    }

    private fun handleSummaryPrinting(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        val acquirer = call.argument<String>("acquirer")
        val summaryDataJson = call.argument<String>("summaryData")

        if (summaryDataJson == null) {
            result.error("SUMMARY_DATA_NULL", "Summary data is null", null)
            return
        }

        // log the summary data
        LogUtil.d("PrinterManager", "Summary Data JSON: $summaryDataJson")

        val summaryReportData = Utils.getSummaryData(this, summaryDataJson)
        if (summaryReportData != null) {
            val printResult = printerManager.printSummaryReport(acquirer, summaryReportData)
            result.success(printResult)
        } else {
            result.error("SUMMARY_PARSE_ERROR", "Failed to parse summary data", null)
        }
    }

    /**
     * Handle Landi-specific receipt printing.
     * Uses direct LandiPrinterService instead of PrinterManager.
     * 
     * This follows the EXACT pattern from the original MainActivity.kt which worked correctly:
     * - NO init check before printing
     * - Direct call to LandiPrinterService.startPrinter()
     * - LandiPrinterService internally gets printer via MainApplication.getOmniDriver().getPrinter()
     * 
     * Requirements: 3.1, 3.2, 3.3, 3.4, 5.1, 5.2, 5.3
     */
    private fun handleLandiReceiptPrinting(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        LogUtil.d(TAG, "=== handleLandiReceiptPrinting START ===")
        
        // Extract bitmap parameters from MethodCall
        val byteArray = call.argument<ByteArray>("logoBitMap")
        val logoBitMap = byteArray?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
            ?: run {
                result.error("LOGO_BITMAP_NULL", "Logo bitmap is null", null)
                return
            }
        
        val stringCompany = call.argument<String>("stringCompany") ?: ""
        val address1 = call.argument<String>("address1") ?: ""
        val address2 = call.argument<String>("address2") ?: ""
        val address3 = call.argument<String>("address3") ?: ""
        val address4 = call.argument<String>("address4") ?: ""
        val txnState1 = call.argument<String>("txnState1") ?: ""
        val txnState2 = call.argument<String>("txnState2") ?: ""
        val txnTime = call.argument<String>("txnTime") ?: ""
        val txnDescription = call.argument<String>("txnDescription") ?: ""
        val txnTotal = call.argument<String>("txnTotal") ?: ""
        val terminalID = call.argument<String>("terminalID") ?: ""
        val txnID = call.argument<String>("txnID") ?: ""
        val brandName = call.argument<String>("brandName") ?: ""
        
        val byteArrayBarCode = call.argument<ByteArray>("bitmapBarCode")
        val bitmapBarCode = byteArrayBarCode?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
            ?: run {
                result.error("BARCODE_BITMAP_NULL", "Barcode bitmap is null", null)
                return
            }
        
        // Create bitmap using PrintUtilRefactored.loadLandiBitmapFromView()
        val printBitmap = PrintUtilRefactored.loadLandiBitmapFromView(
            context,
            logoBitMap,
            stringCompany,
            address1,
            address2,
            address3,
            address4,
            txnState1,
            txnState2,
            txnTime,
            txnDescription,
            txnTotal,
            terminalID,
            txnID,
            bitmapBarCode,
            brandName
        )
        
        if (printBitmap == null) {
            result.error("BITMAP_CREATE_FAILED", "Failed to create print bitmap", null)
            return
        }
        
        // Direct print - same pattern as original MainActivity.kt
        // NO init check, just call LandiPrinterService directly
        try {
            val landiPrinterService = LandiPrinterService(printBitmap)
            landiPrinterService.startPrinter()
            LogUtil.d(TAG, "Landi receipt print initiated")
            result.success("SUCCESS")
        } catch (e: RemoteException) {
            LogUtil.e(TAG, "RemoteException in Landi printing: ${e.message}")
            showDebugToast(e.message ?: "RemoteException occurred")
            result.error("LANDI_PRINT_FAILED", e.message, null)
        } catch (e: Exception) {
            LogUtil.e(TAG, "Exception in Landi printing: ${e.message}")
            showDebugToast(e.message ?: "Exception occurred")
            result.error("LANDI_PRINT_ERROR", e.message, null)
        }
    }

    /**
     * Handle Landi-specific summary printing.
     * Uses direct LandiPrinterService instead of PrinterManager.
     * 
     * This follows the EXACT pattern from the original MainActivity.kt which worked correctly.
     * 
     * Requirements: 3.1, 3.4
     */
    private fun handleLandiSummaryPrinting(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        LogUtil.d(TAG, "LANDI_SUMMARY: === handleLandiSummaryPrinting START ===")
        
        val acquirer = call.argument<String>("acquirer")
        val summaryDataJson = call.argument<String>("summaryData")
        
        LogUtil.d(TAG, "LANDI_SUMMARY: acquirer=$acquirer")
        LogUtil.d(TAG, "LANDI_SUMMARY: summaryDataJson isNull=${summaryDataJson == null}, length=${summaryDataJson?.length ?: 0}")
        
        if (summaryDataJson == null) {
            LogUtil.e(TAG, "LANDI_SUMMARY: ERROR - summaryDataJson is null")
            result.error("SUMMARY_DATA_NULL", "Summary data is null", null)
            return
        }
        
        LogUtil.d(TAG, "LANDI_SUMMARY: summaryDataJson preview=${summaryDataJson.take(300)}")
        
        // Parse summary data
        LogUtil.d(TAG, "LANDI_SUMMARY: Calling Utils.getSummaryData()...")
        val summaryReportData: com.oxpay.o7lite.entity.TransactionSummary?
        try {
            summaryReportData = Utils.getSummaryData(this, summaryDataJson)
            LogUtil.d(TAG, "LANDI_SUMMARY: getSummaryData result isNull=${summaryReportData == null}")
            if (summaryReportData != null) {
                LogUtil.d(TAG, "LANDI_SUMMARY: totalPayAmount=${summaryReportData.totalPayAmount}, " +
                    "totalPayCount=${summaryReportData.totalPayCount}, " +
                    "txnListSize=${summaryReportData.transactionList?.size ?: 0}")
            }
        } catch (e: Exception) {
            LogUtil.e(TAG, "LANDI_SUMMARY: ERROR in getSummaryData: ${e.message}")
            LogUtil.e(TAG, "LANDI_SUMMARY: getSummaryData stack: ${e.stackTraceToString()}")
            result.error("SUMMARY_PARSE_ERROR", "Failed to parse summary data: ${e.message}", e.stackTraceToString())
            return
        }
        
        if (summaryReportData == null) {
            LogUtil.e(TAG, "LANDI_SUMMARY: ERROR - summaryReportData is null after parsing")
            result.error("SUMMARY_PARSE_ERROR", "Failed to parse summary data", null)
            return
        }
        
        // Create summary bitmap using PrintUtilRefactored (same as ANFU format for Landi)
        LogUtil.d(TAG, "LANDI_SUMMARY: Calling PrintUtilRefactored.loadAnfuDailySummaryReport()...")
        val printBitmap: android.graphics.Bitmap?
        try {
            printBitmap = PrintUtilRefactored.loadAnfuDailySummaryReport(context, acquirer, summaryReportData)
            LogUtil.d(TAG, "LANDI_SUMMARY: loadAnfuDailySummaryReport result isNull=${printBitmap == null}")
            if (printBitmap != null) {
                LogUtil.d(TAG, "LANDI_SUMMARY: bitmap size=${printBitmap.width}x${printBitmap.height}")
            }
        } catch (e: Exception) {
            LogUtil.e(TAG, "LANDI_SUMMARY: ERROR in loadAnfuDailySummaryReport: ${e.message}")
            LogUtil.e(TAG, "LANDI_SUMMARY: bitmap creation stack: ${e.stackTraceToString()}")
            result.error("BITMAP_CREATE_FAILED", "Failed to create summary bitmap: ${e.message}", e.stackTraceToString())
            return
        }
        
        if (printBitmap == null) {
            LogUtil.e(TAG, "LANDI_SUMMARY: ERROR - printBitmap is null")
            result.error("BITMAP_CREATE_FAILED", "Failed to create summary bitmap", null)
            return
        }
        
        // Direct print - same pattern as original MainActivity.kt
        // NO init check, just call LandiPrinterService directly
        LogUtil.d(TAG, "LANDI_SUMMARY: Creating LandiPrinterService and calling startPrinter()...")
        try {
            val landiPrinterService = LandiPrinterService(printBitmap)
            landiPrinterService.startPrinter()
            LogUtil.d(TAG, "LANDI_SUMMARY: startPrinter() completed successfully")
            result.success(true)
        } catch (e: RemoteException) {
            LogUtil.e(TAG, "LANDI_SUMMARY: RemoteException in startPrinter: ${e.message}")
            showDebugToast(e.message ?: "RemoteException occurred")
            result.error("LANDI_PRINT_FAILED", e.message, null)
        } catch (e: Exception) {
            LogUtil.e(TAG, "LANDI_SUMMARY: Exception in startPrinter: ${e.message}")
            showDebugToast(e.message ?: "Exception occurred")
            result.error("LANDI_PRINT_ERROR", e.message, null)
        }
    }

    private fun handleSummaryReportRequest(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        emitCastleReportPrintMonitorEvent("Native", "Parsing Castle summary arguments")
        val brand = call.argument<String>("brand")
        val acquirer = call.argument<String>("acquirer")
        val currency = call.argument<String>("currency")
        val startDate = call.argument<String>("startDate")
        val endDate = call.argument<String>("endDate")
        val mcpTerminalId = call.argument<String>("mcpTerminalId")
        val signature = call.argument<String>("signature")
        val summaryDataJson = call.argument<String>("summaryData")

        emitCastleReportPrintMonitorEvent(
            "Native",
            "Arguments parsed: brand=$brand, acquirer=$acquirer, currency=$currency, tid=$mcpTerminalId"
        )

        if (!summaryDataJson.isNullOrBlank()) {
            emitCastleReportPrintMonitorEvent(
                "Native JSON",
                "Direct summaryData received: length=${summaryDataJson.length}"
            )
            try {
                val summaryReportData = Utils.getSummaryData(this, summaryDataJson)
                if (summaryReportData == null) {
                    emitCastleReportPrintMonitorEvent(
                        "Native JSON",
                        "Failed to parse direct summaryData",
                        "error",
                        done = true
                    )
                    result.error("SUMMARY_PARSE_ERROR", "Failed to parse direct summaryData", null)
                    return
                }

                emitCastleReportPrintMonitorEvent(
                    "Native Print",
                    "Direct summaryData parsed: txnListSize=${summaryReportData.transactionList?.size ?: 0}"
                )
                val printResult = printerManager.printSummaryReport(brand, summaryReportData)
                emitCastleReportPrintMonitorEvent(
                    "Native Print",
                    "printerManager.printSummaryReport result=$printResult",
                    if (printResult) "success" else "error",
                    done = true
                )
                result.success(printResult)
                return
            } catch (e: Exception) {
                LogUtil.e(TAG, "Castle direct summaryData error: ${e.message}")
                emitCastleReportPrintMonitorEvent(
                    "Native JSON",
                    "Direct summaryData error: ${e.message}",
                    "error",
                    done = true
                )
                result.error("SUMMARY_DIRECT_PRINT_ERROR", e.message, e.stackTraceToString())
                return
            }
        }

        emitCastleReportPrintMonitorEvent(
            "Native",
            "No direct summaryData found; falling back to native HTTP"
        )

        val summaryReportRequest = SummaryReportRequest(
            data = DataEntity(
                acquirer = acquirer,
                currency = currency,
                startDate = startDate,
                endDate = endDate,
                mcpTerminalId = mcpTerminalId,
            ),
            header = HeaderEntity(
                appType = "o7lite",
                appVersion = "3.0.35",
                version = "3.0.35",
                mcpTerminalId = mcpTerminalId,
                signature = signature
            )
        )

        fetchSummaryReports(brand, summaryReportRequest)
        emitCastleReportPrintMonitorEvent(
            "Native",
            "Returned true to Flutter; native HTTP continues async"
        )
        result.success(true)
    }

    private fun fetchSummaryReports(brand: String?, summaryReportRequest: SummaryReportRequest) {
        emitCastleReportPrintMonitorEvent(
            "Native HTTP",
            "Creating OkHttp/Retrofit client for summary report"
        )
        val okHttpClient = OkHttpClient.Builder()
            .connectTimeout(PrinterConstants.CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(PrinterConstants.READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .writeTimeout(PrinterConstants.WRITE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .build()

        val retrofit: Retrofit = Retrofit.Builder()
            .baseUrl(API_URL)
            .addConverterFactory(GsonConverterFactory.create())
            .client(okHttpClient)
            .build()

        val service = retrofit.create(ApiService::class.java)
        val call = service.getSummaryReports(summaryReportRequest)
        emitCastleReportPrintMonitorEvent("Native HTTP", "Summary report request enqueued")

        call?.enqueue(object : Callback<SummaryReportResponse?> {
            override fun onResponse(
                call: Call<SummaryReportResponse?>,
                response: Response<SummaryReportResponse?>
            ) {
                emitCastleReportPrintMonitorEvent(
                    "Native HTTP",
                    "Response received: httpStatus=${response.code()}"
                )
                if (response.isSuccessful) {
                    val transactionSummary = response.body()
                    // log the response
                    LogUtil.d("SummaryReport", "@@@ Response: $transactionSummary")
                    if (transactionSummary != null) {
                        val summaryData = transactionSummary.data
                        if (summaryData != null) {
                            emitCastleReportPrintMonitorEvent(
                                "Native Print",
                                "Summary data parsed: txnListSize=${summaryData.transactionList?.size ?: 0}"
                            )
                            val printResult = printerManager.printSummaryReport(
                                brand,
                                summaryData
                            )
                            emitCastleReportPrintMonitorEvent(
                                "Native Print",
                                "printerManager.printSummaryReport result=$printResult",
                                if (printResult) "success" else "error",
                                done = true
                            )
                        } else {
                            LogUtil.e("SummaryReport", "@@@ transactionSummary.data is null")
                            emitCastleReportPrintMonitorEvent(
                                "Native HTTP",
                                "Response body data is null",
                                "error",
                                done = true
                            )
                        }
                    } else {
                        LogUtil.e("SummaryReport", "@@@ transactionSummary is null")
                        emitCastleReportPrintMonitorEvent(
                            "Native HTTP",
                            "Response body is null",
                            "error",
                            done = true
                        )
                    }
                } else {
                    LogUtil.e("SummaryReport", "HTTP Status: ${response.code()}")
                    val errorBody = response.errorBody()?.string()
                    if (errorBody != null) {
                        LogUtil.e("SummaryReport", "Error Body: $errorBody")
                    }
                    emitCastleReportPrintMonitorEvent(
                        "Native HTTP",
                        "HTTP ${response.code()}: ${errorBody ?: "empty error body"}",
                        "error",
                        done = true
                    )
                    val errorMessage = "HTTP Status: ${response.code()}\nError Body: $errorBody"
                    Utils.showErrorDialog(this@MainActivityRefactored, errorMessage)
                }
            }

            override fun onFailure(call: Call<SummaryReportResponse?>, t: Throwable) {
                LogUtil.e("SummaryReport", "onFailure: ${t.message}")
                emitCastleReportPrintMonitorEvent(
                    "Native HTTP",
                    "Request failed: ${t.message}",
                    "error",
                    done = true
                )
                val errorMessage = "onFailure: ${t.message}"
                Utils.showErrorDialog(this@MainActivityRefactored, errorMessage)
            }
        })
    }

    private fun emitCastleReportPrintMonitorEvent(
        stage: String,
        message: String,
        level: String = "info",
        done: Boolean = false
    ) {
        LogUtil.d("CastleReportPrintMonitor", "[$level][$stage] $message")
        val payload = mapOf(
            "stage" to stage,
            "message" to message,
            "level" to level,
            "done" to done
        )
        runOnUiThread {
            castleReportPrintMonitorChannel?.invokeMethod(
                METHOD_CASTLE_REPORT_PRINT_MONITOR_EVENT,
                payload
            )
        }
    }
}
