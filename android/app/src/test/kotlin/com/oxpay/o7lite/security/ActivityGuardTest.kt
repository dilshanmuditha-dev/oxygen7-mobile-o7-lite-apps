package com.oxpay.o7lite.security

import android.content.Context
import android.content.Intent
import android.net.Uri
import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.property.Arb
import io.kotest.property.arbitrary.element
import io.kotest.property.arbitrary.string
import io.kotest.property.forAll
import io.mockk.every
import io.mockk.mockk

/**
 * Property-based tests for ActivityGuard.
 * 
 * Feature: exposed-activity-remediation
 */
class ActivityGuardTest : StringSpec({
    
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
    
    // =========================================================================
    // Property 1: Trusted Package Access Control
    // Validates: Requirements 1.1, 1.2
    // 
    // For any package name and non-launcher intent, the ActivityGuard SHALL
    // allow access if and only if the package is in the TrustedPackageRegistry.
    // =========================================================================
    
    "Property 1: Trusted packages should be allowed for external intents" {
        val guard = createActivityGuard()
        val trustedPackages = listOf(
            "com.cardbiz.razercredits1",
            "woyou.aidlservice.jiuiv5",
//            "sunmi.pay.u_mobile",
            "com.pos.router.pay_dee",
            "com.sc.mf919",
            "com.mscardpayments.app",
            "com.landiconnect.appstore"
        )
        
        forAll(Arb.element(trustedPackages)) { packageName ->
            val intent = mockk<Intent>()
            every { intent.action } returns "com.test.ACTION"
            every { intent.categories } returns null
            every { intent.data } returns null
            every { intent.extras } returns null
            every { intent.hasCategory(any()) } returns false
            
            val result = guard.validateIntent(intent, packageName)
            result.isAllowed()
        }
    }
    
    "Property 1: Untrusted packages should be denied for external intents" {
        val guard = createActivityGuard()
        val untrustedPackages = listOf(
            "com.malicious.app",
            "com.unknown.package",
            "com.hacker.tool",
            "com.random.app"
        )
        
        forAll(Arb.element(untrustedPackages)) { packageName ->
            val intent = mockk<Intent>()
            every { intent.action } returns "com.test.ACTION"
            every { intent.categories } returns null
            every { intent.data } returns null
            every { intent.extras } returns null
            every { intent.hasCategory(any()) } returns false
            
            val result = guard.validateIntent(intent, packageName)
            result.isDenied()
        }
    }
    
    "Property 1: Null package should be denied for external intents" {
        val guard = createActivityGuard()
        
        val intent = mockk<Intent>()
        every { intent.action } returns "com.test.ACTION"
        every { intent.categories } returns null
        every { intent.data } returns null
        every { intent.extras } returns null
        every { intent.hasCategory(any()) } returns false
        
        val result = guard.validateIntent(intent, null)
        result.isDenied() shouldBe true
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        (result as ValidationResult.Denied).reason shouldBe DenialReason.UNTRUSTED_PACKAGE
    }
    
    // =========================================================================
    // Property 2: Launcher Intent Bypass
    // Validates: Requirements 1.3
    // 
    // For any intent with action MAIN and category LAUNCHER, the ActivityGuard
    // SHALL allow access regardless of the calling package name.
    // =========================================================================
    
    "Property 2: Launcher intents should be allowed regardless of package" {
        val guard = createActivityGuard()
        val packages = listOf(
            "com.malicious.app",
            "com.unknown.package",
            null,
            "com.random.app"
        )
        
        forAll(Arb.element(packages)) { packageName ->
            val intent = mockk<Intent>()
            every { intent.action } returns Intent.ACTION_MAIN
            every { intent.categories } returns setOf(Intent.CATEGORY_LAUNCHER)
            every { intent.hasCategory(Intent.CATEGORY_LAUNCHER) } returns true
            every { intent.data } returns null
            every { intent.extras } returns null
            
            val result = guard.validateIntent(intent, packageName)
            result.isAllowed()
        }
    }
    
    "Property 2: Launcher intent classification should be correct" {
        val guard = createActivityGuard()
        
        val intent = mockk<Intent>()
        every { intent.action } returns Intent.ACTION_MAIN
        every { intent.categories } returns setOf(Intent.CATEGORY_LAUNCHER)
        every { intent.hasCategory(Intent.CATEGORY_LAUNCHER) } returns true
        every { intent.data } returns null
        
        guard.classifyIntent(intent) shouldBe IntentType.LAUNCHER
    }
    
    // =========================================================================
    // Property 3: Notification Intent Self-Origin Validation
    // Validates: Requirements 1.4
    // 
    // For any intent with action FLUTTER_NOTIFICATION_CLICK, the ActivityGuard
    // SHALL allow access only if the intent originated from the application's
    // own package.
    // =========================================================================
    
    "Property 3: Notification intents from self should be allowed" {
        val guard = createActivityGuard()
        val selfPackages = listOf("com.oxpay.o7lite", "com.oxpay.o7lite")
        
        forAll(Arb.element(selfPackages)) { packageName ->
            val intent = mockk<Intent>()
            every { intent.action } returns "FLUTTER_NOTIFICATION_CLICK"
            every { intent.categories } returns null
            every { intent.hasCategory(any()) } returns false
            every { intent.data } returns null
            every { intent.extras } returns null
            
            val result = guard.validateIntent(intent, packageName)
            result.isAllowed()
        }
    }
    
    "Property 3: Notification intents from external packages should be denied" {
        val guard = createActivityGuard()
        val externalPackages = listOf(
            "com.malicious.app",
            "com.other.app",
            null
        )
        
        forAll(Arb.element(externalPackages)) { packageName ->
            val intent = mockk<Intent>()
            every { intent.action } returns "FLUTTER_NOTIFICATION_CLICK"
            every { intent.categories } returns null
            every { intent.hasCategory(any()) } returns false
            every { intent.data } returns null
            every { intent.extras } returns null
            
            val result = guard.validateIntent(intent, packageName)
            result.isDenied()
        }
    }
    
    "Property 3: Notification intent from external package should have correct denial reason" {
        val guard = createActivityGuard()
        
        val intent = mockk<Intent>()
        every { intent.action } returns "FLUTTER_NOTIFICATION_CLICK"
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns null
        every { intent.extras } returns null
        
        val result = guard.validateIntent(intent, "com.malicious.app")
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        (result as ValidationResult.Denied).reason shouldBe DenialReason.INVALID_NOTIFICATION_ORIGIN
    }
})

