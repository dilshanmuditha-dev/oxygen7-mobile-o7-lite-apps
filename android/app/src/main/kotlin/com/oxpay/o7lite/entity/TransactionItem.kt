package com.oxpay.o7lite.entity

data class TransactionItem(
    val type: String? = null,
    val responseCode: String? = null,
    val currency: String? = null,
    val brandName: String? = null,
    val gatewayResponseDate: String? = null,
    val mcpTerminalId: String? = null,
    val totalAmount: Double? = null,
)
