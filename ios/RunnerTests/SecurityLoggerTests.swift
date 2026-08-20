//
//  SecurityLoggerTests.swift
//  RunnerTests
//
//  iOS Binary Protection - Security Logger Tests
//  Feature: ios-binary-protection, Property 2: Security Event Logging Consistency
//  Validates: Requirements 1.5, 2.4, 3.4, 4.4, 7.1, 7.2, 7.3
//

import XCTest
@testable import Runner

final class SecurityLoggerTests: XCTestCase {
    
    var logger: SecurityLogger!
    
    override func setUp() {
        super.setUp()
        logger = SecurityLogger(verboseLoggingEnabled: true)
        logger.clearLogs()
    }
    
    override func tearDown() {
        logger.clearLogs()
        logger = nil
        super.tearDown()
    }
    
    // MARK: - Property 2: Security Event Logging Consistency
    // For any security event, the Binary_Protection_System SHALL create a structured log entry
    // containing timestamp, event type, severity, and relevant details, while excluding sensitive data patterns.
    
    /// Property test: All security events create valid log entries with required fields
    func testProperty2_AllSecurityEventsCreateValidLogEntries() {
        // Feature: ios-binary-protection, Property 2: Security Event Logging Consistency
        // Validates: Requirements 1.5, 2.4, 3.4, 4.4, 7.1, 7.2, 7.3
        
        let eventTypes: [SecurityEventType] = [
            .jailbreakDetected,
            .debuggerDetected,
            .integrityViolation,
            .runtimeThreat,
            .securityCheckPassed,
            .securityCheckFailed
        ]
        
        let severities: [SecuritySeverity] = [
            .critical,
            .high,
            .medium,
            .low,
            .info
        ]
        
        // Test 100+ combinations (property-based testing with exhaustive combinations)
        var testCount = 0
        
        for eventType in eventTypes {
            for severity in severities {
                for iteration in 0..<4 { // 6 * 5 * 4 = 120 iterations
                    let event = SecurityEvent(
                        type: eventType,
                        severity: severity,
                        message: "Test message \(iteration)",
                        details: ["key\(iteration)": "value\(iteration)"]
                    )
                    
                    logger.log(event)
                    testCount += 1
                }
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100, "Should run at least 100 iterations")
        
        // Verify all logged events have required fields
        let loggedEvents = logger.getRecentEvents(limit: 100)
        
        for event in loggedEvents {
            // Verify timestamp is present and valid
            XCTAssertNotNil(event.timestamp)
            XCTAssertLessThanOrEqual(event.timestamp, Date())
            
            // Verify event type is present
            XCTAssertNotNil(event.type)
            
            // Verify severity is present
            XCTAssertNotNil(event.severity)
            
            // Verify ID is present and non-empty
            XCTAssertFalse(event.id.isEmpty)
            
            // Verify message is present
            XCTAssertNotNil(event.message)
        }
    }
    
    /// Property test: Sensitive data is excluded from log entries
    func testProperty2_SensitiveDataExcludedFromLogs() {
        // Feature: ios-binary-protection, Property 2: Security Event Logging Consistency
        // Validates: Requirements 7.3
        
        let sensitivePatterns = [
            "password=secret123",
            "token=abc123xyz",
            "api_key=mykey",
            "credential=mycred",
            "bearer=authtoken"
        ]
        
        // Test with 100+ iterations
        for i in 0..<100 {
            let sensitiveData = sensitivePatterns[i % sensitivePatterns.count]
            
            let event = SecurityEvent(
                type: .securityCheckFailed,
                severity: .high,
                message: "Error with \(sensitiveData)",
                details: ["data": sensitiveData, "index": "\(i)"]
            )
            
            logger.log(event)
        }
        
        let loggedEvents = logger.getRecentEvents(limit: 100)
        
        for event in loggedEvents {
            // Verify no sensitive data in message
            XCTAssertFalse(event.message.contains("secret123"))
            XCTAssertFalse(event.message.contains("abc123xyz"))
            XCTAssertFalse(event.message.contains("mykey"))
            XCTAssertFalse(event.message.contains("mycred"))
            XCTAssertFalse(event.message.contains("authtoken"))
            
            // Verify no sensitive data in details
            for (_, value) in event.details {
                XCTAssertFalse(value.contains("secret123"))
                XCTAssertFalse(value.contains("abc123xyz"))
                XCTAssertFalse(value.contains("mykey"))
                XCTAssertFalse(value.contains("mycred"))
                XCTAssertFalse(value.contains("authtoken"))
            }
        }
    }
    
    // MARK: - Unit Tests for Specific Examples
    
    func testLogEventCreatesEntry() {
        let event = SecurityEvent(
            type: .jailbreakDetected,
            severity: .critical,
            message: "Test jailbreak detection"
        )
        
        logger.log(event)
        
        let events = logger.getRecentEvents(limit: 1)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.type, .jailbreakDetected)
        XCTAssertEqual(events.first?.severity, .critical)
    }
    
