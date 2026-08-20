package com.oxpay.o7lite.services.printers

import android.content.Context
import android.graphics.Bitmap
import android.os.RemoteException
import android.widget.Toast
import com.cloudpos.jniinterface.PrinterInterface
import com.cloudpos.sdk.printer.html.PrinterBitmapUtil
import com.oxpay.o7lite.MainApplication
import com.oxpay.o7lite.constants.PrinterConstants
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.services.base.BasePrinterService
import com.oxpay.o7lite.utils.LogUtil

/**
 * WizarPos printer service implementation
 */
class WizarPosPrinterService(context: Context) : BasePrinterService(context, PrinterType.WIZAR_POS) {
    
    override fun initialize(): Boolean {
        if (!MainApplication.isWizarPosOpen) {
            val result = PrinterInterface.open()
            
            if (result < 0) {
                Toast.makeText(context, "Initialize WizarPos printer failed", Toast.LENGTH_LONG).show()
                LogUtil.e("WizarPosPrinterService", "Printer initialization failed: $result")
                return false
            }
            
            MainApplication.isWizarPosOpen = result >= 0
            isInitialized = MainApplication.isWizarPosOpen
        } else {
            isInitialized = true
        }
        
        LogUtil.d("WizarPosPrinterService", "WizarPos printer initialized: $isInitialized")
        return isInitialized
    }
    
    override fun isReady(): Boolean {
        return isInitialized && MainApplication.isWizarPosOpen
    }
    
    override fun printBitmapInternal(bitmap: Bitmap): Boolean {
        if (!isReady()) {
            LogUtil.e("WizarPosPrinterService", "Printer not ready")
            return false
        }
        
        return try {
            PrinterBitmapUtil.printBitmap(
                bitmap,
                0,
                0,
                MainApplication.isWizarPosOpen,
                PrinterConstants.WIZAR_BITMAP_THRESHOLD
            )
            LogUtil.d("WizarPosPrinterService", "Bitmap printed successfully")
            true
        } catch (e: RemoteException) {
            Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
            LogUtil.e("WizarPosPrinterService", "Print failed: ${e.message}")
            false
        }
    }
    
    override fun cleanup() {
        if (MainApplication.isWizarPosOpen) {
            PrinterInterface.close()
            MainApplication.isWizarPosOpen = false
            isInitialized = false
            LogUtil.d("WizarPosPrinterService", "WizarPos printer cleaned up")
        }
    }
}
