package com.oxpay.o7lite.entity

data class DataEntity(
    //"acquirer": "gw3Host",
    //"currency": "SGD",
    //"endDate": "20240420000000",
    //"mcpTerminalId": "7021030011",
    //"order": "true", // default is true
    //"startDate": "20240419000000"
    val acquirer: String? = null,
    val currency: String? = null,
    val endDate: String? = null,
    val mcpTerminalId: String? = null,
//    val order: String? = null,
    val startDate: String? = null
)