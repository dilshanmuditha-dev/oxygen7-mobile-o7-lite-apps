package com.oxpay.o7lite.services.printers

import android.content.Context
import android.graphics.Bitmap
import android.os.RemoteException
import android.widget.Toast
import com.oxpay.o7lite.MainApplication
import com.oxpay.o7lite.constants.PrinterConstants
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.services.base.BasePrinterService
import com.oxpay.o7lite.utils.LogUtil
import com.oxpay.o7lite.utils.landi.LandiPrinterService as LandiPrinterUtil
import com.sdksuite.omnidriver.OmniConnection
import com.sdksuite.omnidriver.OmniDriver

/**
 * Landi printer service implementation
 */
class LandiPrinterService(context: Context) : BasePrinterService(context, PrinterType.LANDI) {
    
    private var retryCount = 0
    
    override fun initialize(): Boolean {
        var result: String
        MainApplication.getOmniDriver().init(object : OmniConnection {
            override fun onConnected() {
                result = "initOmniDriver--->onSuccess"
                isInitialized = true
                LogUtil.d("LandiPrinterService", result)
            }
            
            override fun onDisconnected(error: Int) {
                result = "initOmniDriver--->onError:error=$error"
                isInitialized = false
                LogUtil.e("LandiPrinterService", result)
                
                if (error == OmniDriver.ERROR_BIND_FAIL) {
                    LogUtil.e("LandiPrinterService", "Please confirm whether it is installed OmniDriver service")
                    return
                }
                
                if (retryCount < PrinterConstants.MAX_RETRY_COUNT) {
                    retryCount++
                    initialize()
                }
            }
        })
        return true
    }
    
    override fun printBitmapInternal(bitmap: Bitmap): Boolean {
        if (!isInitialized) {
            LogUtil.e("LandiPrinterService", "Printer not initialized")
            return false
        }
        
        return try {
            val landiPrinterUtil = LandiPrinterUtil(bitmap)
            landiPrinterUtil.startPrinter()
            LogUtil.d("LandiPrinterService", "Bitmap printed successfully")
            true
        } catch (e: RemoteException) {
            Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
            LogUtil.e("LandiPrinterService", "Print failed: ${e.message}")
            false
        }
    }
    
    override fun cleanup() {
        if (isInitialized) {
            MainApplication.getOmniDriver().destroy()
            isInitialized = false
            LogUtil.d("LandiPrinterService", "Landi printer cleaned up")
        }
    }
}
