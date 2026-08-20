package com.oxpay.o7lite.factory

import android.content.Context
import android.os.Build
import android.widget.Toast
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.interfaces.IPrinterService
import com.oxpay.o7lite.services.printers.AnfuPrinterService
import com.oxpay.o7lite.services.printers.CastlePrinterService
import com.oxpay.o7lite.services.printers.CoherentPrinterService
import com.oxpay.o7lite.services.printers.LandiPrinterService
import com.oxpay.o7lite.services.printers.MorefunPrinterService
import com.oxpay.o7lite.services.printers.SunmiPrinterService
import com.oxpay.o7lite.services.printers.WizarPosPrinterService
import com.oxpay.o7lite.utils.LogUtil
import com.oxpay.o7lite.utils.Utils

/**
 * Factory class for creating printer services based on device type
 */
object PrinterServiceFactory {
    
    private const val TAG = "PrinterServiceFactory"
    private var currentPrinterService: IPrinterService? = null
    
    // Helper function to show Toast
    private fun showDebugToast(context: Context, message: String) {
//        (context as? android.app.Activity)?.runOnUiThread {
//            Toast.makeText(context, message, Toast.LENGTH_LONG).show()
//        }
        LogUtil.d(TAG, "TOAST: $message")
    }
    
    /**
     * Create printer service based on device detection
     */
    fun createPrinterService(context: Context): IPrinterService? {
        LogUtil.d(TAG, "=== createPrinterService START ===")
        LogUtil.d(TAG, "Device Brand: ${Build.BRAND}")
        LogUtil.d(TAG, "Device Model: ${Build.MODEL}")
        LogUtil.d(TAG, "Device Manufacturer: ${Build.MANUFACTURER}")
        
        val printerType = detectPrinterType()
        LogUtil.d(TAG, "Detected printer type: ${printerType?.name ?: "NULL"}")
        showDebugToast(context, "Printer type: ${printerType?.name ?: "UNKNOWN"}")
        
        return createPrinterService(context, printerType)
    }
    
    /**
     * Create printer service for specific printer type
     */
    fun createPrinterService(context: Context, printerType: PrinterType?): IPrinterService? {
        if (printerType == null) {
            LogUtil.e(TAG, "ERROR: Printer type is null")
            showDebugToast(context, "ERROR: No printer detected!")
            return null
        }
        
        // Clean up existing service if different type
        if (currentPrinterService != null && getCurrentPrinterType() != printerType) {
            LogUtil.d(TAG, "Cleaning up existing printer service")
            currentPrinterService?.cleanup()
            currentPrinterService = null
        }
        
        // Create new service if needed
        if (currentPrinterService == null) {
            LogUtil.d(TAG, "Creating new printer service for: ${printerType.name}")
            showDebugToast(context, "Creating ${printerType.name} printer...")
            
            currentPrinterService = try {
                when (printerType) {
                    PrinterType.CASTLE -> CastlePrinterService(context)
                    PrinterType.ANFU -> AnfuPrinterService(context)
                    PrinterType.SUNMI -> SunmiPrinterService(context)
                    PrinterType.LANDI -> LandiPrinterService(context)
                    PrinterType.WIZAR_POS -> WizarPosPrinterService(context)
                    PrinterType.COHERENT -> CoherentPrinterService(context)
                    PrinterType.MOREFUN -> MorefunPrinterService(context)
                }
            } catch (e: Exception) {
                LogUtil.e(TAG, "Exception creating printer service: ${e.message}")
                LogUtil.e(TAG, "Stack trace: ${e.stackTraceToString()}")
                showDebugToast(context, "ERROR creating printer: ${e.message}")
                null
            }
            
            if (currentPrinterService != null) {
                LogUtil.d(TAG, "Initializing printer service...")
                try {
                    currentPrinterService?.initialize()
                    LogUtil.d(TAG, "Printer service initialized successfully")
                    showDebugToast(context, "Printer initialized OK")
                } catch (e: Exception) {
                    LogUtil.e(TAG, "Exception initializing printer: ${e.message}")
                    showDebugToast(context, "ERROR init printer: ${e.message}")
                }
            }
            
            LogUtil.d(TAG, "Created printer service: ${printerType.name}")
        }
        
        return currentPrinterService
    }
    
