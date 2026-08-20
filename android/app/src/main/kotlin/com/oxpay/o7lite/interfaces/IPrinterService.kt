package com.oxpay.o7lite.interfaces

import android.graphics.Bitmap
import com.oxpay.o7lite.entity.TransactionSummary
import com.oxpay.o7lite.models.PrintReceiptData

/**
 * Interface for printer service operations
 */
interface IPrinterService {
    fun initialize(): Boolean
    fun isReady(): Boolean
    fun printReceipt(receiptData: PrintReceiptData): Boolean
    fun printSummaryReport(acquirer: String?, summaryData: TransactionSummary): Boolean
    fun printBitmap(bitmap: Bitmap): Boolean
    fun cleanup()
}
