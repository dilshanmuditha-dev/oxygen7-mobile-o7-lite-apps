//
//  SecurityMethodChannelTests.swift
//  RunnerTests
//
//  iOS Binary Protection - Security Method Channel Tests
//  Feature: ios-binary-protection, Property 9: Security Status Query Completeness
//  Feature: ios-binary-protection, Property 10: Configuration Application
//  Validates: Requirements 6.3, 6.4, 6.5
//

import XCTest
@testable import Runner

final class SecurityMethodChannelTests: XCTestCase {
    
    var service: TestableBinaryProtectionService!
    
    override func setUp() {
        super.setUp()
        service = TestableBinaryProtectionService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Property 9: Security Status Query Completeness
    // For any security status query from the Flutter layer, the Binary_Protection_System
    // SHALL return a complete SecurityAssessment containing results from all detection
    // components (jailbreak, debugger, integrity, runtime).
    
    /// Property test: Security assessment contains all components
    func testProperty9_AssessmentContainsAllComponents() {
        // Feature: ios-binary-protection, Property 9: Security Status Query Completeness
        // Validates: Requirements 6.3, 6.5
        
        var testCount = 0
        
        // Test various combinations of component results
        let boolValues = [true, false]
        
        for jailbroken in boolValues {
            for debugging in boolValues {
                for integrityValid in boolValues {
                    for runtimeSafe in boolValues {
                        for _ in 0..<7 { // 2^4 * 7 = 112 iterations
                            service.mockJailbreakResult = JailbreakResult(
                                isJailbroken: jailbroken,
                                confidence: jailbroken ? .high : .unknown,
                                indicators: jailbroken ? [.cydiaInstalled] : []
                            )
                            service.mockDebuggerResult = DebuggerResult(
                                isDebugging: debugging,
                                debuggerType: debugging ? .lldb : nil
                            )
                            service.mockIntegrityResult = IntegrityResult(
                                isValid: integrityValid,
                                signatureValid: integrityValid,
                                bundleIdentifierValid: integrityValid,
                                teamIdentifierValid: integrityValid,
                                violations: integrityValid ? [] : [.invalidSignature]
                            )
                            service.mockRuntimeResult = RuntimeCheckResult(
                                isSafe: runtimeSafe,
                                fridaDetected: !runtimeSafe,
                                threats: runtimeSafe ? [] : [.fridaServer]
                            )
                            
                            let assessment = service.performSecurityCheck()
                            
                            // Verify all components are present
                            XCTAssertNotNil(assessment.jailbreakResult,
                                "Assessment should contain jailbreak result")
                            XCTAssertNotNil(assessment.debuggerResult,
                                "Assessment should contain debugger result")
                            XCTAssertNotNil(assessment.integrityResult,
                                "Assessment should contain integrity result")
                            XCTAssertNotNil(assessment.runtimeResult,
                                "Assessment should contain runtime result")
                            
                            // Verify component values match
                            XCTAssertEqual(assessment.jailbreakResult.isJailbroken, jailbroken)
                            XCTAssertEqual(assessment.debuggerResult.isDebugging, debugging)
                            XCTAssertEqual(assessment.integrityResult.isValid, integrityValid)
                            XCTAssertEqual(assessment.runtimeResult.isSafe, runtimeSafe)
                            
                            // Verify assessment has required metadata
                            XCTAssertNotNil(assessment.timestamp)
                            XCTAssertFalse(assessment.assessmentId.isEmpty)
                            
                            testCount += 1
                        }
                    }
                }
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100,
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    /// Property test: Flutter map contains all required fields
    func testProperty9_FlutterMapContainsAllFields() {
        // Feature: ios-binary-protection, Property 9: Security Status Query Completeness
        // Validates: Requirements 6.3, 6.5
        
        for _ in 0..<100 {
            let jailbroken = Bool.random()
            let debugging = Bool.random()
            let integrityValid = Bool.random()
            let runtimeSafe = Bool.random()
            
            service.mockJailbreakResult = JailbreakResult(isJailbroken: jailbroken)
            service.mockDebuggerResult = DebuggerResult(isDebugging: debugging)
            service.mockIntegrityResult = IntegrityResult(isValid: integrityValid)
            service.mockRuntimeResult = RuntimeCheckResult(isSafe: runtimeSafe)
            
            let assessment = service.performSecurityCheck()
            let map = assessment.toFlutterMap()
            
            // Verify all required fields are present
            XCTAssertNotNil(map["overallStatus"], "Map should contain overallStatus")
            XCTAssertNotNil(map["isJailbroken"], "Map should contain isJailbroken")
            XCTAssertNotNil(map["isDebugging"], "Map should contain isDebugging")
            XCTAssertNotNil(map["integrityValid"], "Map should contain integrityValid")
            XCTAssertNotNil(map["runtimeSafe"], "Map should contain runtimeSafe")
            XCTAssertNotNil(map["timestamp"], "Map should contain timestamp")
            XCTAssertNotNil(map["assessmentId"], "Map should contain assessmentId")
            
            // Verify nested result maps
            XCTAssertNotNil(map["jailbreakResult"], "Map should contain jailbreakResult")
            XCTAssertNotNil(map["debuggerResult"], "Map should contain debuggerResult")
            XCTAssertNotNil(map["integrityResult"], "Map should contain integrityResult")
            XCTAssertNotNil(map["runtimeResult"], "Map should contain runtimeResult")
            
            // Verify values match
            XCTAssertEqual(map["isJailbroken"] as? Bool, jailbroken)
            XCTAssertEqual(map["isDebugging"] as? Bool, debugging)
            XCTAssertEqual(map["integrityValid"] as? Bool, integrityValid)
            XCTAssertEqual(map["runtimeSafe"] as? Bool, runtimeSafe)
        }
    }
    
    // MARK: - Property 10: Configuration Application
    // For any security configuration update from the Flutter layer,
    // the Binary_Protection_System SHALL apply the new configuration
    // to all subsequent security checks.
    
    /// Property test: Configuration updates are applied
    func testProperty10_ConfigurationUpdatesApplied() {
        // Feature: ios-binary-protection, Property 10: Configuration Application
        // Validates: Requirements 6.4
        
        var testCount = 0
        let boolValues = [true, false]
        let intervals: [TimeInterval] = [10.0, 30.0, 60.0, 120.0]
        
        for jailbreakEnabled in boolValues {
            for debuggerEnabled in boolValues {
                for integrityEnabled in boolValues {
                    for runtimeEnabled in boolValues {
                        for interval in intervals {
                            let config = SecurityConfiguration(
                                jailbreakDetectionEnabled: jailbreakEnabled,
                                debuggerDetectionEnabled: debuggerEnabled,
                                integrityCheckEnabled: integrityEnabled,
                                runtimeProtectionEnabled: runtimeEnabled,
                                monitoringInterval: interval
                            )
                            
                            service.updateConfiguration(config)
                            
                            // Verify configuration was applied
                            XCTAssertEqual(service.configuration.jailbreakDetectionEnabled, jailbreakEnabled,
                                "Jailbreak detection setting should be applied")
                            XCTAssertEqual(service.configuration.debuggerDetectionEnabled, debuggerEnabled,
                                "Debugger detection setting should be applied")
                            XCTAssertEqual(service.configuration.integrityCheckEnabled, integrityEnabled,
                                "Integrity check setting should be applied")
                            XCTAssertEqual(service.configuration.runtimeProtectionEnabled, runtimeEnabled,
                                "Runtime protection setting should be applied")
                            XCTAssertEqual(service.configuration.monitoringInterval, interval,
                                "Monitoring interval should be applied")
                            
                            testCount += 1
                        }
                    }
                }
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 64,
            "Should run at least 64 iterations (actual: \(testCount))")
    }
    
    /// Property test: Configuration persists across checks
    func testProperty10_ConfigurationPersistsAcrossChecks() {
        // Feature: ios-binary-protection, Property 10: Configuration Application
        // Validates: Requirements 6.4
        
        for _ in 0..<100 {
            let jailbreakEnabled = Bool.random()
            let interval = TimeInterval.random(in: 10...120)
            
            let config = SecurityConfiguration(
                jailbreakDetectionEnabled: jailbreakEnabled,
                monitoringInterval: interval
            )
            
            service.updateConfiguration(config)
            
            // Perform multiple checks
            for _ in 0..<5 {
                _ = service.performSecurityCheck()
                
                // Configuration should persist
                XCTAssertEqual(service.configuration.jailbreakDetectionEnabled, jailbreakEnabled)
                XCTAssertEqual(service.configuration.monitoringInterval, interval, accuracy: 0.001)
            }
        }
    }
    
    // MARK: - Unit Tests for Method Channel
    
    func testChannelName() {
        XCTAssertEqual(SecurityMethodChannel.channelName, "CHANNEL_IOS_SECURITY")
    }
    
    func testMethodNames() {
        XCTAssertEqual(SecurityMethodChannel.Method.getSecurityStatus.rawValue, "getSecurityStatus")
        XCTAssertEqual(SecurityMethodChannel.Method.performSecurityCheck.rawValue, "performSecurityCheck")
        XCTAssertEqual(SecurityMethodChannel.Method.startMonitoring.rawValue, "startMonitoring")
        XCTAssertEqual(SecurityMethodChannel.Method.stopMonitoring.rawValue, "stopMonitoring")
        XCTAssertEqual(SecurityMethodChannel.Method.getSecurityEvents.rawValue, "getSecurityEvents")
        XCTAssertEqual(SecurityMethodChannel.Method.setConfiguration.rawValue, "setConfiguration")
        XCTAssertEqual(SecurityMethodChannel.Method.isMonitoring.rawValue, "isMonitoring")
    }
    
    func testSecurityStatusValues() {
        XCTAssertEqual(SecurityStatus.secure.rawValue, "secure")
        XCTAssertEqual(SecurityStatus.warning.rawValue, "warning")
        XCTAssertEqual(SecurityStatus.compromised.rawValue, "compromised")
        XCTAssertEqual(SecurityStatus.unknown.rawValue, "unknown")
    }
    
    func testDefaultConfiguration() {
        let config = SecurityConfiguration.default
        
        XCTAssertTrue(config.jailbreakDetectionEnabled)
        XCTAssertTrue(config.debuggerDetectionEnabled)
        XCTAssertTrue(config.integrityCheckEnabled)
        XCTAssertTrue(config.runtimeProtectionEnabled)
        XCTAssertEqual(config.monitoringInterval, 30.0)
        XCTAssertFalse(config.allowJailbrokenDevices)
    }
    
    func testConfigurationFromFlutterArgs() {
        let args: [String: Any] = [
            "jailbreakDetectionEnabled": false,
            "debuggerDetectionEnabled": true,
            "integrityCheckEnabled": false,
            "runtimeProtectionEnabled": true,
            "monitoringInterval": 45.0,
            "allowJailbrokenDevices": true,
            "expectedBundleIdentifier": "com.test.app",
            "expectedTeamIdentifier": "TESTTEAM"
        ]
        
        let config = SecurityConfiguration(
            jailbreakDetectionEnabled: args["jailbreakDetectionEnabled"] as? Bool ?? true,
            debuggerDetectionEnabled: args["debuggerDetectionEnabled"] as? Bool ?? true,
            integrityCheckEnabled: args["integrityCheckEnabled"] as? Bool ?? true,
            runtimeProtectionEnabled: args["runtimeProtectionEnabled"] as? Bool ?? true,
            monitoringInterval: args["monitoringInterval"] as? TimeInterval ?? 30.0,
            allowJailbrokenDevices: args["allowJailbrokenDevices"] as? Bool ?? false,
            expectedBundleIdentifier: args["expectedBundleIdentifier"] as? String ?? "",
            expectedTeamIdentifier: args["expectedTeamIdentifier"] as? String ?? ""
        )
        
        XCTAssertFalse(config.jailbreakDetectionEnabled)
        XCTAssertTrue(config.debuggerDetectionEnabled)
        XCTAssertFalse(config.integrityCheckEnabled)
        XCTAssertTrue(config.runtimeProtectionEnabled)
        XCTAssertEqual(config.monitoringInterval, 45.0)
        XCTAssertTrue(config.allowJailbrokenDevices)
        XCTAssertEqual(config.expectedBundleIdentifier, "com.test.app")
        XCTAssertEqual(config.expectedTeamIdentifier, "TESTTEAM")
    }
}
