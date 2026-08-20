package com.oxpay.o7lite.security

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.SigningInfo
import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk

/**
 * Unit tests for TrustedPackageRegistry.
 * 
 * Feature: exposed-activity-remediation
 * Validates: Requirements 4.1
 */
class TrustedPackageRegistryTest : StringSpec({
    
    // Mock context and package manager
    val mockContext = mockk<Context>(relaxed = true)
    val mockPackageManager = mockk<PackageManager>(relaxed = true)
    
    beforeTest {
        every { mockContext.packageName } returns "com.oxpay.o7lite"
        every { mockContext.packageManager } returns mockPackageManager
    }
    
    "should recognize Razer Credits as trusted" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("com.cardbiz.razercredits1") shouldBe true
    }
    
    "should recognize SUNMI printer service as trusted" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("woyou.aidlservice.jiuiv5") shouldBe true
    }
    
    "should recognize SUNMI New replacment for Gobiz as trusted" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("com.pos.router.pay_dee") shouldBe true
    }
    
    "should recognize Share Commerce as trusted" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("com.sc.mf919") shouldBe true
    }
    
    "should recognize Minesec as trusted" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("com.mscardpayments.app") shouldBe true
    }
    
    "should recognize Landi app store as trusted" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("com.landiconnect.appstore") shouldBe true
    }
    
    "should recognize self package as trusted" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("com.oxpay.o7lite") shouldBe true
    }
    
    "should recognize dev package as trusted" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("com.oxpay.o7lite") shouldBe true
    }
    
    "should reject unknown packages" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("com.malicious.app") shouldBe false
    }
    
    "should reject null package name" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted(null) shouldBe false
    }
    
    "should reject empty package name" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isPackageTrusted("") shouldBe false
    }
    
    "should correctly identify self package" {
        val registry = TrustedPackageRegistry(mockContext)
        registry.isSelfPackage("com.oxpay.o7lite") shouldBe true
        registry.isSelfPackage("com.oxpay.o7lite") shouldBe true
        registry.isSelfPackage("com.other.app") shouldBe false
        registry.isSelfPackage(null) shouldBe false
    }
    
    "should return all trusted packages" {
        val registry = TrustedPackageRegistry(mockContext)
        val packages = registry.getTrustedPackages()
        
        packages.contains("com.cardbiz.razercredits1") shouldBe true
        packages.contains("woyou.aidlservice.jiuiv5") shouldBe true
//        packages.contains("sunmi.pay.u_mobile") shouldBe true
        packages.contains("com.pos.router.pay_dee") shouldBe true
        packages.contains("com.sc.mf919") shouldBe true
        packages.contains("com.mscardpayments.app") shouldBe true
        packages.contains("com.landiconnect.appstore") shouldBe true
    }
    
    "should handle package signature verification for non-existent package" {
        val registry = TrustedPackageRegistry(mockContext)
        
        every { 
            mockPackageManager.getPackageInfo(any<String>(), any<Int>()) 
        } throws PackageManager.NameNotFoundException()
        
        registry.verifyPackageSignature("com.nonexistent.app") shouldBe false
    }
})
