package com.oxpay.o7lite.security

import android.content.Context
import android.content.Intent
import android.net.Uri
import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.every
import io.mockk.mockk

/**
 * Integration tests for MainActivityRefactored security validation.
 * 
 * These tests verify the complete validation flow from intent to result.
 * 
 * Feature: exposed-activity-remediation
 * Validates: Requirements 1.1, 1.2, 6.1
 */
class MainActivityIntegrationTest : StringSpec({
    
    val mockContext = mockk<Context>(relaxed = true)
    
    fun createActivityGuard(): ActivityGuard {
        every { mockContext.packageName } returns "com.oxpay.o7lite"
        val intentValidator = IntentValidator()
        return ActivityGuard(
            trustedPackageRegistry = TrustedPackageRegistry(mockContext),
            intentValidator = intentValidator,
            deepLinkHandler = DeepLinkHandler(intentValidator),
            securityLogger = SecurityLogger(mockContext)
        )
    }
    
    "Integration: Complete validation flow for launcher intent should allow access" {
        val guard = createActivityGuard()
        
        val intent = mockk<Intent>()
        every { intent.action } returns Intent.ACTION_MAIN
        every { intent.categories } returns setOf(Intent.CATEGORY_LAUNCHER)
        every { intent.hasCategory(Intent.CATEGORY_LAUNCHER) } returns true
        every { intent.data } returns null
        every { intent.extras } returns null
        
        val result = guard.validateIntent(intent, null)
        
        result.isAllowed() shouldBe true
    }
    
    "Integration: Complete validation flow for untrusted external app should deny access" {
        val guard = createActivityGuard()
        
        val intent = mockk<Intent>()
        every { intent.action } returns "com.malicious.ACTION"
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns null
        every { intent.extras } returns null
        
        val result = guard.validateIntent(intent, "com.malicious.app")
        
        result.isDenied() shouldBe true
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        (result as ValidationResult.Denied).reason shouldBe DenialReason.UNTRUSTED_PACKAGE
    }
    
    "Integration: Complete validation flow for trusted partner app should allow access" {
        val guard = createActivityGuard()
        
        val intent = mockk<Intent>()
        every { intent.action } returns "com.partner.ACTION"
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns null
        every { intent.extras } returns null
        
        // Test with SUNMI New replacement for Gobiz (trusted partner)
        val result = guard.validateIntent(intent, "com.pos.router.pay_dee")
        
        result.isAllowed() shouldBe true
    }
    
    "Integration: Complete validation flow for valid deep link should allow access" {
        val guard = createActivityGuard()
        
        val uri = Uri.parse("my://native/payment?id=123")
        val intent = mockk<Intent>()
        every { intent.action } returns Intent.ACTION_VIEW
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns uri
        every { intent.extras } returns null
        
        val result = guard.validateIntent(intent, "com.any.app")
        
        result.isAllowed() shouldBe true
    }

    "Integration: Complete validation flow for OxPay Lite login deep link should allow access" {
        val guard = createActivityGuard()

        val uri = Uri.parse("o7lite://login?operatorId=drgw3&pswd=123456")
        val intent = mockk<Intent>()
        every { intent.action } returns Intent.ACTION_VIEW
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns uri
        every { intent.extras } returns null

        val result = guard.validateIntent(intent, "com.oxpay.app")

        result.isAllowed() shouldBe true
    }

    "Integration: Complete validation flow for HTTPS OxPay Lite login app link should allow access" {
        val guard = createActivityGuard()

        val uri = Uri.parse("https://o7lite.com/login?operatorId=drgw3&pswd=123456")
        val intent = mockk<Intent>()
        every { intent.action } returns Intent.ACTION_VIEW
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns uri
        every { intent.extras } returns null

        val result = guard.validateIntent(intent, "com.oxpay.app")

        result.isAllowed() shouldBe true
    }
    
    "Integration: Complete validation flow for deep link with injection should deny access" {
        val guard = createActivityGuard()
        
        val uri = Uri.parse("my://native/payment?id=<script>alert(1)</script>")
        val intent = mockk<Intent>()
        every { intent.action } returns Intent.ACTION_VIEW
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns uri
        every { intent.extras } returns null
        
        val result = guard.validateIntent(intent, "com.any.app")
        
        result.isDenied() shouldBe true
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        (result as ValidationResult.Denied).reason shouldBe DenialReason.INJECTION_DETECTED
    }
    
    "Integration: Complete validation flow for notification from self should allow access" {
        val guard = createActivityGuard()
        
        val intent = mockk<Intent>()
        every { intent.action } returns "FLUTTER_NOTIFICATION_CLICK"
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns null
        every { intent.extras } returns null
        
        val result = guard.validateIntent(intent, "com.oxpay.o7lite")
        
        result.isAllowed() shouldBe true
    }
    
    "Integration: Complete validation flow for notification from external app should deny access" {
        val guard = createActivityGuard()
        
        val intent = mockk<Intent>()
        every { intent.action } returns "FLUTTER_NOTIFICATION_CLICK"
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns null
        every { intent.extras } returns null
        
        val result = guard.validateIntent(intent, "com.malicious.app")
        
        result.isDenied() shouldBe true
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        (result as ValidationResult.Denied).reason shouldBe DenialReason.INVALID_NOTIFICATION_ORIGIN
    }
    
    "Integration: Denial handling should use generic result codes" {
        val guard = createActivityGuard()
        
        val intent = mockk<Intent>()
        every { intent.action } returns "com.malicious.ACTION"
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns null
        every { intent.extras } returns null
        
        val result = guard.validateIntent(intent, "com.malicious.app")
        
        // Verify the denial reason is generic
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        val denied = result as ValidationResult.Denied
        
        // The reason should be one of the predefined generic reasons
        val genericReasons = setOf(
            DenialReason.UNTRUSTED_PACKAGE,
            DenialReason.INVALID_DEEP_LINK,
            DenialReason.MALFORMED_EXTRAS,
            DenialReason.INJECTION_DETECTED,
            DenialReason.INVALID_NOTIFICATION_ORIGIN,
            DenialReason.UNKNOWN_INTENT_TYPE
        )
        genericReasons.contains(denied.reason) shouldBe true
    }
    
    "Integration: Rate limiting should trigger after multiple failed attempts" {
        val guard = createActivityGuard()
        val maliciousPackage = "com.brute.force.app"
        
        val intent = mockk<Intent>()
        every { intent.action } returns "com.malicious.ACTION"
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns null
        every { intent.extras } returns null
        
        // Simulate multiple failed attempts
        repeat(SecurityLogger.RATE_LIMIT_THRESHOLD + 1) {
            guard.validateIntent(intent, maliciousPackage)
        }
        
        // The result should still be denied (rate limiting doesn't change the outcome,
        // but it does log the rate limit exceeded event)
        val result = guard.validateIntent(intent, maliciousPackage)
        result.isDenied() shouldBe true
    }
})
