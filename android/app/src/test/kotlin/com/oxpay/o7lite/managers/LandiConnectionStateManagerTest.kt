package com.oxpay.o7lite.managers

import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.kotest.property.Arb
import io.kotest.property.arbitrary.int
import io.kotest.property.forAll

/**
 * Unit tests for LandiConnectionStateManager.
 * 
 * Feature: landi-printer-fix
 * 
 * These tests validate Property 4: State Consistency from the design document.
 */
class LandiConnectionStateManagerTest : StringSpec({

    // =========================================================================
    // Property 4: State Consistency
    // Validates: Requirements 2.2, 2.3
    // 
    // For any OmniConnection callback, the isLandiInitSuccess flag SHALL be set 
    // to true after onConnected() and false after onDisconnected().
    // =========================================================================

    "Property 4: Initial state - isLandiInitSuccess should be false" {
        val stateManager = LandiConnectionStateManager()
        
        stateManager.isLandiInitSuccess shouldBe false
    }

    "Property 4: Initial state - retryCount should be zero" {
        val stateManager = LandiConnectionStateManager()
        
        stateManager.retryCount shouldBe 0
    }

    "Property 4: After onConnected() - isLandiInitSuccess should be true" {
        val stateManager = LandiConnectionStateManager()
        
        stateManager.onConnected()
        
        stateManager.isLandiInitSuccess shouldBe true
    }

    "Property 4: After onDisconnected() - isLandiInitSuccess should be false" {
        val stateManager = LandiConnectionStateManager()
        
        // First connect
        stateManager.onConnected()
        stateManager.isLandiInitSuccess shouldBe true
        
        // Then disconnect
        stateManager.onDisconnected(errorCode = 0)
        
        stateManager.isLandiInitSuccess shouldBe false
    }

    "Property 4: For any error code, onDisconnected() should set isLandiInitSuccess to false" {
        forAll(Arb.int(-100, 100)) { errorCode ->
            val stateManager = LandiConnectionStateManager()
            
            // Start with connected state
            stateManager.onConnected()
            
            // Disconnect with any error code
            stateManager.onDisconnected(errorCode)
            
            // State should always be false after disconnect
            !stateManager.isLandiInitSuccess
        }
    }

    "Property 4: Multiple connect/disconnect cycles should maintain state consistency" {
        val stateManager = LandiConnectionStateManager()
        
        // Cycle 1
        stateManager.onConnected()
        stateManager.isLandiInitSuccess shouldBe true
        stateManager.onDisconnected(errorCode = 1)
        stateManager.isLandiInitSuccess shouldBe false
        
        // Cycle 2
        stateManager.onConnected()
        stateManager.isLandiInitSuccess shouldBe true
        stateManager.onDisconnected(errorCode = 2)
        stateManager.isLandiInitSuccess shouldBe false
        
        // Cycle 3
        stateManager.onConnected()
        stateManager.isLandiInitSuccess shouldBe true
    }

    "Property 4: onConnected() should reset retry count to zero" {
        val stateManager = LandiConnectionStateManager()
        
        // Simulate some retries
        stateManager.incrementRetryCount()
        stateManager.incrementRetryCount()
        stateManager.retryCount shouldBe 2
        
        // Connect should reset retry count
        stateManager.onConnected()
        
        stateManager.retryCount shouldBe 0
    }

    "Property 4: reset() should set isLandiInitSuccess to false" {
        val stateManager = LandiConnectionStateManager()
        
        // Connect first
        stateManager.onConnected()
        stateManager.isLandiInitSuccess shouldBe true
        
        // Reset
        stateManager.reset()
        
        stateManager.isLandiInitSuccess shouldBe false
    }

    "Property 4: reset() should set retryCount to zero" {
        val stateManager = LandiConnectionStateManager()
        
        // Increment retry count
        stateManager.incrementRetryCount()
        stateManager.incrementRetryCount()
        stateManager.retryCount shouldBe 2
        
        // Reset
        stateManager.reset()
        
        stateManager.retryCount shouldBe 0
    }

    "Property 4: isReady() should return same value as isLandiInitSuccess" {
        val stateManager = LandiConnectionStateManager()
        
        // Initial state
        stateManager.isReady() shouldBe stateManager.isLandiInitSuccess
        stateManager.isReady() shouldBe false
        
        // After connect
        stateManager.onConnected()
        stateManager.isReady() shouldBe stateManager.isLandiInitSuccess
        stateManager.isReady() shouldBe true
        
        // After disconnect
        stateManager.onDisconnected(errorCode = 0)
        stateManager.isReady() shouldBe stateManager.isLandiInitSuccess
        stateManager.isReady() shouldBe false
    }

    // =========================================================================
    // Property 3: Retry Limit Enforcement (Related to State Consistency)
    // Validates: Requirements 1.3
    // 
    // For any sequence of OmniDriver initialization failures, the retry counter 
    // SHALL increment on each failure and stop retrying when it reaches 3.
    // =========================================================================

    "Property 3: shouldRetry() should return true when retryCount < maxRetryCount" {
        val stateManager = LandiConnectionStateManager(maxRetryCount = 3)
        
        stateManager.shouldRetry() shouldBe true
        
        stateManager.incrementRetryCount()
        stateManager.shouldRetry() shouldBe true
        
        stateManager.incrementRetryCount()
        stateManager.shouldRetry() shouldBe true
    }

    "Property 3: shouldRetry() should return false when retryCount >= maxRetryCount" {
        val stateManager = LandiConnectionStateManager(maxRetryCount = 3)
        
        stateManager.incrementRetryCount() // 1
        stateManager.incrementRetryCount() // 2
        stateManager.incrementRetryCount() // 3
        
        stateManager.shouldRetry() shouldBe false
    }

    "Property 3: incrementRetryCount() should increment by 1 each time" {
        val stateManager = LandiConnectionStateManager()
        
        stateManager.retryCount shouldBe 0
        
        stateManager.incrementRetryCount()
        stateManager.retryCount shouldBe 1
        
        stateManager.incrementRetryCount()
        stateManager.retryCount shouldBe 2
        
        stateManager.incrementRetryCount()
        stateManager.retryCount shouldBe 3
    }

    "Property 3: Custom maxRetryCount should be respected" {
        forAll(Arb.int(1, 10)) { maxRetry ->
            val stateManager = LandiConnectionStateManager(maxRetryCount = maxRetry)
            
            // Should allow retries up to maxRetry - 1
            repeat(maxRetry - 1) {
                stateManager.incrementRetryCount()
            }
            val canRetryBefore = stateManager.shouldRetry()
            
            // After reaching maxRetry, should not allow more retries
            stateManager.incrementRetryCount()
            val canRetryAfter = stateManager.shouldRetry()
            
            canRetryBefore && !canRetryAfter
        }
    }

    "Property 3: onDisconnected() should return shouldRetry() result" {
        val stateManager = LandiConnectionStateManager(maxRetryCount = 2)
        
        // First disconnect - should allow retry
        val shouldRetry1 = stateManager.onDisconnected(errorCode = 1)
        shouldRetry1 shouldBe true
        
        // Increment retry count
        stateManager.incrementRetryCount()
        
        // Second disconnect - should still allow retry
        val shouldRetry2 = stateManager.onDisconnected(errorCode = 2)
        shouldRetry2 shouldBe true
        
        // Increment retry count again
        stateManager.incrementRetryCount()
        
        // Third disconnect - should not allow retry (reached max)
        val shouldRetry3 = stateManager.onDisconnected(errorCode = 3)
        shouldRetry3 shouldBe false
    }
})
