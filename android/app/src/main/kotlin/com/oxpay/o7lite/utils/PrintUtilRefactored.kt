package com.oxpay.o7lite.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.core.graphics.createBitmap
import androidx.core.graphics.get
import com.oxpay.o7lite.R
import com.oxpay.o7lite.constants.PrinterConstants
import com.oxpay.o7lite.entity.TransactionSummary
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.extensions.textOrGoneIgnoreNull
import com.oxpay.o7lite.extensions.textOrGoneTrimmed
import com.oxpay.o7lite.models.PrintReceiptData
import com.oxpay.o7lite.utils.Utils.toDollars

object PrintUtilRefactored {

    private const val MAX_BIT_WIDTH = PrinterConstants.MAX_BIT_WIDTH

    /**
     * Convert bitmap to byte array for printer
     */
    fun getBitmapData(bitmap: Bitmap): ByteArray {
        var width = bitmap.width
        val height = bitmap.height
        if (width > MAX_BIT_WIDTH) width = MAX_BIT_WIDTH
        val bitWidth = getPaddingBitWidth(width)
        val pitch = bitWidth / 8
        val bits = ByteArray(pitch * height)

        for (y in 0 until height) {
            for (x in 0 until width) {
                val color = bitmap[x, y]
                if (color and 0xFF < 128) {
                    bits[y * pitch + x / 8] =
                        (bits[y * pitch + x / 8].toInt() or (0x80 shr x % 8).toByte()
                            .toInt()).toByte()
                }
            }
        }
        return bits
    }

    /**
     * Get empty data array for padding
     */
    fun getEmptyData(width: Int, height: Int): ByteArray {
        var adjustedWidth = width
        if (adjustedWidth > MAX_BIT_WIDTH) adjustedWidth = MAX_BIT_WIDTH
        val bitWidth = getPaddingBitWidth(adjustedWidth)
        val pitch = bitWidth / 8
        return ByteArray(pitch * height)
    }

    /**
     * Calculate padding bit width
     */
    fun getPaddingBitWidth(width: Int): Int {
        return (width + 7) / 8 * 8
    }

    /**
     * Create receipt bitmap for any printer type
     */
    fun createReceiptBitmap(
        context: Context,
        printerType: PrinterType,
        receiptData: PrintReceiptData
    ): Bitmap? {
        val layoutResource = getReceiptLayoutResource(printerType)
        return createBitmapFromLayout(context, layoutResource) { view ->
            bindReceiptData(view, receiptData)
        }
    }

    /**
     * Create summary report bitmap for any printer type
     */
    fun createSummaryBitmap(
        context: Context,
        printerType: PrinterType,
        acquirer: String?,
        summaryData: TransactionSummary
    ): Bitmap? {
        val layoutResource = getSummaryLayoutResource(printerType)
        return createBitmapFromLayout(context, layoutResource) { view ->
            bindSummaryData(view, acquirer, summaryData)
        }
    }

    /**
     * Generic method to create bitmap from layout
     */
    private fun createBitmapFromLayout(
        context: Context,
        layoutResource: Int,
        bindData: (View) -> Unit
    ): Bitmap? {
        return try {
            val view: View = LayoutInflater.from(context).inflate(layoutResource, null, false)
            bindData(view)

            view.measure(
                View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
                View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
            )
            view.layout(0, 0, view.measuredWidth, view.measuredHeight)

            val bitmap = createBitmap(view.measuredWidth, view.measuredHeight)
            val canvas = Canvas(bitmap)
            view.draw(canvas)
            bitmap
        } catch (e: Exception) {
            LogUtil.e("PrintUtilRefactored", "Failed to create bitmap: ${e.message}")
            null
        }
    }

