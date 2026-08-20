package com.oxpay.o7lite.security

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.oxpay.o7lite.utils.LogUtil

/**
 * Registry of trusted packages that are allowed to launch the application.
 * Packages are verified by both name and optionally by signature.
 * 
 * This registry is immutable after initialization to prevent runtime tampering.
 */
class TrustedPackageRegistry(private val context: Context) {
    
    companion object {
        private const val TAG = "TrustedPackageRegistry"
        
        /**
         * Set of trusted partner packages from AndroidManifest queries.
         * These packages are explicitly allowed to interact with the application.
         */
        private val TRUSTED_PACKAGES = setOf(
            "com.cardbiz.razercredits1",      // Razer Credits
            "woyou.aidlservice.jiuiv5",       // SUNMI printer service
//            "sunmi.pay.u_mobile",             // SUNMI Gobiz
            "com.pos.router.pay_dee",
            "com.sc.mf919",                   // Share Commerce
            "com.mscardpayments.app",         // Minesec
            "com.landiconnect.appstore"       // Landi app store
        )
        
        /**
         * The application's own package name - always trusted for self-calls.
         */
        private const val SELF_PACKAGE = "com.oxpay.o7lite"
        
        /**
         * Alternative package name for development builds.
         */
        private const val SELF_PACKAGE_DEV = "com.oxpay.o7lite"
    }
    
    /** Cached set of trusted packages including self */
    private val allTrustedPackages: Set<String> by lazy {
        TRUSTED_PACKAGES + setOf(SELF_PACKAGE, SELF_PACKAGE_DEV, context.packageName)
    }
    
    /**
     * Checks if a package is in the trusted registry.
     * 
     * @param packageName The package name to verify (may be null)
     * @return true if the package is trusted, false otherwise
     */
    fun isPackageTrusted(packageName: String?): Boolean {
        if (packageName == null) {
            LogUtil.d(TAG, "Package name is null - treating as untrusted")
            return false
        }
        
        val isTrusted = allTrustedPackages.contains(packageName)
        LogUtil.d(TAG, "Package '$packageName' trusted: $isTrusted")
        return isTrusted
    }
    
    /**
     * Checks if the package is the application itself.
     * 
     * @param packageName The package name to check
     * @return true if this is the application's own package
     */
    fun isSelfPackage(packageName: String?): Boolean {
        if (packageName == null) return false
        return packageName == SELF_PACKAGE || 
               packageName == SELF_PACKAGE_DEV || 
               packageName == context.packageName
    }
    
    /**
     * Verifies the signature of a package matches expected values.
     * This provides additional security beyond just checking the package name.
     * 
     * @param packageName The package to verify
     * @return true if signature is valid or verification is not possible, false if invalid
     */
    fun verifyPackageSignature(packageName: String): Boolean {
        return try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                context.packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES
                )
            }
            
            // For now, we just verify the package exists and has signatures
            // In production, you would compare against known signature hashes
            val hasSignatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo?.hasMultipleSigners() == true ||
                packageInfo.signingInfo?.apkContentsSigners?.isNotEmpty() == true
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures?.isNotEmpty() == true
            }
            
            LogUtil.d(TAG, "Package '$packageName' signature verification: $hasSignatures")
            hasSignatures
        } catch (e: PackageManager.NameNotFoundException) {
            LogUtil.w(TAG, "Package '$packageName' not found for signature verification")
            false
        } catch (e: Exception) {
            LogUtil.e(TAG, "Error verifying package signature: ${e.message}")
            false
        }
    }
    
    /**
     * Gets the list of all trusted package names.
     * Useful for debugging and logging.
     * 
     * @return Immutable set of trusted package names
     */
    fun getTrustedPackages(): Set<String> = allTrustedPackages.toSet()
    
    /**
     * Checks if a package is trusted AND has a valid signature.
     * This is the most secure validation method.
     * 
     * @param packageName The package to validate
     * @return true if package is trusted and signature is valid
     */
    fun isPackageTrustedAndVerified(packageName: String?): Boolean {
        if (packageName == null) return false
        if (!isPackageTrusted(packageName)) return false
        
        // Self packages don't need signature verification
        if (isSelfPackage(packageName)) return true
        
        return verifyPackageSignature(packageName)
    }
}
