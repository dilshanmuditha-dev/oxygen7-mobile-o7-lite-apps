package com.oxpay.o7lite.enums

/**
 * Enum for method channel operations
 */
enum class MethodChannelType(val value: String) {
    // Castle operations - MUST match Flutter side method names
    PRINT_RECEIPT_MANUAL("printCastleReceiptManual"),  // Fixed: was "printReceiptManual"
    PRINT_BITMAP("printCastle"),  // Fixed: was "printBitmap"
    PRINT_SUMMARY_REPORT("printCastleSummary"),  // Fixed: was "printSummaryReport"
    
    // Device-specific operations
    PRINT_ANFU_RECEIPT_MANUAL("printAnfuReceiptManual"),
    PRINT_ANFU_SUMMARY("printAnfuSummary"),
    PRINT_SUNMI_SUMMARY("printSunmiSummary"),
    PRINT_LANDI_RECEIPT_MANUAL("printLandiReceiptManual"),
    PRINT_LANDI_SUMMARY("printLandiSummary"),
    PRINT_WIZAR_POS_RECEIPT_MANUAL("printWizarPosReceiptManual"),
    PRINT_WIZAR_POS_SUMMARY("printWizarPosSummary"),
    PRINT_COHERENT_RECEIPT_MANUAL("printCoherentReceiptManual"),
    PRINT_COHERENT_SUMMARY("printCoherentSummary"),
    PRINT_MOREFUN_RECEIPT_MANUAL("printMorefunReceiptManual"),
    PRINT_MOREFUN_SUMMARY("printMorefunSummary"),
    PRINT_MOREFUN_TEST("printMorefunTest"),
    
    // MineSoftPOS operations
    MINESOFTPOS_INITIALIZE("initialize"),
    MINESOFTPOS_PROCESS_CARD_PAYMENT("processCardPayment"),
    MINESOFTPOS_IS_READY("isReady"),
    
    // System operations
    ENCRYPTION_SHA512("encryptionSHA512"),
    GET_UPTIME("getUptime"),
    OPEN_WIZARPOS_CARD_PAYMENT_APP("openWizarPosCardPaymentApp");
    
    companion object {
        fun fromValue(value: String): MethodChannelType? {
            return values().find { it.value == value }
        }
    }
}
