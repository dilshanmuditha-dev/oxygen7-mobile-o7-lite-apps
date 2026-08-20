package com.oxpay.o7lite.services.printers

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Bundle
import android.os.IBinder
import android.os.RemoteException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import com.oxpay.o7lite.constants.PrinterConstants
import com.oxpay.o7lite.enums.PrinterType
import com.oxpay.o7lite.services.base.BasePrinterService
import com.oxpay.o7lite.utils.LogUtil
import com.morefun.yapi.ServiceResult
import com.morefun.yapi.device.printer.MultipleAppPrinter
import com.morefun.yapi.device.printer.OnPrintListener
import com.morefun.yapi.device.printer.PrinterConfig
import com.morefun.yapi.engine.DeviceServiceEngine

/**
 * Morefun (MF) POS printer service implementation.
 *
 * The Morefun YSDK is a thin AIDL client that binds to the `com.morefun.ysdk`
 * system service pre-installed on Morefun POS hardware. Once bound, the returned
 * [DeviceServiceEngine] exposes a high-level [MultipleAppPrinter] used to print a
 * single bitmap (`printImage`) and a low-level `Printer` used for status queries.
 *
 * This service mirrors the bound-service pattern already used by
 * [AnfuPrinterService] and [CoherentPrinterService]:
 *  - bind on [initialize] with action + package
 *  - reconnect on binder death / service disconnect
 *  - render the receipt/summary bitmap in [BasePrinterService] (ANFU layout)
 *  - dispatch the bitmap to the printer in [printBitmapInternal]
 *
 * The bitmap sent from Flutter is already laid out and resized; here we simply
 * forward it to the printer. The final print outcome is delivered asynchronously
 * on a binder thread via [OnPrintListener] and is logged for diagnostics.
 */
class MorefunPrinterService(context: Context) : BasePrinterService(context, PrinterType.MOREFUN) {

    companion object {
        private const val TAG = "MorefunPrinterService"
        private const val LOG_PREFIX = "MOREFUN:::"
        private const val SERVICE_PACKAGE = "com.morefun.ysdk"
        private const val SERVICE_ACTION = "com.morefun.ysdk.service"

        /**
         * White margin (in printer dots) left on each side of the receipt so the
         * printout has a normal receipt look instead of running edge-to-edge.
         * Tune this if a wider/narrower margin is desired (58mm head = 384 dots).
         */
        private const val HORIZONTAL_MARGIN_DOTS = 24

        /**
         * White space (in printer dots) added below the receipt content so the
         * printer feeds past the last printed line and does not clip the bottom
         * of the receipt (e.g. the barcode/QR). Tune if more/less trailing feed
         * is desired.
         */
        private const val BOTTOM_MARGIN_DOTS = 60
    }

    private var deviceServiceEngine: DeviceServiceEngine? = null
    private var isServiceBound = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceDisconnected(name: ComponentName) {
            isServiceBound = false
            deviceServiceEngine = null
            isInitialized = false
            LogUtil.d(TAG, "$LOG_PREFIX Service disconnected, attempting rebind")
            // Auto-reconnect: the system service may be updated/killed at runtime
            initialize()
        }

        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            isServiceBound = true
            deviceServiceEngine = DeviceServiceEngine.Stub.asInterface(service)
            LogUtil.d(TAG, "$LOG_PREFIX Service connected, engine=$deviceServiceEngine")

