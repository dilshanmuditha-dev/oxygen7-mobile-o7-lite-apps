package com.oxpay.o7lite.models

import android.graphics.Bitmap

/**
 * Data class for receipt printing parameters
 */
data class PrintReceiptData(
    val logoBitmap: Bitmap,
    val companyName: String,
    val address1: String = "",
    val address2: String = "",
    val address3: String = "",
    val address4: String = "",
    val transactionState1: String,
    val transactionState2: String,
    val transactionTime: String,
    val transactionDescription: String,
    val transactionTotal: String,
    val terminalId: String,
    val transactionId: String,
    val barcodeBitmap: Bitmap,
    val brandName: String? = null
)
