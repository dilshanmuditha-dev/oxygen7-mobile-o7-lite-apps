package com.oxpay.o7lite.security

import android.content.Context
import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldNotContain
import io.kotest.property.Arb
import io.kotest.property.arbitrary.element
import io.kotest.property.arbitrary.string
import io.kotest.property.checkAll
import io.kotest.property.forAll
import io.mockk.mockk

/**
 * Property-based tests for SecurityLogger.
 * 
 * Feature: exposed-activity-remediation
 */
class SecurityLoggerTest : StringSpec({
    
    val mockContext = mockk<Context>(relaxed = true)
    
    // =========================================================================
    // Property 4: Security Event Logging Completeness
    // Validates: Requirements 1.5, 5.1, 5.2
    // 
    // For any intent processed by ActivityGuard (whether allowed or denied),
    // a SecurityEvent SHALL be logged containing the intent action, calling
    // package, and timestamp. For denied intents, the denial reason SHALL
    // also be included.
    // =========================================================================
    
    "Property 4: Allowed events should contain package and action in log string" {
        val packages = listOf("com.test.app", "com.other.app", null)
        val actions = listOf("android.intent.action.MAIN", "FLUTTER_NOTIFICATION_CLICK", null)
        
        checkAll(Arb.element(packages), Arb.element(actions)) { pkg, action ->
            val event = SecurityEvent.allowed(pkg, action)
            val logString = event.toLogString()
            
            logString shouldContain "ACCESS_ALLOWED"
            if (pkg != null) {
                logString shouldContain pkg
            }
        }
    }
    
    "Property 4: Denied events should contain reason in log string" {
        val reasons = DenialReason.values().toList()
        
        forAll(Arb.element(reasons)) { reason ->
            val event = SecurityEvent.denied("com.test.app", "action", reason)
            val logString = event.toLogString()
            
            logString.contains("ACCESS_DENIED") && logString.contains(reason.name)
        }
    }
    
    "Property 4: Events should have valid timestamps" {
        val beforeCreation = System.currentTimeMillis()
        val event = SecurityEvent.allowed("com.test.app", "action")
        val afterCreation = System.currentTimeMillis()
        
        event.timestamp >= beforeCreation shouldBe true
        event.timestamp <= afterCreation shouldBe true
    }
    
    "Property 4: All event types should produce valid log strings" {
        val eventTypes = SecurityEventType.values().toList()
        
        forAll(Arb.element(eventTypes)) { eventType ->
            val event = SecurityEvent(
                eventType = eventType,
                callingPackage = "com.test.app",
                intentAction = "test.action"
            )
            val logString = event.toLogString()
            
            logString.isNotEmpty() && logString.contains(eventType.name)
        }
    }
})

/**
 * Property-based tests for rate limiting.
 * 
 * Feature: exposed-activity-remediation
 */
