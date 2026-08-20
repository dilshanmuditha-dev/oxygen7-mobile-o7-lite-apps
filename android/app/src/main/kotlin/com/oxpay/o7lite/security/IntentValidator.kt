package com.oxpay.o7lite.security

import android.content.Intent
import android.os.Bundle

/**
 * Validates intent extras and data for security threats.
 * Detects injection patterns and enforces data constraints.
 */
class IntentValidator {
    
    companion object {
        /** Maximum allowed length for string extras to prevent buffer overflow attacks */
        const val MAX_STRING_EXTRA_LENGTH = 4096
        
        /** Characters that should be encoded in sanitized output */
        private val SPECIAL_CHARACTERS = mapOf(
            '<' to "&lt;",
            '>' to "&gt;",
            '"' to "&quot;",
            '\'' to "&#39;",
            '&' to "&amp;",
            '\\' to "&#92;",
            '/' to "&#47;"
        )
        
        /** SQL injection patterns */
        private val SQL_INJECTION_PATTERNS = listOf(
            Regex("(?i)\\b(select|insert|update|delete|drop|union|alter|create|truncate)\\b\\s+"),
            Regex("(?i)\\b(or|and)\\b\\s+\\d+\\s*=\\s*\\d+"),
            Regex("(?i)'\\s*(or|and)\\s+'"),
            Regex("(?i)--\\s*$"),
            Regex("(?i);\\s*(drop|delete|update|insert)\\b")
        )
        
        /** XSS (Cross-Site Scripting) patterns */
        private val XSS_PATTERNS = listOf(
            Regex("(?i)<script[^>]*>", RegexOption.IGNORE_CASE),
            Regex("(?i)</script>", RegexOption.IGNORE_CASE),
            Regex("(?i)javascript:", RegexOption.IGNORE_CASE),
            Regex("(?i)on\\w+\\s*=", RegexOption.IGNORE_CASE),
            Regex("(?i)<iframe[^>]*>", RegexOption.IGNORE_CASE),
            Regex("(?i)<object[^>]*>", RegexOption.IGNORE_CASE),
            Regex("(?i)<embed[^>]*>", RegexOption.IGNORE_CASE)
        )
        
        /** Template injection patterns */
        private val TEMPLATE_INJECTION_PATTERNS = listOf(
            Regex("\\$\\{[^}]+\\}"),           // ${...} - Java/Kotlin template
            Regex("\\{\\{[^}]+\\}\\}"),         // {{...}} - Mustache/Handlebars
            Regex("#\\{[^}]+\\}"),              // #{...} - Ruby/Spring
            Regex("<%[^%]*%>")                  // <% %> - JSP/ERB
        )
        
        /** All injection patterns combined */
        private val ALL_INJECTION_PATTERNS = SQL_INJECTION_PATTERNS + 
                                              XSS_PATTERNS + 
                                              TEMPLATE_INJECTION_PATTERNS
    }
    
    /**
     * Validates all extras in an intent.
     * Checks for injection patterns and enforces length limits.
     * 
     * @param intent The intent to validate
     * @return ValidationResult indicating if extras are safe
     */
    fun validateExtras(intent: Intent): ValidationResult {
        val extras = intent.extras ?: return ValidationResult.allowed()
        
        return validateBundle(extras)
    }
    
    /**
     * Validates a Bundle of extras recursively.
     * 
     * @param bundle The bundle to validate
     * @return ValidationResult indicating if the bundle is safe
     */
    private fun validateBundle(bundle: Bundle): ValidationResult {
        for (key in bundle.keySet()) {
            val value = bundle.get(key)
            
            val result = when (value) {
                is String -> validateStringValue(key, value)
                is Bundle -> validateBundle(value)
                is Array<*> -> validateArray(key, value)
                else -> ValidationResult.allowed() // Non-string types are generally safe
            }
            
            if (result.isDenied()) {
                return result
            }
        }
        
        return ValidationResult.allowed()
    }
    
