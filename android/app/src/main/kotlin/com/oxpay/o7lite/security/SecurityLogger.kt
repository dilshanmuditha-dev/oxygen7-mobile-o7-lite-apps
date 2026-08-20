package com.oxpay.o7lite.security

import android.content.Context
import com.oxpay.o7lite.utils.LogUtil

/**
 * Logs security-related events for auditing and attack detection.
 * Implements rate limiting to detect potential brute-force attacks.
 */
class SecurityLogger(private val context: Context) {
    
    companion object {
        private const val TAG = "SecurityAudit"
        
        /** Time window for rate limiting (60 seconds) */
        const val RATE_LIMIT_WINDOW_MS = 60_000L
        
        /** Maximum failed attempts before flagging as potential attack */
        const val RATE_LIMIT_THRESHOLD = 5
        
        /** Maximum entries to track per package to prevent memory issues */
        private const val MAX_ENTRIES_PER_PACKAGE = 100
        
        /** Maximum packages to track to prevent memory issues */
        private const val MAX_TRACKED_PACKAGES = 50
    }
    
    /** Track failed attempts per package for rate limiting */
    private val failedAttempts = mutableMapOf<String, MutableList<Long>>()
    
    /** Lock for thread-safe access to failedAttempts */
    private val lock = Any()
    
    /**
     * Logs a security event.
     * 
     * @param event The security event to log
     */
    fun logEvent(event: SecurityEvent) {
        val logMessage = event.toLogString()
        
        when (event.eventType) {
            SecurityEventType.ACCESS_ALLOWED -> {
                LogUtil.i(TAG, logMessage)
            }
            SecurityEventType.ACCESS_DENIED -> {
                LogUtil.w(TAG, logMessage)
            }
            SecurityEventType.RATE_LIMIT_EXCEEDED -> {
                LogUtil.e(TAG, "SECURITY ALERT: $logMessage")
            }
            SecurityEventType.INJECTION_ATTEMPT_DETECTED -> {
                LogUtil.e(TAG, "SECURITY ALERT: $logMessage")
            }
        }
    }
    
    /**
     * Logs an allowed access event.
     * 
     * @param callingPackage The package that was allowed
     * @param intentAction The intent action
     */
    fun logAllowed(callingPackage: String?, intentAction: String?) {
        logEvent(SecurityEvent.allowed(callingPackage, intentAction))
    }
    
    /**
     * Logs a denied access event and records the failed attempt.
     * 
     * @param callingPackage The package that was denied
     * @param intentAction The intent action
     * @param reason The reason for denial
     * @param details Additional details
     */
    fun logDenied(
        callingPackage: String?,
        intentAction: String?,
        reason: DenialReason,
        details: String? = null
    ) {
        logEvent(SecurityEvent.denied(callingPackage, intentAction, reason, details))
        
        // Record failed attempt for rate limiting
        callingPackage?.let { recordFailedAttempt(it) }
    }
    
    /**
     * Checks if a package has exceeded the rate limit for failed attempts.
     * 
     * @param packageName The package to check
     * @return true if rate limit exceeded, false otherwise
     */
    fun isRateLimitExceeded(packageName: String): Boolean {
        synchronized(lock) {
            val attempts = failedAttempts[packageName] ?: return false
            val now = System.currentTimeMillis()
            
            // Count attempts within the time window
            val recentAttempts = attempts.count { timestamp ->
                now - timestamp < RATE_LIMIT_WINDOW_MS
            }
            
            return recentAttempts >= RATE_LIMIT_THRESHOLD
        }
    }
    
    /**
     * Records a failed access attempt for rate limiting.
     * 
     * @param packageName The package that failed
     */
    fun recordFailedAttempt(packageName: String) {
        synchronized(lock) {
            // Prevent tracking too many packages
            if (failedAttempts.size >= MAX_TRACKED_PACKAGES && 
                !failedAttempts.containsKey(packageName)) {
                cleanupOldestPackage()
            }
            
            val attempts = failedAttempts.getOrPut(packageName) { mutableListOf() }
            val now = System.currentTimeMillis()
            
            // Add new attempt
            attempts.add(now)
            
            // Cleanup old entries for this package
            cleanupOldEntries(attempts, now)
            
            // Check if rate limit is now exceeded
            if (isRateLimitExceeded(packageName)) {
                logEvent(SecurityEvent.rateLimitExceeded(packageName, attempts.size))
            }
        }
    }
    
    /**
     * Cleans up entries older than the rate limit window.
     */
    private fun cleanupOldEntries(attempts: MutableList<Long>, now: Long) {
        attempts.removeAll { timestamp ->
            now - timestamp >= RATE_LIMIT_WINDOW_MS
        }
        
        // Also limit total entries per package
        while (attempts.size > MAX_ENTRIES_PER_PACKAGE) {
            attempts.removeAt(0)
        }
    }
    
    /**
     * Removes the oldest tracked package to prevent memory issues.
     */
    private fun cleanupOldestPackage() {
        if (failedAttempts.isEmpty()) return
        
        // Find package with oldest last attempt
        var oldestPackage: String? = null
        var oldestTime = Long.MAX_VALUE
        
        for ((pkg, attempts) in failedAttempts) {
            val lastAttempt = attempts.lastOrNull() ?: 0L
            if (lastAttempt < oldestTime) {
                oldestTime = lastAttempt
                oldestPackage = pkg
            }
        }
        
        oldestPackage?.let { failedAttempts.remove(it) }
    }
    
    /**
     * Gets the count of recent failed attempts for a package.
     * 
     * @param packageName The package to check
     * @return Number of failed attempts in the rate limit window
     */
    fun getRecentFailedAttemptCount(packageName: String): Int {
        synchronized(lock) {
            val attempts = failedAttempts[packageName] ?: return 0
            val now = System.currentTimeMillis()
            
            return attempts.count { timestamp ->
                now - timestamp < RATE_LIMIT_WINDOW_MS
            }
        }
    }
    
    /**
     * Clears all tracked failed attempts.
     * Useful for testing or when resetting security state.
     */
    fun clearFailedAttempts() {
        synchronized(lock) {
            failedAttempts.clear()
        }
    }
    
    /**
     * Clears failed attempts for a specific package.
     * 
     * @param packageName The package to clear
     */
    fun clearFailedAttemptsForPackage(packageName: String) {
        synchronized(lock) {
            failedAttempts.remove(packageName)
        }
    }
}
