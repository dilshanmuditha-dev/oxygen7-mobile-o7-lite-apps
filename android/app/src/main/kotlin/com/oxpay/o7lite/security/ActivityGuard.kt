package com.oxpay.o7lite.security

import android.content.Context
import android.content.Intent
import com.oxpay.o7lite.utils.LogUtil

/**
 * Guards exported activities against unauthorized access.
 * Validates incoming intents and enforces access restrictions.
 * 
 * This is the main entry point for intent validation in the security layer.
 */
class ActivityGuard(
    private val trustedPackageRegistry: TrustedPackageRegistry,
    private val intentValidator: IntentValidator,
    private val deepLinkHandler: DeepLinkHandler,
    private val securityLogger: SecurityLogger
) {
    
    companion object {
        private const val TAG = "ActivityGuard"
        
        /**
         * Creates an ActivityGuard with all dependencies initialized.
         * 
         * @param context The application context
         * @return Fully configured ActivityGuard instance
         */
        fun create(context: Context): ActivityGuard {
            val intentValidator = IntentValidator()
            return ActivityGuard(
                trustedPackageRegistry = TrustedPackageRegistry(context),
                intentValidator = intentValidator,
                deepLinkHandler = DeepLinkHandler(intentValidator),
                securityLogger = SecurityLogger(context)
            )
        }
    }
    
    /**
     * Validates an incoming intent and determines if access should be allowed.
     * This is the main entry point for intent validation.
     * 
     * @param intent The incoming intent to validate
     * @param callingPackage The package name of the calling application (may be null)
     * @return ValidationResult indicating whether access is allowed or denied
     */
    fun validateIntent(intent: Intent?, callingPackage: String?): ValidationResult {
        LogUtil.d(TAG, "Validating intent from package: $callingPackage")
        
        // Handle null intent
        if (intent == null) {
            return denyAndLog(
                callingPackage,
                null,
                DenialReason.UNKNOWN_INTENT_TYPE,
                "Intent is null"
            )
        }
        
        // Classify the intent
        val classification = IntentClassification.from(intent)
        LogUtil.d(TAG, "Intent classified as: ${classification.type}")
        
        // Route to appropriate validation based on intent type
        val result = when (classification.type) {
            IntentType.LAUNCHER -> validateLauncherIntent(intent, callingPackage)
            IntentType.NOTIFICATION -> validateNotificationIntent(intent, callingPackage)
            IntentType.DEEP_LINK -> validateDeepLinkIntent(intent, callingPackage)
            IntentType.EXTERNAL -> validateExternalIntent(intent, callingPackage)
        }
        
        // Log the result
        logValidationResult(result, callingPackage, intent.action)
        
        return result
    }
    
    /**
     * Validates a launcher intent (from Android home screen).
     * Launcher intents are always allowed without package verification.
     */
    private fun validateLauncherIntent(intent: Intent, callingPackage: String?): ValidationResult {
        LogUtil.d(TAG, "Launcher intent - allowing access")
        return ValidationResult.allowed()
    }
    
    /**
     * Validates a notification intent.
     * Notification intents must originate from the application itself.
     */
    private fun validateNotificationIntent(intent: Intent, callingPackage: String?): ValidationResult {
        // Notification intents should come from our own app
        if (!trustedPackageRegistry.isSelfPackage(callingPackage)) {
            LogUtil.w(TAG, "Notification intent from external package: $callingPackage")
            return ValidationResult.denied(
                DenialReason.INVALID_NOTIFICATION_ORIGIN,
                "Notification intent must originate from application"
            )
        }
        
        // Validate intent extras
        val extrasResult = intentValidator.validateExtras(intent)
        if (extrasResult.isDenied()) {
            return extrasResult
        }
        
        LogUtil.d(TAG, "Notification intent validated successfully")
        return ValidationResult.allowed()
    }
    
    /**
     * Validates a deep link intent.
     * Deep links must have valid scheme/host and sanitized parameters.
     */
    private fun validateDeepLinkIntent(intent: Intent, callingPackage: String?): ValidationResult {
        // First validate the deep link format and parameters
        val deepLinkResult = deepLinkHandler.validateDeepLink(intent)
        if (deepLinkResult.isDenied()) {
            return deepLinkResult
        }
        
        // Also validate any extras
        val extrasResult = intentValidator.validateExtras(intent)
        if (extrasResult.isDenied()) {
            return extrasResult
        }
        
        LogUtil.d(TAG, "Deep link intent validated successfully")
        return ValidationResult.allowed()
    }
    
    /**
     * Validates an external intent from another application.
     * External intents must come from trusted packages.
     */
    private fun validateExternalIntent(intent: Intent, callingPackage: String?): ValidationResult {
        // Check rate limiting first
        if (callingPackage != null && securityLogger.isRateLimitExceeded(callingPackage)) {
            LogUtil.w(TAG, "Rate limit exceeded for package: $callingPackage")
            return ValidationResult.denied(
                DenialReason.UNTRUSTED_PACKAGE,
                "Rate limit exceeded"
            )
        }
        
        // Check if package is trusted
        if (!trustedPackageRegistry.isPackageTrusted(callingPackage)) {
            LogUtil.w(TAG, "Untrusted package: $callingPackage")
            return ValidationResult.denied(
                DenialReason.UNTRUSTED_PACKAGE,
                "Package not in trusted registry"
            )
        }
        
        // Validate intent extras
        val extrasResult = intentValidator.validateExtras(intent)
        if (extrasResult.isDenied()) {
            return extrasResult
        }
        
        LogUtil.d(TAG, "External intent from trusted package validated successfully")
        return ValidationResult.allowed()
    }
    
    /**
     * Helper to deny access and log the event.
     */
    private fun denyAndLog(
        callingPackage: String?,
        intentAction: String?,
        reason: DenialReason,
        details: String
    ): ValidationResult {
        securityLogger.logDenied(callingPackage, intentAction, reason, details)
        return ValidationResult.denied(reason, details)
    }
    
    /**
     * Logs the validation result.
     */
    private fun logValidationResult(
        result: ValidationResult,
        callingPackage: String?,
        intentAction: String?
    ) {
        when (result) {
            is ValidationResult.Allowed -> {
                securityLogger.logAllowed(callingPackage, intentAction)
            }
            is ValidationResult.Denied -> {
                securityLogger.logDenied(
                    callingPackage,
                    intentAction,
                    result.reason,
                    result.details
                )
            }
        }
    }
    
    /**
     * Classifies an intent to determine its type.
     * Exposed for testing purposes.
     */
    fun classifyIntent(intent: Intent?): IntentType {
        return IntentClassification.from(intent).type
    }
    
    /**
     * Checks if a package is trusted.
     * Exposed for testing purposes.
     */
    fun isPackageTrusted(packageName: String?): Boolean {
        return trustedPackageRegistry.isPackageTrusted(packageName)
    }
}
