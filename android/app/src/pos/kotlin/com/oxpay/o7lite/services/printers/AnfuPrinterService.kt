package com.oxpay.o7lite.services.printers

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.graphics.Bitmap
import android.os.IBinder
import android.os.RemoteException
import android.widget.Toast
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.services.base.BasePrinterService
import com.oxpay.o7lite.utils.LogUtil
import com.oxpay.o7lite.utils.PrintUtilRefactored
import com.szanfu.sdk.api.ISdkServiceManager
import com.szanfu.sdk.api.constant.ServiceID
import com.szanfu.sdk.api.error.ErrorCode
import com.szanfu.sdk.api.printer.IPrinterBinderService
import com.szanfu.sdk.api.printer.IPrinterCallback

/**
 * ANFU printer service implementation
 */
class AnfuPrinterService(context: Context) : BasePrinterService(context, PrinterType.ANFU) {
    
    private var mAnfuSdkServiceManager: ISdkServiceManager? = null
    private var mAnfuPrinterBinderService: IPrinterBinderService? = null
    private var isServiceBound = false
    
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceDisconnected(name: ComponentName) {
            isServiceBound = false
            mAnfuSdkServiceManager = null
            LogUtil.d("AnfuPrinterService", "sdk_binder_service_disconnected")
        }
        
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            isServiceBound = true
            mAnfuSdkServiceManager = ISdkServiceManager.Stub.asInterface(service)
            if (mAnfuSdkServiceManager != null) {
                try {
                    mAnfuSdkServiceManager?.asBinder()?.linkToDeath({
                        LogUtil.d("AnfuPrinterService", "sdk_binder_service_binderdied")
                        initialize()
                    }, 0)
                    
                    mAnfuPrinterBinderService = IPrinterBinderService.Stub.asInterface(
                        mAnfuSdkServiceManager?.getService(ServiceID.SERVICE_ID_PRINTER)
                    )
                    isInitialized = true
                } catch (e: RemoteException) {
                    LogUtil.e("AnfuPrinterService", "RemoteException: ${e.message}")
                    LogUtil.e("AnfuPrinterService", "Service connection error: ${e.message}")
                }
            }
        }
    }
    
    override fun initialize(): Boolean {
        return try {
            val intent = Intent()
            intent.setPackage("com.szanfu.sdk.service")
            intent.setAction("com.szanfu.sdk.service.SDK_SERVICE")
            context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
            LogUtil.d("AnfuPrinterService", "ANFU printer service binding initiated")
            true
        } catch (e: Exception) {
            LogUtil.e("AnfuPrinterService", "Failed to initialize: ${e.message}")
            false
        }
    }
    
    override fun isReady(): Boolean {
        return isInitialized && isServiceBound && mAnfuPrinterBinderService != null
    }
    
    override fun printBitmapInternal(bitmap: Bitmap): Boolean {
        if (mAnfuPrinterBinderService == null) {
            Toast.makeText(context, "printer_service_is_not_connected", Toast.LENGTH_SHORT).show()
            return false
        }
        
        return try {
            val x = 0
            val width = bitmap.width
            val height = bitmap.height
            val bitW = PrintUtilRefactored.getPaddingBitWidth(width)
            val bitmapData = PrintUtilRefactored.getBitmapData(bitmap)
            
            var printResult = false
            
            mAnfuPrinterBinderService?.printBitmap(
                x,
                bitmapData,
                bitW,
                height,
                object : IPrinterCallback.Stub() {
                    override fun onResult(errorCode: Int, errorMsg: String, subErrorCode: Int) {
                        if (errorCode == ErrorCode.SUCCESS) {
                            Toast.makeText(context, "Printed Successfully", Toast.LENGTH_SHORT).show()
                            printResult = true
                        } else {
                            Toast.makeText(context, "Printed failed: $errorMsg", Toast.LENGTH_SHORT).show()
                            printResult = false
                        }
                    }
                })
            
            LogUtil.d("AnfuPrinterService", "Print command sent")
            true
        } catch (e: RemoteException) {
            LogUtil.e("AnfuPrinterService", "RemoteException: ${e.message}")
            Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
            LogUtil.e("AnfuPrinterService", "Print failed: ${e.message}")
            false
        }
    }
    
    override fun cleanup() {
        if (isServiceBound) {
            try {
                context.unbindService(serviceConnection)
                isServiceBound = false
                isInitialized = false
                LogUtil.d("AnfuPrinterService", "ANFU printer service unbound")
            } catch (e: Exception) {
                LogUtil.e("AnfuPrinterService", "Cleanup error: ${e.message}")
            }
        }
    }
}
