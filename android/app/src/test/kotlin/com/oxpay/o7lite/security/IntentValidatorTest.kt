package com.oxpay.o7lite.security

import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.kotest.property.Arb
import io.kotest.property.arbitrary.string
import io.kotest.property.arbitrary.stringPattern
import io.kotest.property.arbitrary.element
import io.kotest.property.arbitrary.map
import io.kotest.property.checkAll
import io.kotest.property.forAll

/**
 * Property-based tests for IntentValidator.
 * 
 * Feature: exposed-activity-remediation
 */
class IntentValidatorTest : StringSpec({
    
    val validator = IntentValidator()
    
    // =========================================================================
    // Property 7: Injection Pattern Detection
    // Validates: Requirements 3.2
    // 
    // For any string containing SQL injection patterns, script tags, or template
    // injection syntax, the IntentValidator.containsInjectionPatterns() method
    // SHALL return true.
    // =========================================================================
    
    "Property 7: SQL injection patterns should be detected" {
        val sqlInjectionPatterns = listOf(
            "SELECT * FROM users",
            "'; DROP TABLE users; --",
            "1 OR 1=1",
            "admin'--",
            "'; DELETE FROM accounts WHERE '1'='1",
            "UNION SELECT password FROM users",
            "1; UPDATE users SET admin=1",
            "INSERT INTO logs VALUES ('hack')",
            "' AND 1=1 --",
            "'; TRUNCATE TABLE data; --"
        )
        
        forAll(Arb.element(sqlInjectionPatterns)) { pattern ->
            validator.containsInjectionPatterns(pattern)
        }
    }
    
    "Property 7: XSS patterns should be detected" {
        val xssPatterns = listOf(
            "<script>alert('xss')</script>",
            "<SCRIPT SRC=http://evil.com/xss.js></SCRIPT>",
            "javascript:alert(1)",
            "<img onerror=alert(1)>",
            "<iframe src='http://evil.com'>",
            "<object data='http://evil.com'>",
            "<embed src='http://evil.com'>",
            "<div onmouseover=alert(1)>",
            "onclick=alert(1)",
            "<script>document.cookie</script>"
        )
        
        forAll(Arb.element(xssPatterns)) { pattern ->
            validator.containsInjectionPatterns(pattern)
        }
    }
    
    "Property 7: Template injection patterns should be detected" {
        val templatePatterns = listOf(
            "\${Runtime.getRuntime().exec('cmd')}",
            "{{constructor.constructor('return this')()}}",
            "#{T(java.lang.Runtime).getRuntime().exec('cmd')}",
            "<%=system('ls')%>",
            "\${7*7}",
            "{{7*7}}",
            "#{7*7}",
            "<%=7*7%>"
        )
        
        forAll(Arb.element(templatePatterns)) { pattern ->
            validator.containsInjectionPatterns(pattern)
        }
    }
    
    "Property 7: Safe strings should not trigger injection detection" {
        val safeStrings = listOf(
            "Hello World",
            "user@example.com",
            "Payment of $100.00",
            "Order #12345",
            "Transaction completed successfully",
            "2024-01-15T10:30:00Z",
            "UTF-8 encoded: café, naïve",
            "Phone: +1-555-123-4567",
            "Normal text with numbers 123 and symbols !@#"
        )
        
        forAll(Arb.element(safeStrings)) { safeString ->
            !validator.containsInjectionPatterns(safeString)
        }
    }
    
    "Property 7: Random alphanumeric strings should not trigger injection detection" {
        checkAll(100, Arb.string(1..100, Arb.element('a'..'z') + Arb.element('A'..'Z') + Arb.element('0'..'9'))) { randomString ->
            validator.containsInjectionPatterns(randomString) shouldBe false
        }
    }
})

/**
 * Helper to create Arb from char range
 */
private operator fun Arb.Companion.element(range: CharRange): Arb<Char> = 
    Arb.element(range.toList())

private operator fun Arb<Char>.plus(other: Arb<Char>): Arb<Char> {
    return Arb.element(('a'..'z').toList() + ('A'..'Z').toList() + ('0'..'9').toList())
}