    /**
     * Bind receipt data to view
     */
    private fun bindReceiptData(view: View, receiptData: PrintReceiptData) {
        val ivLogo = view.findViewById<ImageView>(R.id.ivLogo)
        val tvCompanyName = view.findViewById<TextView>(R.id.tvOxpaySg)
        val tvAddress1 = view.findViewById<TextView>(R.id.tvAddress1)
        val tvAddress2 = view.findViewById<TextView>(R.id.tvAddress2)
        val tvAddress3 = view.findViewById<TextView>(R.id.tvAddress3)
        val tvAddress4 = view.findViewById<TextView>(R.id.tvAddress4)
        val tvPaymentType = view.findViewById<TextView>(R.id.tvPaymentType)
        val tvStatus = view.findViewById<TextView>(R.id.tvStatus)
        val tvDateTime = view.findViewById<TextView>(R.id.tvDateTime)
        val tvDescription = view.findViewById<TextView>(R.id.tvDescription)
        val tvPrice = view.findViewById<TextView>(R.id.tvPrice)
        val tvTID = view.findViewById<TextView>(R.id.tvTID)
        val tvTnxID = view.findViewById<TextView>(R.id.tvTnxID)
        val ivQRCode = view.findViewById<ImageView>(R.id.ivQRCode)


        if (receiptData.brandName.isNullOrEmpty()) {
            ivLogo?.setImageBitmap(receiptData.logoBitmap)
        } else {
            ivLogo?.setImageResource(Utils.brandImage(receiptData.brandName))
        }

        tvCompanyName?.textOrGoneTrimmed = receiptData.companyName
        tvAddress1?.textOrGoneTrimmed = receiptData.address1
        tvAddress2?.textOrGoneTrimmed = receiptData.address2
        tvAddress3?.textOrGoneTrimmed = receiptData.address3
        tvAddress4?.textOrGoneTrimmed = receiptData.address4

        tvPaymentType?.textOrGoneIgnoreNull = receiptData.transactionState1
        tvStatus?.textOrGoneIgnoreNull = receiptData.transactionState2
        tvDateTime?.textOrGoneIgnoreNull = receiptData.transactionTime
        tvDescription?.textOrGoneIgnoreNull = receiptData.transactionDescription
        tvPrice?.textOrGoneIgnoreNull = receiptData.transactionTotal
        tvTID?.textOrGoneIgnoreNull = receiptData.terminalId
        tvTnxID?.textOrGoneIgnoreNull = receiptData.transactionId

        ivQRCode?.setImageBitmap(receiptData.barcodeBitmap)
    }

    /**
     * Bind summary data to view
     */
    private fun bindSummaryData(view: View, acquirer: String?, summaryData: TransactionSummary) {
        val firstTransaction = summaryData.transactionList?.firstOrNull()

        view.findViewById<ImageView>(R.id.ivLogo)?.let { logoView ->
            val brandLogo = Utils.brandImage(firstTransaction?.brandName)
            logoView.setImageResource(brandLogo)
        }

        view.findViewById<TextView>(R.id.tvTitle)?.text = acquirer
        view.findViewById<TextView>(R.id.tvDate)?.text =
            Utils.convertDDMMYYYY(firstTransaction?.gatewayResponseDate)
        view.findViewById<TextView>(R.id.tvTID)?.text = firstTransaction?.mcpTerminalId ?: "-"
        view.findViewById<TextView>(R.id.tvTxnAmount)?.text = summaryData.totalPayAmount.toDollars()
        view.findViewById<TextView>(R.id.tvTxnCount)?.text = summaryData.totalPayCount.toString()

        // Void views
        val llVoidSection = view.findViewById<View>(R.id.llVoidCount)
        val llVoidAmount = view.findViewById<View>(R.id.llVoidAmount)
        val tvVoidAmount = view.findViewById<TextView>(R.id.tvVoidAmount)
        val tvVoidCount = view.findViewById<TextView>(R.id.tvVoidCount)

        // Refund views
        val llRefundSection = view.findViewById<View>(R.id.llRefundCount)
        val llRefundAmount = view.findViewById<View>(R.id.llRefundAmount)
        val tvRefundAmount = view.findViewById<TextView>(R.id.tvRefundAmount)
        val tvRefundCount = view.findViewById<TextView>(R.id.tvRefundCount)

        val totalRefundCount = summaryData.totalRefundCount ?: 0
        val totalRefundAmount = summaryData.totalRefundAmount ?: 0.0

        val totalVoidCount = summaryData.totalVoidCount ?: 0
        val totalVoidAmount = summaryData.totalVoidAmount ?: 0.0

        if (totalRefundCount > 0) {
            llRefundSection.visibility = View.VISIBLE
            llRefundAmount.visibility = View.VISIBLE
            tvRefundAmount?.text = totalRefundAmount.toDollars()
            tvRefundCount?.text = totalRefundCount.toString()
        } else {
            llVoidSection.visibility = View.VISIBLE
            llVoidAmount.visibility = View.VISIBLE
            tvVoidAmount.text = totalVoidAmount.toDollars()
            tvVoidCount.text = totalVoidCount.toString()
        }

        // Set up RecyclerView if present
        view.findViewById<androidx.recyclerview.widget.RecyclerView>(R.id.rvTransactionList)
            ?.let { recyclerView ->
                val adapter = TransactionSummaryAdapter(view.context, summaryData.transactionList)
                recyclerView.adapter = adapter
            }
    }

