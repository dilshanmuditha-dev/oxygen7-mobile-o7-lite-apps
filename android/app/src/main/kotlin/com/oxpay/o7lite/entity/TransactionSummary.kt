package com.oxpay.o7lite.entity

data class TransactionSummary(
    val totalCount: Int? = 0,
    val totalPayAmount: Double? = 0.0,
    val totalPayCount: Int? = 0,
    val totalVoidAmount: Double? = 0.0,
    val totalVoidCount: Int? = 0,
    val totalRefundAmount: Double? = 0.0,
    val totalRefundCount: Int? = 0,
    var transactionList : List<TransactionItem>? = null
)
