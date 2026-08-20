package com.oxpay.o7lite.services.printers

import CTOS.CtPrint
import android.content.Context
import android.graphics.Bitmap
import android.widget.Toast
import com.oxpay.o7lite.constants.PrinterConstants
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.services.base.BasePrinterService
import com.oxpay.o7lite.utils.LogUtil

/**
 * Castle printer service implementation
 */
class CastlePrinterService(context: Context) : BasePrinterService(context, PrinterType.CASTLE) {
    
    companion object {
        private const val TAG = "CastlePrinterService"
    }
    
    // Helper function to show Toast
    private fun showDebugToast(message: String) {
//        (context as? android.app.Activity)?.runOnUiThread {
//            Toast.makeText(context, message, Toast.LENGTH_LONG).show()
//        }
        LogUtil.d(TAG, "TOAST: $message")
    }
    
    override fun initialize(): Boolean {
        LogUtil.d(TAG, "=== initialize() START ===")
        showDebugToast("Castle printer initializing...")
        isInitialized = true
        LogUtil.d(TAG, "Castle printer initialized")
        showDebugToast("Castle printer initialized OK")
        return true
    }
    
    override fun printBitmapInternal(bitmap: Bitmap): Boolean {
        LogUtil.d(TAG, "=== printBitmapInternal START ===")
        LogUtil.d(TAG, "Bitmap size: ${bitmap.width}x${bitmap.height}")
        showDebugToast("Castle printing: ${bitmap.width}x${bitmap.height}")
        
        return try {
            LogUtil.d(TAG, "Creating CtPrint instance...")
            val print = CtPrint()
            
            LogUtil.d(TAG, "Setting heat level: ${PrinterConstants.DEFAULT_HEAT_LEVEL}")
            print.setHeatLevel(PrinterConstants.DEFAULT_HEAT_LEVEL)
            
            val pageHeight = (bitmap.height * PrinterConstants.RECEIPT_HEIGHT_MULTIPLIER).toInt()
            LogUtil.d(TAG, "Initializing page with height: $pageHeight")
            print.initPage(pageHeight)
            
            LogUtil.d(TAG, "Drawing image at (0, 0)...")
            print.drawImage(bitmap, 0, 0)
            
            LogUtil.d(TAG, "Calling printPage()...")
            showDebugToast("Sending to printer...")
            print.printPage()
            
            LogUtil.d(TAG, "Bitmap printed successfully")
            showDebugToast("Print SUCCESS!")
            true
        } catch (e: Exception) {
            LogUtil.e(TAG, "Failed to print bitmap: ${e.message}")
            LogUtil.e(TAG, "Stack trace: ${e.stackTraceToString()}")
            showDebugToast("CASTLE ERROR: ${e.message}")
            false
        }
    }
    
    fun printReceiptDetail(bitmap: Bitmap, bitmapBarCode: Bitmap): Boolean {
        LogUtil.d(TAG, "=== printReceiptDetail START ===")
        return try {
            val print = CtPrint()
            print.setHeatLevel(PrinterConstants.DEFAULT_HEAT_LEVEL)
            print.initPage(((bitmap.height + bitmapBarCode.height) * PrinterConstants.SUMMARY_HEIGHT_MULTIPLIER).toInt())
            print.drawImage(bitmap, 0, 0)
            print.setHeatLevel(PrinterConstants.BARCODE_HEAT_LEVEL)
            print.drawImage(
                bitmapBarCode,
                (bitmap.width * PrinterConstants.BARCODE_POSITION_X_MULTIPLIER).toInt(),
                (bitmap.height * PrinterConstants.BARCODE_POSITION_Y_MULTIPLIER).toInt()
            )
            print.printPage()
            
            LogUtil.d(TAG, "Receipt detail printed successfully")
            true
        } catch (e: Exception) {
            LogUtil.e(TAG, "Failed to print receipt detail: ${e.message}")
            LogUtil.e(TAG, "Stack trace: ${e.stackTraceToString()}")
            showDebugToast("CASTLE ERROR: ${e.message}")
            false
        }
    }
    
    override fun cleanup() {
        isInitialized = false
        LogUtil.d(TAG, "Castle printer cleaned up")
    }
}
