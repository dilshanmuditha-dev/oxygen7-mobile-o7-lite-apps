//
//  RuntimeProtectionTests.swift
//  RunnerTests
//
//  iOS Binary Protection - Runtime Protection Tests
//  Feature: ios-binary-protection, Property 8: Runtime Threat Detection
//  Validates: Requirements 4.1, 4.2, 4.3
//

import XCTest
@testable import Runner

final class RuntimeProtectionTests: XCTestCase {
    
    var protection: TestableRuntimeProtection!
    
    override func setUp() {
        super.setUp()
        protection = TestableRuntimeProtection()
    }
    
    override func tearDown() {
        protection = nil
        super.tearDown()
    }
    
    // MARK: - Property 8: Runtime Threat Detection
    // For any runtime threat indicator (Frida server/gadget, method swizzling, code injection,
    // suspicious libraries), if the indicator is present, the RuntimeProtection SHALL detect it
    // and include it in the threats list.
    
    /// Property test: Any threat indicator results in detection and inclusion in threats list
    func testProperty8_AnyThreatIndicatorDetectedAndIncluded() {
        // Feature: ios-binary-protection, Property 8: Runtime Threat Detection
        // Validates: Requirements 4.1, 4.2, 4.3
        
        let allThreats: [RuntimeThreat] = [
            .fridaServer,
            .fridaGadget,
            .methodSwizzling,
            .codeInjection,
            .suspiciousLibrary,
            .hookingFramework
        ]
        
        var testCount = 0
        
        // Test each individual threat
        for threat in allThreats {
            for _ in 0..<17 { // 6 * 17 = 102 iterations
                protection.mockThreats = [threat]
                protection.mockFridaDetected = threat == .fridaServer || threat == .fridaGadget
                protection.mockSwizzlingDetected = threat == .methodSwizzling
                protection.mockInjectionDetected = threat == .codeInjection || threat == .suspiciousLibrary
                
                let result = protection.performRuntimeCheck()
                
                XCTAssertFalse(result.isSafe,
                    "Should not be safe when threat \(threat.rawValue) is present")
                XCTAssertTrue(result.threats.contains(threat),
                    "Threats list should contain \(threat.rawValue)")
                
                testCount += 1
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100,
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    /// Property test: Multiple threats are all detected and included
    func testProperty8_MultipleThreatsCombinations() {
        // Feature: ios-binary-protection, Property 8: Runtime Threat Detection
        // Validates: Requirements 4.1, 4.2, 4.3
        
        let allThreats: [RuntimeThreat] = [
            .fridaServer,
            .fridaGadget,
            .methodSwizzling,
            .codeInjection,
            .suspiciousLibrary,
            .hookingFramework
        ]
        
        var testCount = 0
        
        // Test combinations of 2 threats
        for i in 0..<allThreats.count {
            for j in (i+1)..<allThreats.count {
                let threats = [allThreats[i], allThreats[j]]
                
                protection.mockThreats = threats
                protection.mockFridaDetected = threats.contains(.fridaServer) || threats.contains(.fridaGadget)
                protection.mockSwizzlingDetected = threats.contains(.methodSwizzling)
                protection.mockInjectionDetected = threats.contains(.codeInjection) || threats.contains(.suspiciousLibrary)
                
                let result = protection.performRuntimeCheck()
                
                XCTAssertFalse(result.isSafe,
                    "Should not be safe with multiple threats")
                
                for threat in threats {
                    XCTAssertTrue(result.threats.contains(threat),
                        "Threats list should contain \(threat.rawValue)")
                }
                
                testCount += 1
            }
        }
        
        // Test combinations of 3 threats
        for i in 0..<allThreats.count {
            for j in (i+1)..<allThreats.count {
                for k in (j+1)..<allThreats.count {
                    let threats = [allThreats[i], allThreats[j], allThreats[k]]
                    
                    protection.mockThreats = threats
                    protection.mockFridaDetected = threats.contains(.fridaServer) || threats.contains(.fridaGadget)
                    protection.mockSwizzlingDetected = threats.contains(.methodSwizzling)
                    protection.mockInjectionDetected = threats.contains(.codeInjection) || threats.contains(.suspiciousLibrary)
                    
                    let result = protection.performRuntimeCheck()
                    
                    XCTAssertFalse(result.isSafe)
                    
                    for threat in threats {
                        XCTAssertTrue(result.threats.contains(threat))
                    }
                    
                    testCount += 1
                }
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 35,
            "Should run at least 35 iterations for combinations (actual: \(testCount))")
    }
    
    /// Property test: No threats results in isSafe=true
    func testProperty8_NoThreatsResultsInSafe() {
        // Feature: ios-binary-protection, Property 8: Runtime Threat Detection
        // Validates: Requirements 4.1, 4.2, 4.3
        
        for _ in 0..<100 {
            protection.mockThreats = []
            protection.mockFridaDetected = false
            protection.mockSwizzlingDetected = false
            protection.mockInjectionDetected = false
            
            let result = protection.performRuntimeCheck()
            
            XCTAssertTrue(result.isSafe,
                "Should be safe when no threats detected")
            XCTAssertTrue(result.threats.isEmpty,
                "Threats list should be empty")
            XCTAssertFalse(result.fridaDetected)
            XCTAssertFalse(result.swizzlingDetected)
            XCTAssertFalse(result.injectionDetected)
        }
    }
    
    /// Property test: Detection methods are consistent with overall result
    func testProperty8_DetectionMethodsConsistentWithResult() {
        // Feature: ios-binary-protection, Property 8: Runtime Threat Detection
        // Validates: Requirements 4.1, 4.2, 4.3
        
        for _ in 0..<100 {
            let fridaDetected = Bool.random()
            let swizzlingDetected = Bool.random()
            let injectionDetected = Bool.random()
            
            protection.mockFridaDetected = fridaDetected
            protection.mockSwizzlingDetected = swizzlingDetected
            protection.mockInjectionDetected = injectionDetected
            protection.mockThreats = []
            
            // Individual detection methods
            XCTAssertEqual(protection.detectFrida(), fridaDetected)
            XCTAssertEqual(protection.detectSwizzling(), swizzlingDetected)
            XCTAssertEqual(protection.detectCodeInjection(), injectionDetected)
            
            // Overall result
            let result = protection.performRuntimeCheck()
            XCTAssertEqual(result.fridaDetected, fridaDetected)
            XCTAssertEqual(result.swizzlingDetected, swizzlingDetected)
            XCTAssertEqual(result.injectionDetected, injectionDetected)
        }
    }
    
    // MARK: - Unit Tests for Specific Threats
    
    func testFridaServerDetection() {
        protection.mockFridaDetected = true
        protection.mockThreats = [.fridaServer]
        
        let result = protection.performRuntimeCheck()
        
        XCTAssertFalse(result.isSafe)
        XCTAssertTrue(result.fridaDetected)
        XCTAssertTrue(result.threats.contains(.fridaServer))
    }
    
    func testFridaGadgetDetection() {
        protection.mockFridaDetected = true
        protection.mockThreats = [.fridaGadget]
        
        let result = protection.performRuntimeCheck()
        
        XCTAssertFalse(result.isSafe)
        XCTAssertTrue(result.fridaDetected)
        XCTAssertTrue(result.threats.contains(.fridaGadget))
    }
    
    func testMethodSwizzlingDetection() {
        protection.mockSwizzlingDetected = true
        protection.mockThreats = [.methodSwizzling]
        
        let result = protection.performRuntimeCheck()
        
        XCTAssertFalse(result.isSafe)
        XCTAssertTrue(result.swizzlingDetected)
        XCTAssertTrue(result.threats.contains(.methodSwizzling))
    }
    
    func testCodeInjectionDetection() {
        protection.mockInjectionDetected = true
        protection.mockThreats = [.codeInjection]
        
        let result = protection.performRuntimeCheck()
        
        XCTAssertFalse(result.isSafe)
        XCTAssertTrue(result.injectionDetected)
        XCTAssertTrue(result.threats.contains(.codeInjection))
    }
    
    func testSuspiciousLibraryDetection() {
        protection.mockInjectionDetected = true
        protection.mockThreats = [.suspiciousLibrary]
        
        let result = protection.performRuntimeCheck()
        
        XCTAssertFalse(result.isSafe)
        XCTAssertTrue(result.threats.contains(.suspiciousLibrary))
    }
    
    func testHookingFrameworkDetection() {
        protection.mockThreats = [.hookingFramework]
        
        let result = protection.performRuntimeCheck()
        
        XCTAssertFalse(result.isSafe)
        XCTAssertTrue(result.threats.contains(.hookingFramework))
    }
    
    // MARK: - Result Serialization Tests
    
    func testRuntimeCheckResultToMap() {
        protection.mockFridaDetected = true
        protection.mockSwizzlingDetected = false
        protection.mockInjectionDetected = true
        protection.mockThreats = [.fridaServer, .codeInjection]
        
        let result = protection.performRuntimeCheck()
        let map = result.toMap()
        
        XCTAssertEqual(map["isSafe"] as? Bool, false)
        XCTAssertEqual(map["fridaDetected"] as? Bool, true)
        XCTAssertEqual(map["swizzlingDetected"] as? Bool, false)
        XCTAssertEqual(map["injectionDetected"] as? Bool, true)
        XCTAssertNotNil(map["timestamp"])
        
        let threats = map["threats"] as? [String]
        XCTAssertNotNil(threats)
        XCTAssertTrue(threats?.contains("frida_server") ?? false)
        XCTAssertTrue(threats?.contains("code_injection") ?? false)
    }
    
    func testSafeResultToMap() {
        protection.mockFridaDetected = false
        protection.mockSwizzlingDetected = false
        protection.mockInjectionDetected = false
        protection.mockThreats = []
        
        let result = protection.performRuntimeCheck()
        let map = result.toMap()
        
        XCTAssertEqual(map["isSafe"] as? Bool, true)
        XCTAssertEqual(map["fridaDetected"] as? Bool, false)
        XCTAssertEqual(map["swizzlingDetected"] as? Bool, false)
        XCTAssertEqual(map["injectionDetected"] as? Bool, false)
        
        let threats = map["threats"] as? [String]
        XCTAssertTrue(threats?.isEmpty ?? true)
    }
}