/**
 * Property-based tests for string length enforcement and sanitization.
 * 
 * Feature: exposed-activity-remediation
 */
class IntentValidatorSanitizationTest : StringSpec({
    
    val validator = IntentValidator()
    
    // =========================================================================
    // Property 8: String Length Enforcement
    // Validates: Requirements 3.3
    // 
    // For any string extra in an intent, if the string length exceeds
    // MAX_STRING_EXTRA_LENGTH (4096), the IntentValidator SHALL reject the intent.
    // =========================================================================
    
    "Property 8: Strings at or below max length should be accepted" {
        checkAll(100, Arb.string(0..IntentValidator.MAX_STRING_EXTRA_LENGTH)) { str ->
            validator.exceedsMaxLength(str) shouldBe false
        }
    }
    
    "Property 8: Strings exceeding max length should be rejected" {
        // Generate strings that are definitely over the limit
        val overLimitArb = Arb.string(
            IntentValidator.MAX_STRING_EXTRA_LENGTH + 1..IntentValidator.MAX_STRING_EXTRA_LENGTH + 1000
        )
        
        checkAll(100, overLimitArb) { str ->
            validator.exceedsMaxLength(str) shouldBe true
        }
    }
    
    "Property 8: Boundary condition - exactly max length should be accepted" {
        val exactLengthString = "a".repeat(IntentValidator.MAX_STRING_EXTRA_LENGTH)
        validator.exceedsMaxLength(exactLengthString) shouldBe false
    }
    
    "Property 8: Boundary condition - one over max length should be rejected" {
        val overLengthString = "a".repeat(IntentValidator.MAX_STRING_EXTRA_LENGTH + 1)
        validator.exceedsMaxLength(overLengthString) shouldBe true
    }
    
    // =========================================================================
    // Property 9: Special Character Sanitization
    // Validates: Requirements 3.4
    // 
    // For any input string, the IntentValidator.sanitizeString() method SHALL
    // return a string where special characters are encoded or stripped, and the
    // output SHALL NOT contain unencoded special characters that could enable
    // injection attacks.
    // =========================================================================
    
    "Property 9: Sanitized output should not contain raw angle brackets" {
        val stringsWithBrackets = Arb.string(1..100).map { base ->
            base + "<script>" + base + "</script>"
        }
        
        checkAll(100, stringsWithBrackets) { input ->
            val sanitized = validator.sanitizeString(input)
            sanitized.contains('<') shouldBe false
            sanitized.contains('>') shouldBe false
        }
    }
    
    "Property 9: Sanitized output should encode special characters" {
        val specialChars = listOf('<', '>', '"', '\'', '&', '\\', '/')
        
        forAll(Arb.element(specialChars)) { char ->
            val input = "test${char}value"
            val sanitized = validator.sanitizeString(input)
            !sanitized.contains(char) || char == '&' // & might appear in encoded form
        }
    }
    
    "Property 9: Sanitization should preserve alphanumeric content" {
        checkAll(100, Arb.string(1..100, Arb.element(('a'..'z').toList()))) { alphaString ->
            val sanitized = validator.sanitizeString(alphaString)
            sanitized shouldBe alphaString
        }
    }
    
    "Property 9: Empty string sanitization should return empty string" {
        validator.sanitizeString("") shouldBe ""
    }
    
    "Property 9: Sanitization should be idempotent for safe strings" {
        checkAll(100, Arb.string(1..50, Arb.element(('a'..'z').toList() + ('0'..'9').toList()))) { safeString ->
            val firstPass = validator.sanitizeString(safeString)
            val secondPass = validator.sanitizeString(firstPass)
            // For safe strings, both passes should be identical to input
            firstPass shouldBe safeString
            secondPass shouldBe safeString
        }
    }
    
    "Property 9: Specific dangerous characters should be encoded" {
        val testCases = mapOf(
            "<" to "&lt;",
            ">" to "&gt;",
            "\"" to "&quot;",
            "'" to "&#39;",
            "\\" to "&#92;",
            "/" to "&#47;"
        )
        
        testCases.forEach { (input, expected) ->
            validator.sanitizeString(input) shouldBe expected
        }
    }
})
