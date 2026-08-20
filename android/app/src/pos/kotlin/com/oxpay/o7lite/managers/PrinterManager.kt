package com.oxpay.o7lite.managers

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.widget.Toast
import com.oxpay.o7lite.entity.TransactionSummary
import com.oxpay.o7lite.factory.PrinterServiceFactory
import com.oxpay.o7lite.interfaces.IPrinterService
import com.oxpay.o7lite.models.PrintReceiptData
import com.oxpay.o7lite.utils.LogUtil
import com.oxpay.o7lite.utils.PrintUtilRefactored

/**
 * Manager class for handling all printer operations
 */
class PrinterManager(private val context: Context) {
    
    companion object {
        private const val TAG = "PrinterManager"
    }
    
    private var printerService: IPrinterService? = null
    
    // Helper function to show Toast on UI thread
    private fun showDebugToast(message: String) {
//        (context as? android.app.Activity)?.runOnUiThread {
//            Toast.makeText(context, message, Toast.LENGTH_LONG).show()
//        }
        LogUtil.d(TAG, "TOAST: $message")
    }
    
    fun initialize(): Boolean {
        LogUtil.d(TAG, "=== initialize() START ===")
        printerService = PrinterServiceFactory.createPrinterService(context)
        val isReady = printerService?.isReady() ?: false
        LogUtil.d(TAG, "Printer service created, isReady: $isReady")
        LogUtil.d(TAG, "Printer service type: ${printerService?.javaClass?.simpleName}")
        showDebugToast("Printer init: $isReady")
        return isReady
    }
    
    fun printReceiptManual(
        logoBitMap: ByteArray,
        companyName: String,
        address1: String = "",
        address2: String = "",
        address3: String = "",
        address4: String = "",
        txnState1: String,
        txnState2: String,
        txnTime: String,
        txnDescription: String,
        txnTotal: String,
        terminalID: String,
        txnID: String,
        bitmapBarCode: ByteArray,
        brandName : String
    ): Boolean {
        LogUtil.d(TAG, "=== printReceiptManual START ===")
        LogUtil.d(TAG, "logoBitMap size: ${logoBitMap.size}")
        LogUtil.d(TAG, "bitmapBarCode size: ${bitmapBarCode.size}")
        LogUtil.d(TAG, "companyName: $companyName")
        LogUtil.d(TAG, "txnID: $txnID")
        LogUtil.d(TAG, "brandName: $brandName")
        showDebugToast("PrinterManager: Decoding bitmaps...")
        
        val logoBitmap = BitmapFactory.decodeByteArray(logoBitMap, 0, logoBitMap.size)
        val barcodeBitmap = BitmapFactory.decodeByteArray(bitmapBarCode, 0, bitmapBarCode.size)
        
        if (logoBitmap == null) {
            LogUtil.e(TAG, "ERROR: Failed to decode logo bitmap")
            showDebugToast("ERROR: Logo decode failed")
            return false
        }
        
        if (barcodeBitmap == null) {
            LogUtil.e(TAG, "ERROR: Failed to decode barcode bitmap")
            showDebugToast("ERROR: Barcode decode failed")
            return false
        }
        
        LogUtil.d(TAG, "Bitmaps decoded successfully")
        LogUtil.d(TAG, "Logo bitmap: ${logoBitmap.width}x${logoBitmap.height}")
        LogUtil.d(TAG, "Barcode bitmap: ${barcodeBitmap.width}x${barcodeBitmap.height}")
        showDebugToast("Bitmaps OK: ${logoBitmap.width}x${logoBitmap.height}")
        
        val receiptData = PrintReceiptData(
            logoBitmap = logoBitmap,
            companyName = companyName,
            address1 = address1,
            address2 = address2,
            address3 = address3,
            address4 = address4,
            transactionState1 = txnState1,
            transactionState2 = txnState2,
            transactionTime = txnTime,
            transactionDescription = txnDescription,
            transactionTotal = txnTotal,
            terminalId = terminalID,
            transactionId = txnID,
            barcodeBitmap = barcodeBitmap,
            brandName = brandName
        )

        LogUtil.d(TAG, "PrintReceiptData created")
        LogUtil.d(TAG, "printerService: ${printerService?.javaClass?.simpleName ?: "NULL"}")
        
        if (printerService == null) {
            LogUtil.e(TAG, "ERROR: printerService is NULL!")
            showDebugToast("ERROR: Printer service is NULL!")
            return false
        }
        
        showDebugToast("Calling printerService.printReceipt...")
        
        return try {
            val result = printerService?.printReceipt(receiptData) ?: false
            LogUtil.d(TAG, "printReceipt result: $result")
            showDebugToast("Print result: $result")
            result
        } catch (e: Exception) {
            LogUtil.e(TAG, "Exception in printReceipt: ${e.message}")
            LogUtil.e(TAG, "Stack trace: ${e.stackTraceToString()}")
            showDebugToast("Print exception: ${e.message}")
            false
        }
    }
    
    fun printBitmap(bitmap: ByteArray): Boolean {
        val decodedBitmap = BitmapFactory.decodeByteArray(bitmap, 0, bitmap.size)
        return if (decodedBitmap != null) {
            printerService?.printBitmap(decodedBitmap) ?: false
        } else {
            LogUtil.e("PrinterManager", "Failed to decode bitmap")
            false
        }
    }
    
    fun printSummaryReport(acquirer: String?, summaryData: TransactionSummary): Boolean {
        return printerService?.printSummaryReport(acquirer, summaryData) ?: false
    }
    
    fun isReady(): Boolean {
        return printerService?.isReady() ?: false
    }
    
    fun cleanup() {
        printerService?.cleanup()
        printerService = null
        PrinterServiceFactory.cleanup()
    }
}
