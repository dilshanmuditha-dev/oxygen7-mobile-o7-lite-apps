package com.oxpay.o7lite

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.multidex.MultiDexApplication
import com.centerm.smartpos.aidl.sys.AidlDeviceManager
import com.cloudpos.jniinterface.PrinterInterface
import com.oxpay.o7lite.utils.Utils
import com.oxpay.o7lite.utils.LogUtil
import com.oxpay.o7lite.utils.sunmi_printer.SunmiPrintHelper
import com.sdksuite.omnidriver.OmniConnection
import com.sdksuite.omnidriver.OmniDriver


class MainApplication : MultiDexApplication() {

    companion object {
        private const val TAG = "MainApplication"

        lateinit var context: MainApplication

        @SuppressLint("StaticFieldLeak")
        private lateinit var mOmniDriver: OmniDriver

        // Track if Landi OmniDriver is connected
        @Volatile
        var isLandiConnected: Boolean = false
            private set

        fun getApplicationContext() = context

        fun getOmniDriver() = mOmniDriver

        var isWizarPosOpen: Boolean = false

        // Coherent AIDL device manager
        private var coherentDeviceManager: AidlDeviceManager? = null

        fun getCoherentDeviceManager(): AidlDeviceManager? = coherentDeviceManager
    }

    override fun onCreate() {
        super.onCreate()
        context = this

        // Initialize Landi OmniDriver
        showDebugToast("MainApplication: Creating OmniDriver...")
        mOmniDriver = OmniDriver.me(this)
        showDebugToast("MainApplication: OmniDriver instance created")

        // Initialize OmniDriver connection for Landi devices
        initLandiOmniDriver()

        // Initialize Sunmi printer service
        initSunmiPrinterService(this)

        // Initialize WizarPos printer service
        initWizarPosPrinterService()

        // Initialize Coherent AIDL service
        initCoherentService()
    }

    /**
     * Initialize OmniDriver connection for Landi devices.
     * This must be called before getPrinter() can return a valid printer.
     */
    private fun initLandiOmniDriver() {
        if (!Utils.isLANDI()) {
            showDebugToast("MainApplication: Not a Landi device, skipping OmniDriver init")
            return
        }

        showDebugToast("MainApplication: Initializing OmniDriver...")

        mOmniDriver.init(object : OmniConnection {
            override fun onConnected() {
                isLandiConnected = true
                showDebugToast("MainApplication: OmniDriver connected successfully")
                Log.i(TAG, "OmniDriver connected successfully")
            }

            override fun onDisconnected(error: Int) {
                isLandiConnected = false
                showDebugToast("MainApplication: OmniDriver disconnected: error=$error")
                Log.e(TAG, "OmniDriver disconnected: error=$error")

                if (error == OmniDriver.ERROR_BIND_FAIL) {
                    showDebugToast("MainApplication: OmniDriver service NOT INSTALLED!")
                    Log.e(TAG, "OmniDriver service not installed")
                }
            }
        })
    }

    private fun initSunmiPrinterService(context: Context) {
        if (!Utils.isSUNMI()) return
        SunmiPrintHelper.instance.initSunmiPrinterService(context)
    }

    fun initWizarPosPrinterService() {
        if (!Utils.isWIZAR()) return
        val result: Int = PrinterInterface.open()

        if (result < 0) {
            showDebugToast("Initialize WizarPos printer failed with error code: $result")
        }

        isWizarPosOpen = result >= 0
    }

    fun closeWizarPosPrinterService() {
        if (!Utils.isWIZAR()) return
        if (isWizarPosOpen) {
            PrinterInterface.close()
            isWizarPosOpen = false
        }
    }

    // Coherent AIDL service connection
    private var isCoherentServiceBound = false

    private val coherentServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            coherentDeviceManager = AidlDeviceManager.Stub.asInterface(service)
            isCoherentServiceBound = true
            LogUtil.d(TAG, "COHERENT::: Service connected, manager=$coherentDeviceManager")
        }

        override fun onServiceDisconnected(name: ComponentName) {
            coherentDeviceManager = null
            isCoherentServiceBound = false
            LogUtil.d(TAG, "COHERENT::: Service disconnected")
        }
    }

    /**
     * Initialize Coherent AIDL service binding.
     * Binds to com.centerm.smartposservice to obtain AidlDeviceManager.
     */
    private fun initCoherentService() {
        if (!Utils.isCOHERENT()) return

        LogUtil.d(TAG, "COHERENT::: Initializing Coherent service...")
        try {
            val intent = Intent()
            intent.setPackage("com.centerm.smartposservice")
            intent.setAction("com.centerm.smartpos.service.MANAGER_SERVICE")
            val bound = bindService(intent, coherentServiceConnection, Context.BIND_AUTO_CREATE)
            if (bound) {
                LogUtil.d(TAG, "COHERENT::: Service binding initiated")
            } else {
                LogUtil.e(TAG, "COHERENT::: Failed to bind service")
            }
        } catch (e: Exception) {
            LogUtil.e(TAG, "COHERENT::: Failed to initialize: ${e.message}")
        }
    }

    override fun onTerminate() {
        super.onTerminate()
        closeWizarPosPrinterService()

        // Cleanup Landi OmniDriver
        if (Utils.isLANDI() && isLandiConnected) {
            mOmniDriver.destroy()
            isLandiConnected = false
        }

        // Cleanup Coherent AIDL service
        if (isCoherentServiceBound) {
            try {
                unbindService(coherentServiceConnection)
                LogUtil.d(TAG, "COHERENT::: Service unbound")
            } catch (e: Exception) {
                LogUtil.e(TAG, "COHERENT::: Unbind error: ${e.message}")
            }
            coherentDeviceManager = null
            isCoherentServiceBound = false
        }
    }

    fun checkWizarPosPrinterService(): Boolean {
        if (!Utils.isWIZAR()) return false
        if (!isWizarPosOpen) {
            val result: Int = PrinterInterface.open()
            return result >= 0
        }
        return false
    }

    private fun showDebugToast(message: String) {
//        runOnUiThread {
//            Toast.makeText(this, message, Toast.LENGTH_LONG).show()
//        }
        LogUtil.d("MainApplication", "TOAST: $message")
    }
}