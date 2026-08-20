package com.oxpay.o7lite.services.printers

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.oxpay.o7lite.constants.PrinterConstants
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.services.base.BasePrinterService
import com.oxpay.o7lite.utils.LogUtil
import com.oxpay.o7lite.utils.sunmi_printer.BytesUtil
import com.oxpay.o7lite.utils.sunmi_printer.SunmiPrintHelper
import java.io.ByteArrayOutputStream

/**
 * Sunmi printer service implementation
 */
class SunmiPrinterService(context: Context) : BasePrinterService(context, PrinterType.SUNMI) {
    
    override fun initialize(): Boolean {
        isInitialized = true
        LogUtil.d("SunmiPrinterService", "Sunmi printer initialized")
        return true
    }
    
    override fun printBitmapInternal(bitmap: Bitmap): Boolean {
        return try {
            Log.d("SunmiPrinterService", "Bitmap loaded successfully")
            val resizedBitmap = BytesUtil.getResizedBitmap(
                bitmap,
                (bitmap.height * PrinterConstants.SUNMI_BITMAP_WIDTH / bitmap.width),
                PrinterConstants.SUNMI_BITMAP_WIDTH
            )
            Log.d("SunmiPrinterService", "Bitmap resized successfully")
            
            val stream = ByteArrayOutputStream()
            resizedBitmap.compress(Bitmap.CompressFormat.JPEG, PrinterConstants.SUNMI_JPEG_QUALITY, stream)
            Log.d("SunmiPrinterService", "Bitmap compressed successfully")
            
            SunmiPrintHelper.instance.printBitmap(resizedBitmap, 0)
            LogUtil.d("SunmiPrinterService", "Bitmap printed successfully")
            true
        } catch (e: Exception) {
            LogUtil.e("SunmiPrinterService", "Failed to print bitmap: ${e.message}")
            false
        }
    }
    
    override fun cleanup() {
        isInitialized = false
        LogUtil.d("SunmiPrinterService", "Sunmi printer cleaned up")
    }
}