    /**
     * Get layout resource for receipt based on printer type
     */
    private fun getReceiptLayoutResource(printerType: PrinterType): Int {
        return when (printerType) {
            PrinterType.CASTLE -> R.layout.castle_receipt
            PrinterType.ANFU -> R.layout.anfu_receipt
            PrinterType.SUNMI -> R.layout.anfu_receipt // Sunmi uses ANFU layout
            PrinterType.LANDI -> R.layout.anfu_receipt // Landi uses ANFU layout
            PrinterType.WIZAR_POS -> R.layout.wizar_receipt
            PrinterType.COHERENT -> R.layout.anfu_receipt // Coherent uses ANFU layout
            PrinterType.MOREFUN -> R.layout.anfu_receipt // Morefun uses ANFU layout
        }
    }

    /**
     * Get layout resource for summary based on printer type
     */
    private fun getSummaryLayoutResource(printerType: PrinterType): Int {
        return when (printerType) {
            PrinterType.CASTLE -> R.layout.castle_summary_report
            PrinterType.WIZAR_POS -> R.layout.wizar_summary_report
            else -> R.layout.anfu_summary_report
        }
    }

    // Backwards compatibility methods - delegate to new implementation
    fun loadBitmapFromView(
        context: Context,
        logoBitMap: Bitmap,
        stringCompany: String,
        address1: String?,
        address2: String?,
        address3: String?,
        address4: String?,
        txnState1: String,
        txnState2: String,
        txnTime: String,
        txnDescription: String,
        txnTotal: String,
        terminalID: String,
        txnID: String,
        txnBarCode: Bitmap,
        brandName : String
    ): Bitmap? {
        val receiptData = PrintReceiptData(
            logoBitmap = logoBitMap,
            companyName = stringCompany,
            address1 = address1 ?: "",
            address2 = address2 ?: "",
            address3 = address3 ?: "",
            address4 = address4 ?: "",
            transactionState1 = txnState1,
            transactionState2 = txnState2,
            transactionTime = txnTime,
            transactionDescription = txnDescription,
            transactionTotal = txnTotal,
            terminalId = terminalID,
            transactionId = txnID,
            barcodeBitmap = txnBarCode,
            brandName = brandName
        )
        return createReceiptBitmap(context, PrinterType.CASTLE, receiptData)
    }

