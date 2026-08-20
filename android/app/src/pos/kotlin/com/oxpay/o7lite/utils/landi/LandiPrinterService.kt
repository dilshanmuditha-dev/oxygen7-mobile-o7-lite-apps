package com.oxpay.o7lite.utils.landi

import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import com.oxpay.o7lite.MainApplication
import com.sdksuite.omnidriver.aidl.printer.ASCScale
import com.sdksuite.omnidriver.aidl.printer.ASCSize
import com.sdksuite.omnidriver.aidl.printer.Align
import com.sdksuite.omnidriver.aidl.printer.HZScale
import com.sdksuite.omnidriver.aidl.printer.HZSize
import com.sdksuite.omnidriver.api.KeyConst
import com.sdksuite.omnidriver.api.OnPrintListener
import com.sdksuite.omnidriver.api.Printer
import com.sdksuite.omnidriver.api.PrinterException
import java.io.ByteArrayOutputStream


class LandiPrinterService(val bitmap: Bitmap) {
    companion object {
        private const val TAG = "LandiPrinterService"
        private const val MAX_WIDTH = 384
    }

    private var printer: Printer? = null
    
    // Helper to show toast on UI thread
    private fun showToast(message: String) {
        //Handler(Looper.getMainLooper()).post {
        //   Toast.makeText(MainApplication.getApplicationContext(), message, Toast.LENGTH_LONG).show()
        // }
        Log.d(TAG, "TOAST: $message")
    }

    init {
        showToast("LandiPrinterService: isLandiConnected=${MainApplication.isLandiConnected}")
        showToast("LandiPrinterService: Getting printer from OmniDriver...")
        try {
            printer = MainApplication.getOmniDriver().getPrinter(Bundle())
            showToast("LandiPrinterService: printer=${if (printer != null) "OK" else "NULL"}")
        } catch (e: Exception) {
            showToast("LandiPrinterService: getPrinter EXCEPTION: ${e.message}")
            Log.e(TAG, "getPrinter exception", e)
        }
    }

    fun startPrinter() {
        showToast("startPrinter() called, printer=${if (printer != null) "OK" else "NULL"}")
        Log.d(TAG, "LANDI_SUMMARY: startPrinter() - original bitmap: ${bitmap.width}x${bitmap.height}")
        
        if (printer == null) {
            showToast("ERROR: Printer is NULL, cannot print!")
            Log.e(TAG, "LANDI_SUMMARY: ERROR - printer is NULL")
            return
        }
        
        try {
            showToast("Calling openDevice()...")
            openDevice()
            
            Log.i(TAG, "*********** startPrinter ***********")
            showToast("Getting printer status...")
            val status = getStatus()
            Log.i(TAG, "printer status--->$status")
            Log.d(TAG, "LANDI_SUMMARY: printer status=$status")
            showToast("Printer status: $status")

            showToast("Setting printer format...")
            printer?.setGray(8)
            //Print multiple lines and automatically wrap (0x4801), if there are more than one line, the excess text will be removed and only one line will be printed (0x4800).
            printer?.setFormat(0x0800, 0x4801)
            //Print the digit 0 without a slash (0x01), by default, the slash is present (0x00).
            printer?.setFormat(0x4000, 0x01)

            printer?.setFormat(Bundle().apply {
                putInt(KeyConst.PRINTER_ASC_SIZE, ASCSize.DOT24x12)
                putInt(KeyConst.PRINTER_ASC_SCALE, ASCScale.SC1x3)
                putInt(KeyConst.PRINTER_HZ_SIZE, HZSize.DOT24x24)
                putInt(KeyConst.PRINTER_HZ_SCALE, HZScale.SC1x3)
            })

            showToast("Converting bitmap to bytes...")
            val imageByteArray = getImageBytes(bitmap)
            showToast("Image bytes size: ${imageByteArray.size}")
            Log.d(TAG, "LANDI_SUMMARY: imageByteArray size=${imageByteArray.size}")
            
            if (imageByteArray.isEmpty()) {
                Log.e(TAG, "LANDI_SUMMARY: ERROR - imageByteArray is EMPTY!")
                showToast("ERROR: Image bytes is empty!")
                return
            }
            
            showToast("Adding image to printer...")
            Log.d(TAG, "LANDI_SUMMARY: calling printer.addImage()...")
            printer?.addImage(imageByteArray, Align.CENTER, 0)
            Log.d(TAG, "LANDI_SUMMARY: addImage() completed")

            showToast("Calling startPrint()...")
            Log.d(TAG, "LANDI_SUMMARY: calling startPrint()...")
            startPrint()
        } catch (e: PrinterException) {
            showToast("PrinterException: ${e.message}")
            Log.e(TAG, "LANDI_SUMMARY: PrinterException: ${e.message}", e)
        } catch (e: Exception) {
            showToast("Exception in startPrinter: ${e.message}")
            Log.e(TAG, "LANDI_SUMMARY: Exception in startPrinter: ${e.message}", e)
        }
    }

