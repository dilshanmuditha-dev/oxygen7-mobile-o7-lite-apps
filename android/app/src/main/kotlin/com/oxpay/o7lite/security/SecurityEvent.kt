package com.oxpay.o7lite.security

/**
 * Represents the type of security event for logging and auditing.
 */
enum class SecurityEventType {
    /** Access was allowed after successful validation */
    ACCESS_ALLOWED,
    
    /** Access was denied due to validation failure */
    ACCESS_DENIED,
    
    /** Rate limit exceeded for a specific package */
    RATE_LIMIT_EXCEEDED,
    
    /** Potential injection attack was detected */
    INJECTION_ATTEMPT_DETECTED
}

/**
 * Data class representing a security event for auditing purposes.
 * Contains all relevant information about an access attempt.
 * 
 * IMPORTANT: This class must NOT contain sensitive data such as:
 * - Authentication tokens
 * - Payment card numbers
 * - Personal identification information
 */
data class SecurityEvent(
    /** Timestamp when the event occurred (milliseconds since epoch) */
    val timestamp: Long = System.currentTimeMillis(),
    
    /** Type of security event */
    val eventType: SecurityEventType,
    
    /** Package name of the calling application (may be null for unknown callers) */
    val callingPackage: String?,
    
    /** Action from the intent (may be null) */
    val intentAction: String?,
    
    /** Reason for denial (null for allowed events) */
    val denialReason: DenialReason? = null,
    
    /** Additional details for logging (must not contain sensitive data) */
    val additionalDetails: String? = null
) {
    companion object {
        // Patterns that indicate sensitive data - must be filtered from logs
        private val SENSITIVE_PATTERNS = listOf(
            Regex("(?i)bearer\\s+[a-zA-Z0-9._-]+"),           // Bearer tokens
            Regex("(?i)token[=:]\\s*[a-zA-Z0-9._-]+"),        // Generic tokens
            Regex("\\b\\d{13,19}\\b"),                         // Credit card numbers
            Regex("(?i)password[=:]\\s*\\S+"),                 // Passwords
            Regex("(?i)secret[=:]\\s*\\S+"),                   // Secrets
            Regex("(?i)api[_-]?key[=:]\\s*\\S+")              // API keys
        )
        
        /**
         * Creates an ACCESS_ALLOWED event.
         */
        fun allowed(
            callingPackage: String?,
            intentAction: String?,
            details: String? = null
        ): SecurityEvent = SecurityEvent(
            eventType = SecurityEventType.ACCESS_ALLOWED,
            callingPackage = callingPackage,
            intentAction = intentAction,
            additionalDetails = details
        )
        
        /**
         * Creates an ACCESS_DENIED event.
         */
        fun denied(
            callingPackage: String?,
            intentAction: String?,
            reason: DenialReason,
            details: String? = null
        ): SecurityEvent = SecurityEvent(
            eventType = SecurityEventType.ACCESS_DENIED,
            callingPackage = callingPackage,
            intentAction = intentAction,
            denialReason = reason,
            additionalDetails = details
        )
        
        /**
         * Creates a RATE_LIMIT_EXCEEDED event.
         */
        fun rateLimitExceeded(
            callingPackage: String?,
            attemptCount: Int
        ): SecurityEvent = SecurityEvent(
            eventType = SecurityEventType.RATE_LIMIT_EXCEEDED,
            callingPackage = callingPackage,
            intentAction = null,
            additionalDetails = "Attempt count: $attemptCount"
        )
        
        /**
         * Creates an INJECTION_ATTEMPT_DETECTED event.
         */
        fun injectionDetected(
            callingPackage: String?,
            intentAction: String?,
            patternType: String
        ): SecurityEvent = SecurityEvent(
            eventType = SecurityEventType.INJECTION_ATTEMPT_DETECTED,
            callingPackage = callingPackage,
            intentAction = intentAction,
            denialReason = DenialReason.INJECTION_DETECTED,
            additionalDetails = "Pattern type: $patternType"
        )
    }
    
    /**
     * Converts to a log-safe string representation.
     * Ensures no sensitive data is included in the output.
     * 
     * @return A string safe for logging
     */
    fun toLogString(): String {
        val sanitizedDetails = additionalDetails?.let { sanitizeForLog(it) }
        
        return buildString {
            append("[${eventType.name}] ")
            append("package=${callingPackage ?: "unknown"}, ")
            append("action=${intentAction ?: "none"}")
            denialReason?.let { append(", reason=${it.name}") }
            sanitizedDetails?.let { append(", details=$it") }
        }
    }
    
    /**
     * Sanitizes a string to remove any sensitive data patterns.
     * 
     * @param input The string to sanitize
     * @return The sanitized string with sensitive data redacted
     */
    private fun sanitizeForLog(input: String): String {
        var result = input
        SENSITIVE_PATTERNS.forEach { pattern ->
            result = pattern.replace(result, "[REDACTED]")
        }
        return result
    }
    
    /**
     * Checks if this event represents a denied access.
     */
    fun isDenied(): Boolean = eventType == SecurityEventType.ACCESS_DENIED
    
    /**
     * Checks if this event represents an allowed access.
     */
    fun isAllowed(): Boolean = eventType == SecurityEventType.ACCESS_ALLOWED
}
