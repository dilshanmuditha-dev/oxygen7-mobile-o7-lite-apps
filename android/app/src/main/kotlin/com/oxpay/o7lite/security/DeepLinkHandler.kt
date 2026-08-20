package com.oxpay.o7lite.security

import android.content.Intent
import android.net.Uri
import com.oxpay.o7lite.utils.LogUtil

/**
 * Handles deep link intent validation and parameter extraction.
 * Ensures deep links are properly formatted and parameters are sanitized.
 */
class DeepLinkHandler(private val intentValidator: IntentValidator) {
    
    companion object {
        private const val TAG = "DeepLinkHandler"
        
        /** Expected scheme for deep links */
        const val EXPECTED_SCHEME = "my"
        
        /** Expected host for deep links */
        const val EXPECTED_HOST = "native"

        private const val LOGIN_SCHEME = "o7lite"
        private const val LOGIN_HOST = "login"
        private const val HTTPS_SCHEME = "https"
        private const val HTTPS_LOGIN_HOST = "o7lite.com"
        private const val HTTPS_LOGIN_PATH = "/login"
        
        /** Maximum number of query parameters allowed */
        private const val MAX_QUERY_PARAMETERS = 20
        
        /** Maximum length for a single parameter value */
        private const val MAX_PARAMETER_VALUE_LENGTH = 1024
    }
    
    /**
     * Validates a deep link intent.
     * Checks scheme, host, and validates all parameters.
     * 
     * @param intent The deep link intent to validate
     * @return ValidationResult indicating if the deep link is valid
     */
    fun validateDeepLink(intent: Intent): ValidationResult {
        val uri = intent.data
        
        // Check if URI exists
        if (uri == null) {
            LogUtil.w(TAG, "Deep link intent has no data URI")
            return ValidationResult.denied(
                DenialReason.INVALID_DEEP_LINK,
                "Deep link intent missing data URI"
            )
        }
        
        val isLegacyRouteDeepLink =
            uri.scheme == EXPECTED_SCHEME && uri.host == EXPECTED_HOST
        val isLoginCredentialDeepLink =
            uri.scheme == LOGIN_SCHEME && uri.host == LOGIN_HOST
        val isHttpsLoginAppLink =
            uri.scheme == HTTPS_SCHEME &&
                uri.host == HTTPS_LOGIN_HOST &&
                uri.path == HTTPS_LOGIN_PATH

        // Validate scheme
        if (!isLegacyRouteDeepLink &&
            !isLoginCredentialDeepLink &&
            !isHttpsLoginAppLink
        ) {
            LogUtil.w(TAG, "Invalid deep link scheme: ${uri.scheme}")
            return ValidationResult.denied(
                DenialReason.INVALID_DEEP_LINK,
                "Invalid deep link target"
            )
        }
        
        // Validate parameters
        return validateParameters(uri)
    }
    
    /**
     * Validates all query parameters in a deep link URI.
     * 
     * @param uri The URI to validate
     * @return ValidationResult indicating if parameters are valid
     */
    private fun validateParameters(uri: Uri): ValidationResult {
        val parameterNames = try {
            uri.queryParameterNames
        } catch (e: Exception) {
            LogUtil.e(TAG, "Error parsing query parameters: ${e.message}")
            return ValidationResult.denied(
                DenialReason.INVALID_DEEP_LINK,
                "Malformed query parameters"
            )
        }
        
        // Check parameter count
        if (parameterNames.size > MAX_QUERY_PARAMETERS) {
            LogUtil.w(TAG, "Too many query parameters: ${parameterNames.size}")
            return ValidationResult.denied(
                DenialReason.INVALID_DEEP_LINK,
                "Too many query parameters (max: $MAX_QUERY_PARAMETERS)"
            )
        }
        
        // Validate each parameter
        for (name in parameterNames) {
            val value = uri.getQueryParameter(name) ?: continue
            
            // Check parameter value length
            if (value.length > MAX_PARAMETER_VALUE_LENGTH) {
                LogUtil.w(TAG, "Parameter '$name' exceeds max length")
                return ValidationResult.denied(
                    DenialReason.INVALID_DEEP_LINK,
                    "Parameter '$name' exceeds maximum length"
                )
            }
            
            // Check for injection patterns
            if (intentValidator.containsInjectionPatterns(value)) {
                LogUtil.w(TAG, "Injection pattern detected in parameter '$name'")
                return ValidationResult.denied(
                    DenialReason.INJECTION_DETECTED,
                    "Potential injection in parameter '$name'"
                )
            }
        }
        
        LogUtil.d(TAG, "Deep link validation passed")
        return ValidationResult.allowed()
    }
    
    /**
     * Extracts and sanitizes parameters from a deep link URI.
     * Only call this after validateDeepLink returns Allowed.
     * 
     * @param uri The deep link URI
     * @return Map of sanitized parameter names to values
     */
    fun extractParameters(uri: Uri): Map<String, String> {
        val result = mutableMapOf<String, String>()
        
        try {
            for (name in uri.queryParameterNames) {
                val value = uri.getQueryParameter(name)
                if (value != null) {
                    // Sanitize the value before adding to result
                    result[name] = intentValidator.sanitizeString(value)
                }
            }
        } catch (e: Exception) {
            LogUtil.e(TAG, "Error extracting parameters: ${e.message}")
        }
        
        return result.toMap()
    }
    
    /**
     * Extracts the path from a deep link URI.
     * 
     * @param uri The deep link URI
     * @return The sanitized path, or empty string if none
     */
    fun extractPath(uri: Uri): String {
        val path = uri.path ?: return ""
        return intentValidator.sanitizeString(path)
    }
    
    /**
     * Validates and extracts deep link data in one operation.
     * Returns null if validation fails.
     * 
     * @param intent The deep link intent
     * @return DeepLinkData if valid, null otherwise
     */
    fun validateAndExtract(intent: Intent): DeepLinkData? {
        val validationResult = validateDeepLink(intent)
        if (validationResult.isDenied()) {
            return null
        }
        
        val uri = intent.data ?: return null
        
        return DeepLinkData(
            scheme = uri.scheme ?: EXPECTED_SCHEME,
            host = uri.host ?: EXPECTED_HOST,
            path = extractPath(uri),
            parameters = extractParameters(uri)
        )
    }
    
    /**
     * Checks if an intent is a valid deep link for this application.
     * 
     * @param intent The intent to check
     * @return true if this is a deep link with our scheme
     */
    fun isDeepLink(intent: Intent): Boolean {
        val uri = intent.data ?: return false
        return (uri.scheme == EXPECTED_SCHEME && uri.host == EXPECTED_HOST) ||
            LoginDeepLinkBridge.isLoginDeepLink(uri)
    }
}

/**
 * Data class representing validated and sanitized deep link data.
 */
data class DeepLinkData(
    val scheme: String,
    val host: String,
    val path: String,
    val parameters: Map<String, String>
) {
    /**
     * Gets a parameter value by name.
     * 
     * @param name The parameter name
     * @return The parameter value, or null if not present
     */
    fun getParameter(name: String): String? = parameters[name]
    
    /**
     * Checks if a parameter exists.
     * 
     * @param name The parameter name
     * @return true if the parameter exists
     */
    fun hasParameter(name: String): Boolean = parameters.containsKey(name)
}
