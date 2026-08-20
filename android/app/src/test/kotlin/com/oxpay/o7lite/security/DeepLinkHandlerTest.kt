package com.oxpay.o7lite.security

import android.content.Intent
import android.net.Uri
import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.property.Arb
import io.kotest.property.arbitrary.element
import io.kotest.property.arbitrary.string
import io.kotest.property.arbitrary.map
import io.kotest.property.checkAll
import io.kotest.property.forAll
import io.mockk.every
import io.mockk.mockk

/**
 * Property-based tests for DeepLinkHandler.
 * 
 * Feature: exposed-activity-remediation
 */
class DeepLinkHandlerTest : StringSpec({
    
    val intentValidator = IntentValidator()
    val handler = DeepLinkHandler(intentValidator)
    
    // =========================================================================
    // Property 5: Deep Link Validation and Rejection
    // Validates: Requirements 2.1, 2.2, 2.4
    // 
    // For any deep link intent with scheme "my" and host "native", if the URI
    // data is malformed or missing required fields, the DeepLinkHandler SHALL
    // return a Denied ValidationResult.
    // =========================================================================
    
    "Property 5: Valid deep links should be accepted" {
        val validPaths = listOf("", "/", "/home", "/payment", "/settings")
        
        forAll(Arb.element(validPaths)) { path ->
            val uri = Uri.parse("my://native$path")
            val intent = mockk<Intent>()
            every { intent.data } returns uri
            
            val result = handler.validateDeepLink(intent)
            result.isAllowed()
        }
    }
    
    "Property 5: Deep links with wrong scheme should be rejected" {
        val wrongSchemes = listOf("http", "https", "app", "custom", "file")
        
        forAll(Arb.element(wrongSchemes)) { scheme ->
            val uri = Uri.parse("$scheme://native/path")
            val intent = mockk<Intent>()
            every { intent.data } returns uri
            
            val result = handler.validateDeepLink(intent)
            result.isDenied()
        }
    }
    
    "Property 5: Deep links with wrong host should be rejected" {
        val wrongHosts = listOf("evil.com", "localhost", "other", "malicious")
        
        forAll(Arb.element(wrongHosts)) { host ->
            val uri = Uri.parse("my://$host/path")
            val intent = mockk<Intent>()
            every { intent.data } returns uri
            
            val result = handler.validateDeepLink(intent)
            result.isDenied()
        }
    }
    
    "Property 5: Deep links with null URI should be rejected" {
        val intent = mockk<Intent>()
        every { intent.data } returns null
        
        val result = handler.validateDeepLink(intent)
        result.isDenied() shouldBe true
        result.shouldBeInstanceOf<ValidationResult.Denied>()
        (result as ValidationResult.Denied).reason shouldBe DenialReason.INVALID_DEEP_LINK
    }
    
    "Property 5: Deep links with injection in parameters should be rejected" {
        val injectionPayloads = listOf(
            "<script>alert(1)</script>",
            "'; DROP TABLE users; --",
            "\${Runtime.getRuntime().exec('cmd')}"
        )
        
        forAll(Arb.element(injectionPayloads)) { payload ->
            val encodedPayload = Uri.encode(payload)
            val uri = Uri.parse("my://native/path?param=$encodedPayload")
            val intent = mockk<Intent>()
            every { intent.data } returns uri
            
            val result = handler.validateDeepLink(intent)
            result.isDenied()
        }
    }
    
    "Property 5: Deep links with valid parameters should be accepted" {
        val validParams = listOf(
            "id=123",
            "name=John",
            "action=view",
            "token=abc123def456"
        )
        
        forAll(Arb.element(validParams)) { param ->
            val uri = Uri.parse("my://native/path?$param")
            val intent = mockk<Intent>()
            every { intent.data } returns uri
            
            val result = handler.validateDeepLink(intent)
            result.isAllowed()
        }
    }

    "OxPay Lite login deep link with operatorId and pswd should be accepted" {
        val uri = Uri.parse("o7lite://login?operatorId=drgw3&pswd=123456")
        val intent = mockk<Intent>()
        every { intent.data } returns uri

        val result = handler.validateDeepLink(intent)

        result.isAllowed() shouldBe true
    }

    "HTTPS login app link with operatorId and pswd should be accepted" {
        val uri = Uri.parse("https://o7lite.com/login?operatorId=drgw3&pswd=123456")
        val intent = mockk<Intent>()
        every { intent.data } returns uri

        val result = handler.validateDeepLink(intent)

        result.isAllowed() shouldBe true
    }

    "OxPay Lite login deep link missing required params should still validate as a safe app link" {
        val uri = Uri.parse("o7lite://login?operatorId=drgw3")
        val intent = mockk<Intent>()
        every { intent.data } returns uri

        val result = handler.validateDeepLink(intent)

        result.isAllowed() shouldBe true
    }
})

/**
 * Property-based tests for deep link parameter sanitization.
 * 
 * Feature: exposed-activity-remediation
 */
class DeepLinkSanitizationTest : StringSpec({
    
    val intentValidator = IntentValidator()
    val handler = DeepLinkHandler(intentValidator)
    
    // =========================================================================
    // Property 6: Deep Link Parameter Sanitization
    // Validates: Requirements 2.3
    // 
    // For any valid deep link URI, all extracted parameters SHALL be sanitized
    // such that the output contains no injection patterns.
    // =========================================================================
    
    "Property 6: Extracted parameters should be sanitized" {
        val uri = Uri.parse("my://native/path?name=<test>&value=normal")
        
        val params = handler.extractParameters(uri)
        
        // The < character should be encoded
        params["name"]?.contains('<') shouldBe false
        params["value"] shouldBe "normal"
    }
    
    "Property 6: Special characters in parameters should be encoded" {
        val specialChars = listOf('<', '>', '"', '\'')
        
        forAll(Arb.element(specialChars)) { char ->
            val uri = Uri.parse("my://native/path?param=test${char}value")
            val params = handler.extractParameters(uri)
            
            // The special character should not appear raw in the output
            val paramValue = params["param"] ?: ""
            !paramValue.contains(char)
        }
    }
    
    "Property 6: Safe alphanumeric parameters should pass through unchanged" {
        checkAll(100, Arb.string(1..50, Arb.element(('a'..'z').toList()))) { safeValue ->
            val uri = Uri.parse("my://native/path?param=$safeValue")
            val params = handler.extractParameters(uri)
            
            params["param"] shouldBe safeValue
        }
    }
    
    "Property 6: Empty parameters should be handled" {
        val uri = Uri.parse("my://native/path")
        val params = handler.extractParameters(uri)
        
        params.isEmpty() shouldBe true
    }
    
    "Property 6: Path extraction should sanitize special characters" {
        val uri = Uri.parse("my://native/<script>alert(1)</script>")
        val path = handler.extractPath(uri)
        
        path.contains('<') shouldBe false
        path.contains('>') shouldBe false
    }
})