    /**
     * Get current printer service instance
     */
    fun getCurrentPrinterService(): IPrinterService? {
        return currentPrinterService
    }
    
    /**
     * Get current printer type
     */
    fun getCurrentPrinterType(): PrinterType? {
        return when (currentPrinterService) {
            is CastlePrinterService -> PrinterType.CASTLE
            is AnfuPrinterService -> PrinterType.ANFU
            is SunmiPrinterService -> PrinterType.SUNMI
            is LandiPrinterService -> PrinterType.LANDI
            is WizarPosPrinterService -> PrinterType.WIZAR_POS
            is CoherentPrinterService -> PrinterType.COHERENT
            is MorefunPrinterService -> PrinterType.MOREFUN
            else -> null
        }
    }
    
    /**
     * Detect printer type based on device characteristics
     */
    private fun detectPrinterType(): PrinterType? {
        LogUtil.d(TAG, "=== detectPrinterType START ===")
        LogUtil.d(TAG, "Checking device type...")
        LogUtil.d(TAG, "isCASTLE: ${Utils.isCASTLE()}")
        LogUtil.d(TAG, "isANFU: ${Utils.isANFU()}")
        LogUtil.d(TAG, "isSUNMI: ${Utils.isSUNMI()}")
        LogUtil.d(TAG, "isLANDI: ${Utils.isLANDI()}")
        LogUtil.d(TAG, "isWIZAR: ${Utils.isWIZAR()}")
        LogUtil.d(TAG, "isCOHERENT: ${Utils.isCOHERENT()}")
        LogUtil.d(TAG, "isMOREFUN: ${Utils.isMOREFUN()}")
        
        return when {
            Utils.isCASTLE() -> {
                LogUtil.d(TAG, "Detected: CASTLE")
                PrinterType.CASTLE
            }
            Utils.isANFU() -> {
                LogUtil.d(TAG, "Detected: ANFU")
                PrinterType.ANFU
            }
            Utils.isSUNMI() -> {
                LogUtil.d(TAG, "Detected: SUNMI")
                PrinterType.SUNMI
            }
            Utils.isLANDI() -> {
                LogUtil.d(TAG, "Detected: LANDI")
                PrinterType.LANDI
            }
            Utils.isWIZAR() -> {
                LogUtil.d(TAG, "Detected: WIZAR_POS")
                PrinterType.WIZAR_POS
            }
            Utils.isCOHERENT() -> {
                LogUtil.d(TAG, "Detected: COHERENT")
                PrinterType.COHERENT
            }
            Utils.isMOREFUN() -> {
                LogUtil.d(TAG, "Detected: MOREFUN")
                PrinterType.MOREFUN
            }
            else -> {
                LogUtil.w(TAG, "WARNING: Unknown device type - Brand: ${Build.BRAND}, Model: ${Build.MODEL}")
                null
            }
        }
    }
    
    /**
     * Check if specific printer type is supported
     */
    fun isPrinterTypeSupported(printerType: PrinterType): Boolean {
        return when (printerType) {
            PrinterType.CASTLE -> Utils.isCASTLE()
            PrinterType.ANFU -> Utils.isANFU()
            PrinterType.SUNMI -> Utils.isSUNMI()
            PrinterType.LANDI -> Utils.isLANDI()
            PrinterType.WIZAR_POS -> Utils.isWIZAR()
            PrinterType.COHERENT -> Utils.isCOHERENT()
            PrinterType.MOREFUN -> Utils.isMOREFUN()
        }
    }
    
    /**
     * Cleanup all printer services
     */
    fun cleanup() {
        currentPrinterService?.cleanup()
        currentPrinterService = null
        LogUtil.d("PrinterServiceFactory", "All printer services cleaned up")
    }
}
