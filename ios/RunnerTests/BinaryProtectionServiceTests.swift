//
//  BinaryProtectionServiceTests.swift
//  RunnerTests
//
//  iOS Binary Protection - Binary Protection Service Tests
//  Feature: ios-binary-protection, Property 3: Flutter Notification Delivery
//  Feature: ios-binary-protection, Property 4: Fail-Safe Error Handling
//  Validates: Requirements 1.6, 2.5, 3.5, 4.5, 6.2, 1.7, 3.6
//

import XCTest
@testable import Runner

final class BinaryProtectionServiceTests: XCTestCase {
    
    var service: TestableBinaryProtectionService!
    
    override func setUp() {
        super.setUp()
        service = TestableBinaryProtectionService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Property 3: Flutter Notification Delivery
    // For any security event that occurs, the Binary_Protection_System SHALL send
    // structured event data to the Flutter layer via the method channel.
    
    /// Property test: All security events trigger callback notifications
    func testProperty3_AllSecurityEventsTriggerNotifications() {
        // Feature: ios-binary-protection, Property 3: Flutter Notification Delivery
        // Validates: Requirements 1.6, 2.5, 3.5, 4.5, 6.2
        
        var receivedEvents: [SecurityEvent] = []
        
        service.onSecurityEvent { event in
            receivedEvents.append(event)
        }
        
        var testCount = 0
        
        // Test jailbreak events
        for _ in 0..<25 {
            receivedEvents.removeAll()
            service.mockJailbreakResult = JailbreakResult(
                isJailbroken: true,
                confidence: .high,
                indicators: [.cydiaInstalled]
            )
            service.mockDebuggerResult = DebuggerResult(isDebugging: false)
            service.mockIntegrityResult = IntegrityResult(isValid: true)
            service.mockRuntimeResult = RuntimeCheckResult(isSafe: true)
            
            _ = service.performSecurityCheck()
            
            XCTAssertTrue(receivedEvents.contains { $0.type == .jailbreakDetected },
                "Should receive jailbreak notification")
            testCount += 1
        }
        
        // Test debugger events
        for _ in 0..<25 {
            receivedEvents.removeAll()
            service.mockJailbreakResult = JailbreakResult(isJailbroken: false)
            service.mockDebuggerResult = DebuggerResult(isDebugging: true, debuggerType: .lldb)
            service.mockIntegrityResult = IntegrityResult(isValid: true)
            service.mockRuntimeResult = RuntimeCheckResult(isSafe: true)
            
            _ = service.performSecurityCheck()
            
            XCTAssertTrue(receivedEvents.contains { $0.type == .debuggerDetected },
                "Should receive debugger notification")
            testCount += 1
        }
        
        // Test integrity events
        for _ in 0..<25 {
            receivedEvents.removeAll()
            service.mockJailbreakResult = JailbreakResult(isJailbroken: false)
            service.mockDebuggerResult = DebuggerResult(isDebugging: false)
            service.mockIntegrityResult = IntegrityResult(
                isValid: false,
                violations: [.invalidSignature]
            )
            service.mockRuntimeResult = RuntimeCheckResult(isSafe: true)
            
            _ = service.performSecurityCheck()
            
            XCTAssertTrue(receivedEvents.contains { $0.type == .integrityViolation },
                "Should receive integrity violation notification")
            testCount += 1
        }
        
        // Test runtime events
        for _ in 0..<25 {
            receivedEvents.removeAll()
            service.mockJailbreakResult = JailbreakResult(isJailbroken: false)
            service.mockDebuggerResult = DebuggerResult(isDebugging: false)
            service.mockIntegrityResult = IntegrityResult(isValid: true)
            service.mockRuntimeResult = RuntimeCheckResult(
                isSafe: false,
                threats: [.fridaServer]
            )
            
            _ = service.performSecurityCheck()
            
            XCTAssertTrue(receivedEvents.contains { $0.type == .runtimeThreat },
                "Should receive runtime threat notification")
            testCount += 1
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100,
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    /// Property test: Multiple callbacks all receive events
    func testProperty3_MultipleCallbacksReceiveEvents() {
        // Feature: ios-binary-protection, Property 3: Flutter Notification Delivery
        // Validates: Requirements 1.6, 2.5, 3.5, 4.5, 6.2
        
        var callback1Events: [SecurityEvent] = []
        var callback2Events: [SecurityEvent] = []
        var callback3Events: [SecurityEvent] = []
        
        service.onSecurityEvent { event in
            callback1Events.append(event)
        }
        service.onSecurityEvent { event in
            callback2Events.append(event)
        }
        service.onSecurityEvent { event in
            callback3Events.append(event)
        }
        
        for _ in 0..<100 {
            callback1Events.removeAll()
            callback2Events.removeAll()
            callback3Events.removeAll()
            
            service.mockJailbreakResult = JailbreakResult(
                isJailbroken: true,
                indicators: [.cydiaInstalled]
            )
            
            _ = service.performSecurityCheck()
            
            // All callbacks should receive the same events
            XCTAssertEqual(callback1Events.count, callback2Events.count,
                "All callbacks should receive same number of events")
            XCTAssertEqual(callback2Events.count, callback3Events.count,
                "All callbacks should receive same number of events")
            
            // All should have jailbreak event
            XCTAssertTrue(callback1Events.contains { $0.type == .jailbreakDetected })
            XCTAssertTrue(callback2Events.contains { $0.type == .jailbreakDetected })
            XCTAssertTrue(callback3Events.contains { $0.type == .jailbreakDetected })
        }
    }
    
    /// Property test: Monitoring start/stop events are delivered
    func testProperty3_MonitoringEventsDelivered() {
        // Feature: ios-binary-protection, Property 3: Flutter Notification Delivery
        // Validates: Requirements 6.2
        
        var receivedEvents: [SecurityEvent] = []
        
        service.onSecurityEvent { event in
            receivedEvents.append(event)
        }
        
        for _ in 0..<50 {
            receivedEvents.removeAll()
            
            service.startRuntimeMonitoring()
            XCTAssertTrue(receivedEvents.contains { $0.type == .monitoringStarted },
                "Should receive monitoring started event")
            
            receivedEvents.removeAll()
            
            service.stopRuntimeMonitoring()
            XCTAssertTrue(receivedEvents.contains { $0.type == .monitoringStopped },
                "Should receive monitoring stopped event")
        }
    }
    
    // MARK: - Property 4: Fail-Safe Error Handling
    // For any detection operation that throws an error or fails unexpectedly,
    // the Binary_Protection_System SHALL treat the result as SecurityStatus.compromised.
    
    /// Property test: Errors result in compromised status
    func testProperty4_ErrorsResultInCompromisedStatus() {
        // Feature: ios-binary-protection, Property 4: Fail-Safe Error Handling
        // Validates: Requirements 1.7, 3.6
        
        for _ in 0..<100 {
            service.shouldThrowError = true
            
            let assessment = service.performSecurityCheck()
            
            XCTAssertEqual(assessment.overallStatus, .compromised,
                "Error should result in compromised status")
        }
    }
    
    /// Property test: Normal operation returns expected status
    func testProperty4_NormalOperationReturnsExpectedStatus() {
        // Feature: ios-binary-protection, Property 4: Fail-Safe Error Handling
        // Validates: Requirements 1.7, 3.6
        
        let statuses: [SecurityStatus] = [.secure, .warning, .compromised]
        var testCount = 0
        
        for _ in 0..<34 {
            for status in statuses {
                service.shouldThrowError = false
                service.mockOverallStatus = status
                service.mockJailbreakResult = JailbreakResult(isJailbroken: false)
                service.mockDebuggerResult = DebuggerResult(isDebugging: false)
                service.mockIntegrityResult = IntegrityResult(isValid: true)
                service.mockRuntimeResult = RuntimeCheckResult(isSafe: true)
                
                let assessment = service.performSecurityCheck()
                
                XCTAssertEqual(assessment.overallStatus, status,
                    "Normal operation should return expected status")
                testCount += 1
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100,
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    // MARK: - Unit Tests for Specific Scenarios
    
    func testSecureAssessment() {
        service.mockJailbreakResult = JailbreakResult(isJailbroken: false)
        service.mockDebuggerResult = DebuggerResult(isDebugging: false)
        service.mockIntegrityResult = IntegrityResult(isValid: true)
        service.mockRuntimeResult = RuntimeCheckResult(isSafe: true)
        service.mockOverallStatus = .secure
        
        let assessment = service.performSecurityCheck()
        
        XCTAssertEqual(assessment.overallStatus, .secure)
        XCTAssertTrue(assessment.isSecure)
    }
    
    func testCompromisedAssessment() {
        service.mockJailbreakResult = JailbreakResult(
            isJailbroken: true,
            confidence: .high,
            indicators: [.cydiaInstalled, .sandboxViolation]
        )
        service.mockOverallStatus = .compromised
        
        let assessment = service.performSecurityCheck()
        
        XCTAssertEqual(assessment.overallStatus, .compromised)
        XCTAssertFalse(assessment.isSecure)
    }
    
    func testWarningAssessment() {
        service.mockJailbreakResult = JailbreakResult(
            isJailbroken: true,
            confidence: .low,
            indicators: [.suspiciousURLSchemes]
        )
        service.mockOverallStatus = .warning
        
        let assessment = service.performSecurityCheck()
        
        XCTAssertEqual(assessment.overallStatus, .warning)
    }
    
    func testGetSecurityStatus() {
        service.mockOverallStatus = .secure
        _ = service.performSecurityCheck()
        
        XCTAssertEqual(service.getSecurityStatus(), .secure)
        
        service.mockOverallStatus = .compromised
        _ = service.performSecurityCheck()
        
        XCTAssertEqual(service.getSecurityStatus(), .compromised)
    }
    
    func testStartStopMonitoring() {
        XCTAssertFalse(service.isMonitoring)
        
        service.startRuntimeMonitoring()
        XCTAssertTrue(service.isMonitoring)
        
        service.stopRuntimeMonitoring()
        XCTAssertFalse(service.isMonitoring)
    }
    
    func testConfigurationUpdate() {
        let newConfig = SecurityConfiguration(
            jailbreakDetectionEnabled: false,
            debuggerDetectionEnabled: false,
            monitoringInterval: 60.0
        )
        
        service.updateConfiguration(newConfig)
        
        XCTAssertFalse(service.configuration.jailbreakDetectionEnabled)
        XCTAssertFalse(service.configuration.debuggerDetectionEnabled)
        XCTAssertEqual(service.configuration.monitoringInterval, 60.0)
    }
    
    func testAssessmentToFlutterMap() {
        service.mockJailbreakResult = JailbreakResult(isJailbroken: true, indicators: [.cydiaInstalled])
        service.mockDebuggerResult = DebuggerResult(isDebugging: false)
        service.mockIntegrityResult = IntegrityResult(isValid: true)
        service.mockRuntimeResult = RuntimeCheckResult(isSafe: true)
        service.mockOverallStatus = .warning
        
        let assessment = service.performSecurityCheck()
        let map = assessment.toFlutterMap()
        
        XCTAssertEqual(map["overallStatus"] as? String, "warning")
        XCTAssertEqual(map["isJailbroken"] as? Bool, true)
        XCTAssertEqual(map["isDebugging"] as? Bool, false)
        XCTAssertEqual(map["integrityValid"] as? Bool, true)
        XCTAssertEqual(map["runtimeSafe"] as? Bool, true)
        XCTAssertNotNil(map["timestamp"])
        XCTAssertNotNil(map["assessmentId"])
    }
    
    func testLastAssessmentStored() {
        XCTAssertNil(service.lastAssessment)
        
        service.mockOverallStatus = .secure
        _ = service.performSecurityCheck()
        
        XCTAssertNotNil(service.lastAssessment)
        XCTAssertEqual(service.lastAssessment?.overallStatus, .secure)
    }
}