/**
 * Property-based tests for generic denial handling.
 * 
 * Feature: exposed-activity-remediation
 */
class ActivityGuardDenialTest : StringSpec({
    
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
    
    // =========================================================================
    // Property 12: Generic Denial Result Code
    // Validates: Requirements 6.1, 6.2
    // 
    // For any denied intent, the ValidationResult SHALL be of type Denied with
    // a DenialReason that does not expose internal security mechanism details
    // to the caller.
    // =========================================================================
    
    "Property 12: Denied results should have valid denial reasons" {
        val guard = createActivityGuard()
        val validReasons = DenialReason.values().toSet()
        
        // Test with untrusted package
        val intent = mockk<Intent>()
        every { intent.action } returns "com.test.ACTION"
        every { intent.categories } returns null
        every { intent.data } returns null
        every { intent.extras } returns null
        every { intent.hasCategory(any()) } returns false
        
        val result = guard.validateIntent(intent, "com.untrusted.app")
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        validReasons.contains((result as ValidationResult.Denied).reason) shouldBe true
    }
    
    "Property 12: Denial reasons should be generic and not expose internals" {
        // All denial reasons should be generic categories
        val genericReasons = setOf(
            DenialReason.UNTRUSTED_PACKAGE,
            DenialReason.INVALID_DEEP_LINK,
            DenialReason.MALFORMED_EXTRAS,
            DenialReason.INJECTION_DETECTED,
            DenialReason.INVALID_NOTIFICATION_ORIGIN,
            DenialReason.UNKNOWN_INTENT_TYPE
        )
        
        // Verify all enum values are in our expected set
        DenialReason.values().toSet() shouldBe genericReasons
    }
    
    "Property 12: Null intent should result in denial with UNKNOWN_INTENT_TYPE" {
        val guard = createActivityGuard()
        
        val result = guard.validateIntent(null, "com.test.app")
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        (result as ValidationResult.Denied).reason shouldBe DenialReason.UNKNOWN_INTENT_TYPE
    }
    
    "Property 12: Deep link with injection should result in INJECTION_DETECTED" {
        val guard = createActivityGuard()
        
        val uri = Uri.parse("my://native/path?param=<script>alert(1)</script>")
        val intent = mockk<Intent>()
        every { intent.action } returns Intent.ACTION_VIEW
        every { intent.categories } returns null
        every { intent.hasCategory(any()) } returns false
        every { intent.data } returns uri
        every { intent.extras } returns null
        
        val result = guard.validateIntent(intent, "com.test.app")
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        (result as ValidationResult.Denied).reason shouldBe DenialReason.INJECTION_DETECTED
    }
})
