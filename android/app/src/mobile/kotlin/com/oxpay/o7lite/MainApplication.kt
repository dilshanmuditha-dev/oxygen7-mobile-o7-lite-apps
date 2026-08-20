package com.oxpay.o7lite

import android.util.Log
import androidx.multidex.MultiDexApplication

/**
 * Mobile-specific MainApplication that does NOT depend on any POS SDK libraries.
 * 
 * This class is used for the "mobile" flavor build which targets standard Android
 * phones/tablets without POS hardware. It provides stub implementations for all
 * POS-related methods to maintain API compatibility with the rest of the codebase.
 * 
 * Key differences from main source set MainApplication:
 * - NO POS SDK imports (OmniDriver, PrinterInterface, SunmiPrintHelper)
 * - NO POS SDK initialization
 * - Stub implementations return null/false for POS-related queries
 * 
 * This enables the mobile flavor APK to exclude POS SDK native libraries (.so files)
 * for Google Play Store 16KB page alignment compliance.
 * 
 * @see Requirements 2.1, 2.2, 2.3, 2.4 from mobile-flavor-pos-exclusion spec
 */
class MainApplication : MultiDexApplication() {

    companion object {
        private const val TAG = "MainApplication"
        
        lateinit var context: MainApplication
            private set

        /**
         * Returns the application context.
         */
        fun getApplicationContext(): MainApplication = context

        /**
         * Stub implementation - returns null since OmniDriver is not available on mobile.
         * 
         * On POS flavors, this returns the Landi OmniDriver instance.
         * On mobile flavor, this always returns null.
         * 
         * @return null (no OmniDriver on mobile devices)
         */
        fun getOmniDriver(): Any? = null

        /**
         * Always false on mobile - WizarPOS printer service is not available.
         * 
         * On POS flavors, this tracks whether the WizarPOS printer is open.
         * On mobile flavor, this is always false.
         */
        var isWizarPosOpen: Boolean = false
            private set

        /**
         * Always false on mobile - Landi OmniDriver is not available.
         * 
         * On POS flavors, this tracks whether the Landi OmniDriver is connected.
         * On mobile flavor, this is always false.
         */
        var isLandiConnected: Boolean = false
            private set
    }

    override fun onCreate() {
        super.onCreate()
        context = this
        
        Log.d(TAG, "Mobile MainApplication initialized (no POS SDK)")
        
        // NO POS SDK initialization on mobile flavor:
        // - No OmniDriver initialization
        // - No Sunmi printer service initialization
        // - No WizarPOS printer service initialization
    }

    override fun onTerminate() {
        super.onTerminate()
        Log.d(TAG, "Mobile MainApplication terminated")
        
        // No POS SDK cleanup needed on mobile flavor
    }

    /**
     * No-op stub - WizarPOS printer service is not available on mobile.
     * 
     * On POS flavors, this initializes the WizarPOS printer service.
     * On mobile flavor, this is a no-op.
     */
    fun initWizarPosPrinterService() {
        Log.d(TAG, "initWizarPosPrinterService() called on mobile - no-op")
        // No-op: WizarPOS printer not available on mobile
    }

    /**
     * No-op stub - WizarPOS printer service is not available on mobile.
     * 
     * On POS flavors, this closes the WizarPOS printer service.
     * On mobile flavor, this is a no-op.
     */
    fun closeWizarPosPrinterService() {
        Log.d(TAG, "closeWizarPosPrinterService() called on mobile - no-op")
        // No-op: WizarPOS printer not available on mobile
    }

    /**
     * Stub implementation - always returns false since WizarPOS is not available on mobile.
     * 
     * On POS flavors, this checks if the WizarPOS printer service is available.
     * On mobile flavor, this always returns false.
     * 
     * @return false (WizarPOS printer not available on mobile devices)
     */
    fun checkWizarPosPrinterService(): Boolean {
        Log.d(TAG, "checkWizarPosPrinterService() called on mobile - returning false")
        return false
    }
}