    func testLogEventWithDetails() {
        let event = SecurityEvent(
            type: .debuggerDetected,
            severity: .high,
            message: "Debugger found",
            details: ["debuggerType": "lldb"]
        )
        
        logger.log(event)
        
        let events = logger.getRecentEvents(limit: 1)
        XCTAssertEqual(events.first?.details["debuggerType"], "lldb")
    }
    
    func testClearLogs() {
        let event = SecurityEvent(
            type: .securityCheckPassed,
            severity: .info,
            message: "Check passed"
        )
        
        logger.log(event)
        XCTAssertEqual(logger.getRecentEvents(limit: 10).count, 1)
        
        logger.clearLogs()
        XCTAssertEqual(logger.getRecentEvents(limit: 10).count, 0)
    }
    
    func testGetRecentEventsLimit() {
        for i in 0..<10 {
            let event = SecurityEvent(
                type: .securityCheckPassed,
                severity: .info,
                message: "Event \(i)"
            )
            logger.log(event)
        }
        
        let events = logger.getRecentEvents(limit: 5)
        XCTAssertEqual(events.count, 5)
    }
    
    func testSensitiveDataDetection() {
        XCTAssertTrue(logger.containsSensitiveData("password=test"))
        XCTAssertTrue(logger.containsSensitiveData("my token is here"))
        XCTAssertTrue(logger.containsSensitiveData("api_key: abc123"))
        XCTAssertFalse(logger.containsSensitiveData("normal message"))
        XCTAssertFalse(logger.containsSensitiveData("security check passed"))
    }
    
    func testSecurityEventContainsSensitiveData() {
        let sensitiveEvent = SecurityEvent(
            type: .securityCheckFailed,
            severity: .high,
            message: "Failed with password=secret"
        )
        XCTAssertTrue(sensitiveEvent.containsSensitiveData())
        
        let normalEvent = SecurityEvent(
            type: .securityCheckPassed,
            severity: .info,
            message: "Check completed successfully"
        )
        XCTAssertFalse(normalEvent.containsSensitiveData())
    }
    
    func testSecurityEventToFlutterMap() {
        let event = SecurityEvent(
            type: .jailbreakDetected,
            severity: .critical,
            message: "Jailbreak found",
            details: ["indicator": "cydia"]
        )
        
        let map = event.toFlutterMap()
        
        XCTAssertEqual(map["type"] as? String, "jailbreak_detected")
        XCTAssertEqual(map["severity"] as? String, "critical")
        XCTAssertEqual(map["message"] as? String, "Jailbreak found")
        XCTAssertNotNil(map["timestamp"])
        XCTAssertNotNil(map["id"])
        
        let details = map["details"] as? [String: String]
        XCTAssertEqual(details?["indicator"], "cydia")
    }
    
    func testSecurityEventFactory() {
        let jailbreakEvent = SecurityEventFactory.jailbreakDetected(indicators: [.cydiaInstalled, .sandboxViolation])
        XCTAssertEqual(jailbreakEvent.type, .jailbreakDetected)
        XCTAssertEqual(jailbreakEvent.severity, .critical)
        XCTAssertTrue(jailbreakEvent.details["indicators"]?.contains("cydia_installed") ?? false)
        
        let debuggerEvent = SecurityEventFactory.debuggerDetected(debuggerType: .lldb)
        XCTAssertEqual(debuggerEvent.type, .debuggerDetected)
        XCTAssertEqual(debuggerEvent.severity, .high)
        
        let integrityEvent = SecurityEventFactory.integrityViolation(violations: [.invalidSignature])
        XCTAssertEqual(integrityEvent.type, .integrityViolation)
        XCTAssertEqual(integrityEvent.severity, .critical)
        
        let runtimeEvent = SecurityEventFactory.runtimeThreat(threats: [.fridaServer])
        XCTAssertEqual(runtimeEvent.type, .runtimeThreat)
        XCTAssertEqual(runtimeEvent.severity, .critical)
    }
}


