package com.oxpay.o7lite.services.printers

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.graphics.Bitmap
import android.os.IBinder
import android.os.RemoteException
import android.widget.Toast
import com.centerm.smartpos.aidl.printer.AidlPrinter
import com.centerm.smartpos.aidl.printer.PrinterParams
import com.centerm.smartpos.aidl.sys.AidlDeviceManager
import com.centerm.smartpos.constant.Constant
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.services.base.BasePrinterService
import com.oxpay.o7lite.utils.LogUtil

/**
 * Coherent POS printer service implementation using AIDL service binding.
 * Communicates with Centerm SmartPOS service to control the thermal printer.
 */
class CoherentPrinterService(context: Context) : BasePrinterService(context, PrinterType.COHERENT) {

    companion object {
        private const val TAG = "CoherentPrinterService"
        private const val LOG_PREFIX = "COHERENT:::"
        private const val SERVICE_PACKAGE = "com.centerm.smartposservice"
        private const val SERVICE_ACTION = "com.centerm.smartpos.service.MANAGER_SERVICE"
    }

    private var deviceManager: AidlDeviceManager? = null
    private var printDev: AidlPrinter? = null
    private var isServiceBound = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceDisconnected(name: ComponentName) {
            isServiceBound = false
            deviceManager = null
            printDev = null
            isInitialized = false
            LogUtil.d(TAG, "$LOG_PREFIX Service disconnected")
        }

        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            isServiceBound = true
            deviceManager = AidlDeviceManager.Stub.asInterface(service)
            LogUtil.d(TAG, "$LOG_PREFIX Service connected, manager=$deviceManager")

            if (deviceManager != null) {
                try {
                    printDev = AidlPrinter.Stub.asInterface(
                        deviceManager?.getDevice(Constant.DEVICE_TYPE.DEVICE_TYPE_PRINTERDEV)
                    )
                    isInitialized = true
                    LogUtil.d(TAG, "$LOG_PREFIX Printer device obtained: $printDev")
                } catch (e: RemoteException) {
                    LogUtil.e(TAG, "$LOG_PREFIX Failed to get printer device: ${e.message}")
                }
            }
        }
    }

    override fun initialize(): Boolean {
        return try {
            val intent = Intent()
            intent.setPackage(SERVICE_PACKAGE)
            intent.setAction(SERVICE_ACTION)
            context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
            LogUtil.d(TAG, "$LOG_PREFIX Printer service binding initiated")
            true
        } catch (e: Exception) {
            LogUtil.e(TAG, "$LOG_PREFIX Failed to initialize: ${e.message}")
            false
        }
    }

    override fun isReady(): Boolean {
        return isInitialized && isServiceBound && printDev != null
    }

    /**
     * Get the current printer state from the Centerm SDK.
     * Returns the raw state code from AidlPrinter.getPrinterState().
     * State 0 typically means ready/connected.
     */
    fun getPrinterState(): Int {
        return try {
            printDev?.printerState ?: -1
        } catch (e: RemoteException) {
            LogUtil.e(TAG, "$LOG_PREFIX Failed to get printer state: ${e.message}")
            -1
        }
    }

    override fun printBitmapInternal(bitmap: Bitmap): Boolean {
        if (printDev == null) {
            Toast.makeText(context, "printer_service_is_not_connected", Toast.LENGTH_SHORT).show()
            LogUtil.e(TAG, "$LOG_PREFIX Printer not available")
            return false
        }

        return try {
            // Use the SDK's native bitmap printing via printBmpFastSync.
            // Parameter 2 is alignment: 0=LEFT, 1=CENTER, 2=RIGHT
            val result = printDev?.printBmpFastSync(bitmap, 0) ?: -1
            if (result == 0) {
                // Feed paper after printing to ensure receipt is fully visible
                printDev?.spitPaper(80)
                LogUtil.d(TAG, "$LOG_PREFIX Print success via printBmpFastSync, bitmap ${bitmap.width}x${bitmap.height}")
                true
            } else {
                LogUtil.e(TAG, "$LOG_PREFIX printBmpFastSync returned error code: $result")
                // Fallback: try PrinterParams with IMAGE datatype
                printBitmapViaParams(bitmap)
            }
        } catch (e: RemoteException) {
            LogUtil.e(TAG, "$LOG_PREFIX printBmpFastSync failed: ${e.message}, trying fallback")
            // Fallback: try PrinterParams with IMAGE datatype
            printBitmapViaParams(bitmap)
        }
    }

    /**
     * Fallback bitmap printing using PrinterParams with IMAGE datatype.
     * Used when printBmpFastSync is not available or fails.
     */
    private fun printBitmapViaParams(bitmap: Bitmap): Boolean {
        return try {
            val list = ArrayList<PrinterParams>()
            val params = PrinterParams()
            params.setDataType(PrinterParams.DATATYPE.IMAGE)
            params.setBitmap(bitmap)
            params.setAlign(PrinterParams.ALIGN.CENTER)
            list.add(params)

            // Add paper feed after the image
            val feedParams = PrinterParams()
            feedParams.setDataType(PrinterParams.DATATYPE.FEED_LINE)
            feedParams.setFeedlineNum(4)
            list.add(feedParams)

            val result = printDev?.printData(list) ?: -1
            LogUtil.d(TAG, "$LOG_PREFIX Print via PrinterParams IMAGE, result=$result, bitmap ${bitmap.width}x${bitmap.height}")
            result == 0
        } catch (e: RemoteException) {
            Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
            LogUtil.e(TAG, "$LOG_PREFIX Fallback print also failed: ${e.message}")
            false
        }
    }

    override fun cleanup() {
        if (isServiceBound) {
            try {
                context.unbindService(serviceConnection)
                LogUtil.d(TAG, "$LOG_PREFIX Printer service unbound")
            } catch (e: Exception) {
                LogUtil.e(TAG, "$LOG_PREFIX Cleanup error: ${e.message}")
            }
        }
        isServiceBound = false
        isInitialized = false
        deviceManager = null
        printDev = null
    }
}
