package com.oxpay.o7lite.constants

/**
 * Constants for printer operations
 */
object PrinterConstants {
    // Printer specifications
    const val MAX_BIT_WIDTH = 384
    const val DEFAULT_HEAT_LEVEL = 6
    const val BARCODE_HEAT_LEVEL = 2
    const val BITMAP_HEAT_LEVEL = 4
    
    // Layout multipliers
    const val RECEIPT_HEIGHT_MULTIPLIER = 1.15
    const val BITMAP_HEIGHT_MULTIPLIER = 1.35
    const val SUMMARY_HEIGHT_MULTIPLIER = 1.3
    const val BARCODE_POSITION_X_MULTIPLIER = 0.33
    const val BARCODE_POSITION_Y_MULTIPLIER = 1.02
    
    // Retry configuration
    const val MAX_RETRY_COUNT = 3
    
    // Network timeout
    const val CONNECT_TIMEOUT_SECONDS = 30L
    const val READ_TIMEOUT_SECONDS = 30L
    const val WRITE_TIMEOUT_SECONDS = 30L
    
    // Print quality settings
    const val SUNMI_BITMAP_WIDTH = 384
    const val SUNMI_JPEG_QUALITY = 90
    const val WIZAR_BITMAP_THRESHOLD = 128
}