// MARK: - Property 11: Build-Specific Log Levels Tests

extension SecurityLoggerTests {
    
    /// Property test: Build-specific log levels are applied correctly
    /// Feature: ios-binary-protection, Property 11: Build-Specific Log Levels
    /// Validates: Requirements 7.4, 7.5
    func testProperty11_BuildSpecificLogLevelsApplied() {
        // Test with verbose logging disabled (simulating release behavior)
        let releaseLogger = SecurityLogger(verboseLoggingEnabled: false)
        releaseLogger.clearLogs()
        
        // Test with verbose logging enabled (simulating debug behavior)
        let debugLogger = SecurityLogger(verboseLoggingEnabled: true)
        debugLogger.clearLogs()
        
        let severities: [SecuritySeverity] = [.critical, .high, .medium, .low, .info]
        
        // Run 100+ iterations
        for i in 0..<100 {
            let severity = severities[i % severities.count]
            let event = SecurityEvent(
                type: .securityCheckPassed,
                severity: severity,
                message: "Test event \(i)"
            )
            
            // In release mode (verbose disabled), info events should not be logged to system
            // but should still be stored in memory for retrieval
            releaseLogger.log(event)
            debugLogger.log(event)
            
            // Verify wouldLog behavior
            if severity == .info {
                XCTAssertFalse(releaseLogger.wouldLog(event), 
                    "Info events should not be logged to system in release mode")
                XCTAssertTrue(debugLogger.wouldLog(event), 
                    "Info events should be logged in debug mode")
            } else if severity >= .medium {
                XCTAssertTrue(releaseLogger.wouldLog(event), 
                    "Medium+ severity events should be logged in release mode")
            }
        }
        
        // Both loggers should store events in memory regardless of log level
        XCTAssertEqual(releaseLogger.getRecentEvents(limit: 100).count, 100)
        XCTAssertEqual(debugLogger.getRecentEvents(limit: 100).count, 100)
    }
    
    /// Test that verbose logging can be toggled
    func testVerboseLoggingToggle() {
        let logger = SecurityLogger(verboseLoggingEnabled: false)
        XCTAssertFalse(logger.verboseLoggingEnabled)
        
        logger.verboseLoggingEnabled = true
        XCTAssertTrue(logger.verboseLoggingEnabled)
        
        logger.verboseLoggingEnabled = false
        XCTAssertFalse(logger.verboseLoggingEnabled)
    }
    
    /// Test current log level based on configuration
    func testCurrentLogLevel() {
        let verboseLogger = SecurityLogger(verboseLoggingEnabled: true)
        let quietLogger = SecurityLogger(verboseLoggingEnabled: false)
        
        // In debug builds, log level should be info
        // In release builds with verbose disabled, log level should be medium
        #if DEBUG
        XCTAssertEqual(verboseLogger.currentLogLevel, .info)
        XCTAssertEqual(quietLogger.currentLogLevel, .info)
        #else
        XCTAssertEqual(verboseLogger.currentLogLevel, .low)
        XCTAssertEqual(quietLogger.currentLogLevel, .medium)
        #endif
    }
    
    /// Test that release mode minimizes verbose logging
    func testReleaseModeMinimizsVerboseLogging() {
        let releaseLogger = SecurityLogger(verboseLoggingEnabled: false)
        
        let infoEvent = SecurityEvent(
            type: .monitoringStarted,
            severity: .info,
            message: "Monitoring started"
        )
        
        let criticalEvent = SecurityEvent(
            type: .jailbreakDetected,
            severity: .critical,
            message: "Jailbreak detected"
        )
        
        // Info events should not be logged to system in release mode
        XCTAssertFalse(releaseLogger.wouldLog(infoEvent))
        
        // Critical events should always be logged
        XCTAssertTrue(releaseLogger.wouldLog(criticalEvent))
    }
}