    /**
     * Validates a string value for injection patterns and length.
     * 
     * @param key The key name (for error reporting)
     * @param value The string value to validate
     * @return ValidationResult indicating if the string is safe
     */
    private fun validateStringValue(key: String, value: String): ValidationResult {
        // Check length limit
        if (value.length > MAX_STRING_EXTRA_LENGTH) {
            return ValidationResult.denied(
                DenialReason.MALFORMED_EXTRAS,
                "String extra '$key' exceeds maximum length of $MAX_STRING_EXTRA_LENGTH"
            )
        }
        
        // Check for injection patterns
        if (containsInjectionPatterns(value)) {
            return ValidationResult.denied(
                DenialReason.INJECTION_DETECTED,
                "Potential injection pattern detected in extra '$key'"
            )
        }
        
        return ValidationResult.allowed()
    }
    
    /**
     * Validates an array of values.
     * 
     * @param key The key name (for error reporting)
     * @param array The array to validate
     * @return ValidationResult indicating if the array is safe
     */
    private fun validateArray(key: String, array: Array<*>): ValidationResult {
        for ((index, item) in array.withIndex()) {
            if (item is String) {
                val result = validateStringValue("$key[$index]", item)
                if (result.isDenied()) {
                    return result
                }
            }
        }
        return ValidationResult.allowed()
    }
    
    /**
     * Checks if a string contains any injection patterns.
     * 
     * @param value The string to check
     * @return true if injection patterns detected, false otherwise
     */
    fun containsInjectionPatterns(value: String): Boolean {
        return ALL_INJECTION_PATTERNS.any { pattern ->
            pattern.containsMatchIn(value)
        }
    }
    
    /**
     * Checks specifically for SQL injection patterns.
     * 
     * @param value The string to check
     * @return true if SQL injection patterns detected
     */
    fun containsSqlInjection(value: String): Boolean {
        return SQL_INJECTION_PATTERNS.any { it.containsMatchIn(value) }
    }
    
    /**
     * Checks specifically for XSS patterns.
     * 
     * @param value The string to check
     * @return true if XSS patterns detected
     */
    fun containsXssPatterns(value: String): Boolean {
        return XSS_PATTERNS.any { it.containsMatchIn(value) }
    }
    
    /**
     * Checks specifically for template injection patterns.
     * 
     * @param value The string to check
     * @return true if template injection patterns detected
     */
    fun containsTemplateInjection(value: String): Boolean {
        return TEMPLATE_INJECTION_PATTERNS.any { it.containsMatchIn(value) }
    }
    
    /**
     * Sanitizes a string value by encoding special characters.
     * This prevents injection attacks when the string is used in HTML or SQL contexts.
     * 
     * @param value The string to sanitize
     * @return Sanitized string safe for use
     */
    fun sanitizeString(value: String): String {
        if (value.isEmpty()) return value
        
        val result = StringBuilder(value.length)
        
        for (char in value) {
            val encoded = SPECIAL_CHARACTERS[char]
            if (encoded != null) {
                result.append(encoded)
            } else {
                result.append(char)
            }
        }
        
        return result.toString()
    }
    
    /**
     * Validates and sanitizes a string, returning null if invalid.
     * 
     * @param value The string to validate and sanitize
     * @return Sanitized string if valid, null if injection detected or too long
     */
    fun validateAndSanitize(value: String): String? {
        if (value.length > MAX_STRING_EXTRA_LENGTH) return null
        if (containsInjectionPatterns(value)) return null
        return sanitizeString(value)
    }
    
    /**
     * Checks if a string exceeds the maximum allowed length.
     * 
     * @param value The string to check
     * @return true if the string exceeds MAX_STRING_EXTRA_LENGTH
     */
    fun exceedsMaxLength(value: String): Boolean {
        return value.length > MAX_STRING_EXTRA_LENGTH
    }
}
