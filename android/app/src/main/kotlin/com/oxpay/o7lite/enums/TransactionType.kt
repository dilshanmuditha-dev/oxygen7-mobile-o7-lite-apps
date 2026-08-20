package com.oxpay.o7lite.enums

class TransactionType {
    companion object {
        const val PREAUTH = "PREAUTH"
        const val SALE = "SALE"
        const val SALES = "SALES"
        const val REFUND = "REFUND"
        const val VOID = "VOID"
        const val VOIDED = "VOIDED"
        const val REVERSE = "REVERSE"
        const val QUICK_PAY = "QUICK_PAY"
        const val UNIFIED_ORDER = "UNIFIED_ORDER"
        const val EWALLET_VOID = "EWALLET_VOID"
        const val SUBMIT_QUICK_PAY = "SUBMIT_QUICK_PAY"
    }
}
