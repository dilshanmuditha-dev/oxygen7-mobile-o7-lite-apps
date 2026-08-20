package com.oxpay.o7lite.services.base

import android.content.Context
import android.graphics.Bitmap
import android.widget.Toast
import com.oxpay.o7lite.entity.TransactionSummary
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.interfaces.IPrinterService
import com.oxpay.o7lite.models.PrintReceiptData
import com.oxpay.o7lite.utils.LogUtil
import com.oxpay.o7lite.utils.PrintUtilRefactored

/**
 * Base abstract class for printer services providing common functionality
 */
abstract class BasePrinterService(
    protected val context: Context,
    protected val printerType: PrinterType
) : IPrinterService {
    
    companion object {
        private const val TAG = "BasePrinterService"
    }
    
    protected var isInitialized = false
    
    // Helper function to show Toast
    private fun showDebugToast(message: String) {
//        (context as? android.app.Activity)?.runOnUiThread {
//            Toast.makeText(context, message, Toast.LENGTH_LONG).show()
//        }
        LogUtil.d(TAG, "TOAST: $message")
    }
    
    override fun isReady(): Boolean {
        return isInitialized
    }
    
    override fun printReceipt(receiptData: PrintReceiptData): Boolean {
        LogUtil.d(TAG, "=== printReceipt START ===")
        LogUtil.d(TAG, "printerType: ${printerType.name}")
        LogUtil.d(TAG, "isReady: ${isReady()}")
        showDebugToast("BasePrinter.printReceipt: ${printerType.name}")
        
        if (!isReady()) {
            LogUtil.e(TAG, "ERROR: Printer not ready!")
            showDebugToast("ERROR: Printer not ready!")
            return false
        }
        
        LogUtil.d(TAG, "Creating receipt bitmap...")
        showDebugToast("Creating bitmap...")
        
        val bitmap = try {
            createReceiptBitmap(receiptData)
        } catch (e: Exception) {
            LogUtil.e(TAG, "Exception creating bitmap: ${e.message}")
            LogUtil.e(TAG, "Stack trace: ${e.stackTraceToString()}")
            showDebugToast("ERROR creating bitmap: ${e.message}")
            null
        }
        
        if (bitmap == null) {
            LogUtil.e(TAG, "ERROR: Bitmap is NULL!")
            showDebugToast("ERROR: Bitmap is NULL!")
            return false
        }
        
        LogUtil.d(TAG, "Bitmap created: ${bitmap.width}x${bitmap.height}")
        showDebugToast("Bitmap: ${bitmap.width}x${bitmap.height}")
        
        LogUtil.d(TAG, "Calling printBitmapInternal...")
        showDebugToast("Printing bitmap...")
        
        return try {
            val result = printBitmapInternal(bitmap)
            LogUtil.d(TAG, "printBitmapInternal result: $result")
            showDebugToast("Print done: $result")
            result
        } catch (e: Exception) {
            LogUtil.e(TAG, "Exception in printBitmapInternal: ${e.message}")
            LogUtil.e(TAG, "Stack trace: ${e.stackTraceToString()}")
            showDebugToast("PRINT ERROR: ${e.message}")
            false
        }
    }
    
    override fun printSummaryReport(acquirer: String?, summaryData: TransactionSummary): Boolean {
        if (!isReady()) {
            return false
        }
        
        val bitmap = createSummaryBitmap(acquirer, summaryData)
        return bitmap?.let { printBitmapInternal(it) } ?: false
    }
    
    override fun printBitmap(bitmap: Bitmap): Boolean {
        if (!isReady()) {
            return false
        }
        return printBitmapInternal(bitmap)
    }
    
    /**
     * Create receipt bitmap using PrintUtil
     */
    protected fun createReceiptBitmap(receiptData: PrintReceiptData): Bitmap? {
        return when (printerType) {
            PrinterType.CASTLE -> PrintUtilRefactored.loadBitmapFromView(
                context,
                receiptData.logoBitmap,
                receiptData.companyName,
                receiptData.address1,
                receiptData.address2,
                receiptData.address3,
                receiptData.address4,
                receiptData.transactionState1,
                receiptData.transactionState2,
                receiptData.transactionTime,
                receiptData.transactionDescription,
                receiptData.transactionTotal,
                receiptData.terminalId,
                receiptData.transactionId,
                receiptData.barcodeBitmap,
                receiptData.brandName ?: ""
            )
            PrinterType.ANFU, PrinterType.COHERENT, PrinterType.MOREFUN -> PrintUtilRefactored.loadANFUBitmapFromView(
                context,
                receiptData.logoBitmap,
                receiptData.companyName,
                receiptData.address1,
                receiptData.address2,
                receiptData.address3,
                receiptData.address4,
                receiptData.transactionState1,
                receiptData.transactionState2,
                receiptData.transactionTime,
                receiptData.transactionDescription,
                receiptData.transactionTotal,
                receiptData.terminalId,
                receiptData.transactionId,
                receiptData.barcodeBitmap,
                receiptData.brandName ?: ""
            )
            PrinterType.LANDI -> PrintUtilRefactored.loadLandiBitmapFromView(
                context,
                receiptData.logoBitmap,
                receiptData.companyName,
                receiptData.address1,
                receiptData.address2,
                receiptData.address3,
                receiptData.address4,
                receiptData.transactionState1,
                receiptData.transactionState2,
                receiptData.transactionTime,
                receiptData.transactionDescription,
                receiptData.transactionTotal,
                receiptData.terminalId,
                receiptData.transactionId,
                receiptData.barcodeBitmap,
                receiptData.brandName ?: ""
            )
            PrinterType.WIZAR_POS -> PrintUtilRefactored.loadWizarBitmapFromView(
                context,
                receiptData.logoBitmap,
                receiptData.companyName,
                receiptData.address1,
                receiptData.address2,
                receiptData.address3,
                receiptData.address4,
                receiptData.transactionState1,
                receiptData.transactionState2,
                receiptData.transactionTime,
                receiptData.transactionDescription,
                receiptData.transactionTotal,
                receiptData.terminalId,
                receiptData.transactionId,
                receiptData.barcodeBitmap,
                receiptData.brandName ?: ""
            )
            else -> null
        }
    }
    
    /**
     * Create summary bitmap using PrintUtil
     */
    protected fun createSummaryBitmap(acquirer: String?, summaryData: TransactionSummary): Bitmap? {
        return when (printerType) {
            PrinterType.CASTLE -> PrintUtilRefactored.loadCastleDailySummaryReport(context, acquirer, summaryData)
            PrinterType.WIZAR_POS -> PrintUtilRefactored.loadWizarDailySummaryReport(context, acquirer, summaryData)
            else -> PrintUtilRefactored.loadAnfuDailySummaryReport(context, acquirer, summaryData)
        }
    }
    
    /**
     * Abstract method for device-specific bitmap printing
     */
    protected abstract fun printBitmapInternal(bitmap: Bitmap): Boolean
}
