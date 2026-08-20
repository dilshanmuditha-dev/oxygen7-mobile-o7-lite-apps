package com.oxpay.o7lite.enums

/**
 * Enum for different printer types supported by the application
 */
enum class PrinterType(val deviceType: String, val layoutResource: String) {
    CASTLE("castle", "castle_receipt"),
    ANFU("anfu", "anfu_receipt"),
    SUNMI("sunmi", "anfu_receipt"), // Sunmi uses ANFU layout
    LANDI("landi", "anfu_receipt"), // Landi uses ANFU layout
    WIZAR_POS("wizarpos", "wizar_receipt"),
    COHERENT("coherent", "anfu_receipt"),
    MOREFUN("morefun", "anfu_receipt"); // Morefun uses ANFU layout
    
    companion object {
        fun fromDeviceType(deviceType: String): PrinterType? {
            return values().find { it.deviceType.equals(deviceType, ignoreCase = true) }
        }
        
        fun getSummaryLayoutResource(printerType: PrinterType): String {
            return when (printerType) {
                CASTLE -> "castle_summary_report"
                WIZAR_POS -> "wizar_summary_report"
                else -> "anfu_summary_report"
            }
        }
    }
}
