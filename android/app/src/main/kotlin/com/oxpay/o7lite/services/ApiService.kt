package com.oxpay.o7lite.services

import com.oxpay.o7lite.entity.SummaryReportRequest
import com.oxpay.o7lite.entity.SummaryReportResponse
import com.oxpay.o7lite.entity.TransactionSummary
import retrofit2.Call
import retrofit2.http.Body

import retrofit2.http.POST




interface ApiService {
    @POST("v6/app/txn-summary")
    fun getSummaryReports(@Body body: SummaryReportRequest?): Call<SummaryReportResponse?>?
}