    private fun openDevice() {
        try {
            printer?.openDevice(0)
            showToast("openDevice(0) completed")
        } catch (e: Exception) {
            showToast("openDevice EXCEPTION: ${e.message}")
            Log.e(TAG, "openDevice exception", e)
        }
    }

    private fun getStatus(): Int? {
        return try {
            printer?.getStatus().also {
                var result = "failed"
                if (it == 0) {
                    result = "success"
                }
                showToast("getStatus() returned: $it ($result)")
            }
        } catch (e: Exception) {
            showToast("getStatus EXCEPTION: ${e.message}")
            Log.e(TAG, "getStatus exception", e)
            null
        }
    }

    private fun startPrint() {
        try {
            Log.d(TAG, "LANDI_SUMMARY: startPrint() - submitting print job...")
            printer?.startPrint(object : OnPrintListener {
                override fun onSuccess() {
                    showToast("PRINT SUCCESS!")
                    Log.i(TAG, "LANDI_SUMMARY: printer result--->onSuccess")
                }

                override fun onFail(error: Int) {
                    showToast("PRINT FAILED! error=$error")
                    Log.e(TAG, "LANDI_SUMMARY: printer result--->onFail error=$error")
                }
            })
            Log.d(TAG, "LANDI_SUMMARY: startPrint() - print job submitted (async)")
        } catch (e: Exception) {
            showToast("startPrint EXCEPTION: ${e.message}")
            Log.e(TAG, "LANDI_SUMMARY: startPrint EXCEPTION: ${e.message}", e)
        }
    }

    private fun getImageBytes(bm: Bitmap): ByteArray {
        Log.d(TAG, "LANDI_SUMMARY: getImageBytes() - input bitmap: ${bm.width}x${bm.height}")
        val bitmap = scaleBitmap(bm, 0, MAX_WIDTH)
        Log.d(TAG, "LANDI_SUMMARY: getImageBytes() - scaled bitmap: ${bitmap?.width}x${bitmap?.height} (isNull=${bitmap == null})")
        return bmpToByteArray(bitmap, true)
    }

    private fun bmpToByteArray(bmp: Bitmap?, needRecycle: Boolean): ByteArray {
        if (bmp == null) {
            return byteArrayOf()
        }

        val output = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, output)
        if (needRecycle) {
            bmp.recycle()
        }
        val result = output.toByteArray()
        try {
            output.close()
        } catch (e: Exception) {
            Log.e("LandiPrinterService", "Output stream error: ${e.message}")
        }
        return result
    }

    private fun scaleBitmap(bm: Bitmap, offset: Int, maxWidth: Int): Bitmap? {
        val width = bm.width
        val height = bm.height
        val newWidth = maxWidth - offset
        if (newWidth <= 0) {
            return null
        }
        val scaleWidth = newWidth.toFloat() / width
        val scaleHeight = height.toFloat() / height
        val matrix = Matrix()
        matrix.postScale(scaleWidth, scaleHeight)
        return Bitmap.createBitmap(bm, 0, 0, width, height, matrix, true)
    }
}