    fun loadANFUBitmapFromView(
        context: Context,
        logoBitMap: Bitmap,
        stringCompany: String,
        address1: String?,
        address2: String?,
        address3: String?,
        address4: String?,
        txnState1: String,
        txnState2: String,
        txnTime: String,
        txnDescription: String,
        txnTotal: String,
        terminalID: String,
        txnID: String,
        txnBarCode: Bitmap,
        brandName : String
    ): Bitmap? {
        val receiptData = PrintReceiptData(
            logoBitmap = logoBitMap,
            companyName = stringCompany,
            address1 = address1 ?: "",
            address2 = address2 ?: "",
            address3 = address3 ?: "",
            address4 = address4 ?: "",
            transactionState1 = txnState1,
            transactionState2 = txnState2,
            transactionTime = txnTime,
            transactionDescription = txnDescription,
            transactionTotal = txnTotal,
            terminalId = terminalID,
            transactionId = txnID,
            barcodeBitmap = txnBarCode,
            brandName = brandName
        )
        return createReceiptBitmap(context, PrinterType.ANFU, receiptData)
    }

    fun loadLandiBitmapFromView(
        context: Context,
        logoBitMap: Bitmap,
        stringCompany: String,
        address1: String?,
        address2: String?,
        address3: String?,
        address4: String?,
        txnState1: String,
        txnState2: String,
        txnTime: String,
        txnDescription: String,
        txnTotal: String,
        terminalID: String,
        txnID: String,
        txnBarCode: Bitmap,
        brandName : String
    ): Bitmap? {
        val receiptData = PrintReceiptData(
            logoBitmap = logoBitMap,
            companyName = stringCompany,
            address1 = address1 ?: "",
            address2 = address2 ?: "",
            address3 = address3 ?: "",
            address4 = address4 ?: "",
            transactionState1 = txnState1,
            transactionState2 = txnState2,
            transactionTime = txnTime,
            transactionDescription = txnDescription,
            transactionTotal = txnTotal,
            terminalId = terminalID,
            transactionId = txnID,
            barcodeBitmap = txnBarCode,
            brandName = brandName
        )
        return createReceiptBitmap(context, PrinterType.LANDI, receiptData)
    }

    fun loadWizarBitmapFromView(
        context: Context,
        logoBitMap: Bitmap,
        stringCompany: String,
        address1: String?,
        address2: String?,
        address3: String?,
        address4: String?,
        txnState1: String,
        txnState2: String,
        txnTime: String,
        txnDescription: String,
        txnTotal: String,
        terminalID: String,
        txnID: String,
        txnBarCode: Bitmap,
        brandName : String
    ): Bitmap? {
        val receiptData = PrintReceiptData(
            logoBitmap = logoBitMap,
            companyName = stringCompany,
            address1 = address1 ?: "",
            address2 = address2 ?: "",
            address3 = address3 ?: "",
            address4 = address4 ?: "",
            transactionState1 = txnState1,
            transactionState2 = txnState2,
            transactionTime = txnTime,
            transactionDescription = txnDescription,
            transactionTotal = txnTotal,
            terminalId = terminalID,
            transactionId = txnID,
            barcodeBitmap = txnBarCode,
            brandName = brandName
        )
        return createReceiptBitmap(context, PrinterType.WIZAR_POS, receiptData)
    }

    fun loadCastleDailySummaryReport(
        context: Context,
        acquirer: String?,
        summaryData: TransactionSummary
    ): Bitmap? {
        return createSummaryBitmap(context, PrinterType.CASTLE, acquirer, summaryData)
    }

    fun loadAnfuDailySummaryReport(
        context: Context,
        acquirer: String?,
        summaryData: TransactionSummary
    ): Bitmap? {
        return createSummaryBitmap(context, PrinterType.ANFU, acquirer, summaryData)
    }

    fun loadWizarDailySummaryReport(
        context: Context,
        acquirer: String?,
        summaryData: TransactionSummary
    ): Bitmap? {
        return createSummaryBitmap(context, PrinterType.WIZAR_POS, acquirer, summaryData)
    }
}