            if (deviceServiceEngine != null) {
                try {
                    service.linkToDeath({
                        LogUtil.d(TAG, "$LOG_PREFIX binderDied, rebinding")
                        deviceServiceEngine = null
                        isInitialized = false
                        initialize()
                    }, 0)
                    isInitialized = true
                } catch (e: RemoteException) {
                    LogUtil.e(TAG, "$LOG_PREFIX linkToDeath failed: ${e.message}")
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
        return isInitialized && isServiceBound && deviceServiceEngine != null
    }

    /**
     * Return the raw printer status from the low-level [DeviceServiceEngine.getPrinter].
     * A value of [ServiceResult.Success] (0) means the printer is ready/connected,
     * which matches the `state == 0` convention used by the Flutter connectivity check.
     */
    fun getPrinterState(): Int {
        val engine = deviceServiceEngine ?: return -1
        return try {
            engine.printer?.status ?: -1
        } catch (e: RemoteException) {
            LogUtil.e(TAG, "$LOG_PREFIX getPrinterState error: ${e.message}")
            // Stale binder -> force a rebind for the next call
            deviceServiceEngine = null
            initialize()
            -1
        }
    }

    /**
     * Print a small self-test receipt (used by the troubleshooting screen).
     * The test bitmap is generated natively so it has no dependency on any
     * Flutter widget/receipt data. Reuses [printBitmap] so it goes through the
     * same readiness check and [fitToPrinterWidth] margin/scaling as normal prints.
     */
    fun printTestReceipt(): Boolean {
        return try {
            val bitmap = buildTestReceiptBitmap()
            printBitmap(bitmap)
        } catch (e: Exception) {
            LogUtil.e(TAG, "$LOG_PREFIX printTestReceipt error: ${e.message}")
            false
        }
    }

    /**
     * Build a simple black-on-white self-test receipt bitmap at the printer head
     * width. Kept self-contained (no shared layout/resources) to avoid any impact
     * on the other print flows.
     */
    private fun buildTestReceiptBitmap(): Bitmap {
        val width = PrinterConstants.MAX_BIT_WIDTH // 384 dots @ 58mm
        val cx = width / 2f

        val titlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            textSize = 42f
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val subPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            textSize = 30f
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val bodyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            textSize = 26f
            textAlign = Paint.Align.CENTER
        }
        val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            strokeWidth = 2f
        }

        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())

        val height = 300
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)

        var y = 52f
        canvas.drawText("O7Lite", cx, y, titlePaint); y += 46f
        canvas.drawText("Printer Self-Test", cx, y, subPaint); y += 30f
        canvas.drawLine(24f, y, width - 24f, y, linePaint); y += 36f
        canvas.drawText("Model: MOREFUN", cx, y, bodyPaint); y += 34f
        canvas.drawText(timestamp, cx, y, bodyPaint); y += 36f
        canvas.drawLine(24f, y, width - 24f, y, linePaint); y += 42f
        canvas.drawText("*** TEST OK ***", cx, y, subPaint)

        return bitmap
    }

    override fun printBitmapInternal(bitmap: Bitmap): Boolean {
        val engine = deviceServiceEngine
        if (engine == null) {
            LogUtil.e(TAG, "$LOG_PREFIX Printer engine not available")
            return false
        }

        return try {
            // Fit the bitmap to the printer head width, leaving a white
            // horizontal margin on each side so the printout looks like a normal
            // receipt instead of running edge-to-edge. Also prevents clipping
            // (source wider than the head, e.g. the pixelRatio-2.0 Flutter capture)
            // and left-alignment (source narrower than the head).
            val printBitmap = fitToPrinterWidth(bitmap)

            val config = Bundle().apply {
                putInt(PrinterConfig.COMMON_GRAYLEVEL, PrinterConfig.PRINT_DENSITY_NORMAL)
            }

            val printer: MultipleAppPrinter = engine.multipleAppPrinter
            val dispatchResult = printer.printImage(printBitmap, object : OnPrintListener.Stub() {
                override fun onPrintResult(result: Int) {
                    // Runs on a binder thread — log only, do not touch UI here.
                    if (result == ServiceResult.Success) {
                        LogUtil.d(TAG, "$LOG_PREFIX Print success (async)")
                    } else {
                        LogUtil.e(TAG, "$LOG_PREFIX Print failed (async): code=$result")
                    }
                }
            }, config)

            LogUtil.d(
                TAG,
                "$LOG_PREFIX printImage dispatched: src ${bitmap.width}x${bitmap.height} -> " +
                    "print ${printBitmap.width}x${printBitmap.height}, dispatchResult=$dispatchResult"
            )

            // A negative dispatch result indicates an immediate failure (e.g. paper lack).
            dispatchResult >= 0
        } catch (e: RemoteException) {
            LogUtil.e(TAG, "$LOG_PREFIX printImage RemoteException: ${e.message}")
            // Stale binder -> null it and rebind for the next attempt
            deviceServiceEngine = null
            initialize()
            false
        } catch (e: Exception) {
            LogUtil.e(TAG, "$LOG_PREFIX printImage error: ${e.message}")
            false
        }
    }

    /**
     * Fit a bitmap to the 58mm printer head width (384 dots), preserving aspect
     * ratio and leaving a white horizontal margin ([HORIZONTAL_MARGIN_DOTS]) on
     * each side. The source is scaled to the content width (head width minus both
     * margins) and centered on a white, head-width canvas. This gives a normal
     * receipt look (not edge-to-edge) and works whether the source is wider than
     * the head (pixelRatio-2.0 Flutter capture -> downscaled, crisp) or narrower
     * (native render -> upscaled to fill). Uses bilinear filtering.
     */
    private fun fitToPrinterWidth(bitmap: Bitmap): Bitmap {
        val headWidth = PrinterConstants.MAX_BIT_WIDTH // 384 dots @ 58mm
        val contentWidth = (headWidth - HORIZONTAL_MARGIN_DOTS * 2).coerceAtLeast(1)
        val contentHeight =
            (bitmap.height.toFloat() * contentWidth / bitmap.width).toInt().coerceAtLeast(1)

        val scaled = Bitmap.createScaledBitmap(bitmap, contentWidth, contentHeight, true)

        // Center the scaled content on a white, full-head-width canvas so both
        // sides get an equal white margin, and add BOTTOM_MARGIN_DOTS of white
        // space below the content so the printer feeds past the last line and
        // does not clip the bottom of the receipt (e.g. the barcode/QR).
        val result = Bitmap.createBitmap(
            headWidth,
            contentHeight + BOTTOM_MARGIN_DOTS,
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(result)
        canvas.drawColor(Color.WHITE)
        canvas.drawBitmap(scaled, HORIZONTAL_MARGIN_DOTS.toFloat(), 0f, null)

        if (scaled != bitmap) {
            scaled.recycle()
        }
        return result
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
        deviceServiceEngine = null
    }
}