class SecurityLoggerRateLimitTest : StringSpec({
    
    val mockContext = mockk<Context>(relaxed = true)
    
    // =========================================================================
    // Property 10: Rate Limiting for Failed Attempts
    // Validates: Requirements 5.3
    // 
    // For any package that has more than RATE_LIMIT_THRESHOLD (5) failed access
    // attempts within RATE_LIMIT_WINDOW_MS (60 seconds), the
    // SecurityLogger.isRateLimitExceeded() method SHALL return true.
    // =========================================================================
    
    "Property 10: Rate limit should not be exceeded with fewer than threshold attempts" {
        val logger = SecurityLogger(mockContext)
        val packageName = "com.test.app"
        
        // Record fewer than threshold attempts
        repeat(SecurityLogger.RATE_LIMIT_THRESHOLD - 1) {
            logger.recordFailedAttempt(packageName)
        }
        
        logger.isRateLimitExceeded(packageName) shouldBe false
    }
    
    "Property 10: Rate limit should be exceeded at threshold" {
        val logger = SecurityLogger(mockContext)
        val packageName = "com.test.app"
        
        // Record exactly threshold attempts
        repeat(SecurityLogger.RATE_LIMIT_THRESHOLD) {
            logger.recordFailedAttempt(packageName)
        }
        
        logger.isRateLimitExceeded(packageName) shouldBe true
    }
    
    "Property 10: Rate limit should be exceeded above threshold" {
        val logger = SecurityLogger(mockContext)
        val packageName = "com.test.app"
        
        // Record more than threshold attempts
        repeat(SecurityLogger.RATE_LIMIT_THRESHOLD + 5) {
            logger.recordFailedAttempt(packageName)
        }
        
        logger.isRateLimitExceeded(packageName) shouldBe true
    }
    
    "Property 10: Different packages should have independent rate limits" {
        val logger = SecurityLogger(mockContext)
        
        // Exceed rate limit for package A
        repeat(SecurityLogger.RATE_LIMIT_THRESHOLD) {
            logger.recordFailedAttempt("com.package.a")
        }
        
        // Package B should not be affected
        logger.isRateLimitExceeded("com.package.a") shouldBe true
        logger.isRateLimitExceeded("com.package.b") shouldBe false
    }
    
    "Property 10: Unknown packages should not have rate limit exceeded" {
        val logger = SecurityLogger(mockContext)
        
        logger.isRateLimitExceeded("com.unknown.package") shouldBe false
    }
    
    "Property 10: Clearing attempts should reset rate limit" {
        val logger = SecurityLogger(mockContext)
        val packageName = "com.test.app"
        
        // Exceed rate limit
        repeat(SecurityLogger.RATE_LIMIT_THRESHOLD) {
            logger.recordFailedAttempt(packageName)
        }
        
        logger.isRateLimitExceeded(packageName) shouldBe true
        
        // Clear and verify
        logger.clearFailedAttemptsForPackage(packageName)
        logger.isRateLimitExceeded(packageName) shouldBe false
    }
})

/**
 * Property-based tests for sensitive data exclusion.
 * 
 * Feature: exposed-activity-remediation
 */
class SecurityLoggerSensitiveDataTest : StringSpec({
    
    // =========================================================================
    // Property 11: Sensitive Data Exclusion from Logs
    // Validates: Requirements 5.4
    // 
    // For any SecurityEvent converted to log string via toLogString(), the
    // output SHALL NOT contain patterns matching authentication tokens,
    // payment card numbers, or other sensitive data patterns.
    // =========================================================================
    
    "Property 11: Bearer tokens should be redacted from log output" {
        val sensitiveDetails = "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test"
        val event = SecurityEvent.allowed("com.test.app", "action", sensitiveDetails)
        val logString = event.toLogString()
        
        logString shouldNotContain "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        logString shouldContain "[REDACTED]"
    }
    
    "Property 11: Credit card numbers should be redacted from log output" {
        val sensitiveDetails = "Card: 4111111111111111"
        val event = SecurityEvent.allowed("com.test.app", "action", sensitiveDetails)
        val logString = event.toLogString()
        
        logString shouldNotContain "4111111111111111"
        logString shouldContain "[REDACTED]"
    }
    
    "Property 11: Password patterns should be redacted from log output" {
        val sensitiveDetails = "password=secretPassword123"
        val event = SecurityEvent.allowed("com.test.app", "action", sensitiveDetails)
        val logString = event.toLogString()
        
        logString shouldNotContain "secretPassword123"
        logString shouldContain "[REDACTED]"
    }
    
    "Property 11: API keys should be redacted from log output" {
        val sensitiveDetails = "api_key=sk_live_abcdef123456"
        val event = SecurityEvent.allowed("com.test.app", "action", sensitiveDetails)
        val logString = event.toLogString()
        
        logString shouldNotContain "sk_live_abcdef123456"
        logString shouldContain "[REDACTED]"
    }
    
    "Property 11: Non-sensitive data should not be redacted" {
        val safeDetails = "User clicked button on home screen"
        val event = SecurityEvent.allowed("com.test.app", "action", safeDetails)
        val logString = event.toLogString()
        
        logString shouldContain safeDetails
        logString shouldNotContain "[REDACTED]"
    }
    
    "Property 11: Multiple sensitive patterns should all be redacted" {
        val sensitiveDetails = "token=abc123 password=secret card=4111111111111111"
        val event = SecurityEvent.allowed("com.test.app", "action", sensitiveDetails)
        val logString = event.toLogString()
        
        logString shouldNotContain "abc123"
        logString shouldNotContain "secret"
        logString shouldNotContain "4111111111111111"
    }
})
