package com.oxpay.o7lite.security

/**
 * Represents the possible reasons for denying access to an activity.
 * These reasons are generic and do not expose internal security mechanisms.
 */
enum class DenialReason {
    /** The calling package is not in the trusted registry */
    UNTRUSTED_PACKAGE,
    
    /** The deep link URI is invalid or malformed */
    INVALID_DEEP_LINK,
    
    /** Intent extras contain invalid or malformed data */
    MALFORMED_EXTRAS,
    
    /** Potential injection attack detected in intent data */
    INJECTION_DETECTED,
    
    /** Notification intent did not originate from this application */
    INVALID_NOTIFICATION_ORIGIN,
    
    /** Intent type could not be determined or is not allowed */
    UNKNOWN_INTENT_TYPE
}

/**
 * Represents the result of intent validation.
 * Used by ActivityGuard to communicate whether access should be allowed or denied.
 */
sealed class ValidationResult {
    
    /**
     * Access is allowed, activity can proceed with normal lifecycle.
     */
    object Allowed : ValidationResult()
    
    /**
     * Access is denied with a reason and details.
     * 
     * @param reason The category of denial (generic, does not expose security details)
     * @param details Human-readable explanation for logging purposes only
     */
    data class Denied(
        val reason: DenialReason,
        val details: String
    ) : ValidationResult()
    
    /**
     * Checks if this result allows access.
     * @return true if access is allowed, false otherwise
     */
    fun isAllowed(): Boolean = this is Allowed
    
    /**
     * Checks if this result denies access.
     * @return true if access is denied, false otherwise
     */
    fun isDenied(): Boolean = this is Denied
    
    companion object {
        /**
         * Creates an Allowed result.
         */
        fun allowed(): ValidationResult = Allowed
        
        /**
         * Creates a Denied result with the specified reason and details.
         */
        fun denied(reason: DenialReason, details: String): ValidationResult = 
            Denied(reason, details)
    }
}
