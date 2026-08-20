//
//  DebuggerDetectorTests.swift
//  RunnerTests
//
//  iOS Binary Protection - Debugger Detector Tests
//  Feature: ios-binary-protection, Property 5: Debugger Detection Accuracy
//  Feature: ios-binary-protection, Property 6: Debug Build Exemption
//  Validates: Requirements 2.1, 2.2, 2.6
//

import XCTest
@testable import Runner

final class DebuggerDetectorTests: XCTestCase {
    
    var detector: TestableDebuggerDetector!
    
    override func setUp() {
        super.setUp()
        detector = TestableDebuggerDetector()
    }
    
    override func tearDown() {
        detector = nil
        super.tearDown()
    }
    
    // MARK: - Property 5: Debugger Detection Accuracy
    // For any debugger type in the known set (LLDB, GDB, Frida, Cycript),
    // if that debugger is attached to the process, the DebuggerDetector
    // SHALL return isDebugging = true with the correct debugger type identified.
    
    /// Property test: Any debugger type results in isDebugging=true with correct type
    func testProperty5_AnyDebuggerTypeResultsInDebugging() {
        // Feature: ios-binary-protection, Property 5: Debugger Detection Accuracy
        // Validates: Requirements 2.1, 2.2
        
        let debuggerTypes: [DebuggerType] = [.lldb, .gdb, .frida, .cycript, .unknown]
        var testCount = 0
        
        // Test each debugger type multiple times (100+ iterations)
        for _ in 0..<20 {
            for debuggerType in debuggerTypes {
                detector.mockIsDebugging = true
                detector.mockDebuggerType = debuggerType
                detector.isDebugBuild = false
                detector.skipAlertsInDebugBuild = true
                
                let result = detector.detectDebugger()
                
                XCTAssertTrue(result.isDebugging,
                    "Debugger type \(debuggerType.rawValue) should result in isDebugging=true")
                XCTAssertEqual(result.debuggerType, debuggerType,
                    "Debugger type should be correctly identified as \(debuggerType.rawValue)")
                
                testCount += 1
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100,
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    /// Property test: No debugger results in isDebugging=false
    func testProperty5_NoDebuggerResultsInNotDebugging() {
        // Feature: ios-binary-protection, Property 5: Debugger Detection Accuracy
        // Validates: Requirements 2.1, 2.2
        
        // Run 100 iterations with no debugger
        for _ in 0..<100 {
            detector.mockIsDebugging = false
            detector.mockDebuggerType = nil
            detector.isDebugBuild = false
            
            let result = detector.detectDebugger()
            
            XCTAssertFalse(result.isDebugging,
                "No debugger should result in isDebugging=false")
            XCTAssertNil(result.debuggerType,
                "Debugger type should be nil when no debugger")
        }
    }
    
    /// Property test: isDebuggerAttached returns consistent results
    func testProperty5_IsDebuggerAttachedConsistency() {
        // Feature: ios-binary-protection, Property 5: Debugger Detection Accuracy
        // Validates: Requirements 2.1, 2.2
        
        // Test 100+ iterations
        for i in 0..<100 {
            let isDebugging = i % 2 == 0
            detector.mockIsDebugging = isDebugging
            detector.isDebugBuild = false
            
            let attached = detector.isDebuggerAttached()
            let result = detector.detectDebugger()
            
            XCTAssertEqual(attached, result.isDebugging,
                "isDebuggerAttached should be consistent with detectDebugger")
        }
    }
    
    // MARK: - Property 6: Debug Build Exemption
    // For any debug build configuration, the DebuggerDetector SHALL NOT trigger
    // security alerts when a debugger is attached, allowing normal development workflow.
    
    /// Property test: Debug builds with skipAlerts don't trigger alerts
    func testProperty6_DebugBuildExemption() {
        // Feature: ios-binary-protection, Property 6: Debug Build Exemption
        // Validates: Requirements 2.6
        
        let debuggerTypes: [DebuggerType?] = [.lldb, .gdb, .frida, .cycript, .unknown, nil]
        var testCount = 0
        
        // Test all debugger types in debug build mode (100+ iterations)
        for _ in 0..<17 {
            for debuggerType in debuggerTypes {
                detector.mockIsDebugging = true
                detector.mockDebuggerType = debuggerType
                detector.isDebugBuild = true
                detector.skipAlertsInDebugBuild = true
                
                let result = detector.detectDebugger()
                let attached = detector.isDebuggerAttached()
                
                XCTAssertFalse(result.isDebugging,
                    "Debug build with skipAlerts should not report debugging")
                XCTAssertFalse(attached,
                    "Debug build with skipAlerts should not report debugger attached")
                
                testCount += 1
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100,
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    /// Property test: Debug builds without skipAlerts still detect debuggers
    func testProperty6_DebugBuildWithoutExemption() {
        // Feature: ios-binary-protection, Property 6: Debug Build Exemption
        // Validates: Requirements 2.6
        
        // When skipAlertsInDebugBuild is false, debuggers should be detected
        for _ in 0..<100 {
            detector.mockIsDebugging = true
            detector.mockDebuggerType = .lldb
            detector.isDebugBuild = true
            detector.skipAlertsInDebugBuild = false
            
            let result = detector.detectDebugger()
            
            XCTAssertTrue(result.isDebugging,
                "Debug build without skipAlerts should detect debugger")
            XCTAssertEqual(result.debuggerType, .lldb,
                "Debugger type should be correctly identified")
        }
    }
    
    /// Property test: Release builds always detect debuggers
    func testProperty6_ReleaseBuildAlwaysDetects() {
        // Feature: ios-binary-protection, Property 6: Debug Build Exemption
        // Validates: Requirements 2.6
        
        let debuggerTypes: [DebuggerType] = [.lldb, .gdb, .frida, .cycript, .unknown]
        var testCount = 0
        
        // Test all debugger types in release build mode
        for _ in 0..<20 {
            for debuggerType in debuggerTypes {
                detector.mockIsDebugging = true
                detector.mockDebuggerType = debuggerType
                detector.isDebugBuild = false
                detector.skipAlertsInDebugBuild = true // Should be ignored in release
                
                let result = detector.detectDebugger()
                
                XCTAssertTrue(result.isDebugging,
                    "Release build should always detect debugger")
                XCTAssertEqual(result.debuggerType, debuggerType,
                    "Debugger type should be correctly identified in release")
                
                testCount += 1
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100,
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    // MARK: - Unit Tests for Specific Debugger Types
    
    func testLLDBDetection() {
        detector.mockIsDebugging = true
        detector.mockDebuggerType = .lldb
        detector.isDebugBuild = false
        
        let result = detector.detectDebugger()
        
        XCTAssertTrue(result.isDebugging)
        XCTAssertEqual(result.debuggerType, .lldb)
    }
    
    func testGDBDetection() {
        detector.mockIsDebugging = true
        detector.mockDebuggerType = .gdb
        detector.isDebugBuild = false
        
        let result = detector.detectDebugger()
        
        XCTAssertTrue(result.isDebugging)
        XCTAssertEqual(result.debuggerType, .gdb)
    }
    
    func testFridaDetection() {
        detector.mockIsDebugging = true
        detector.mockDebuggerType = .frida
        detector.isDebugBuild = false
        
        let result = detector.detectDebugger()
        
        XCTAssertTrue(result.isDebugging)
        XCTAssertEqual(result.debuggerType, .frida)
    }
    
    func testCycriptDetection() {
        detector.mockIsDebugging = true
        detector.mockDebuggerType = .cycript
        detector.isDebugBuild = false
        
        let result = detector.detectDebugger()
        
        XCTAssertTrue(result.isDebugging)
        XCTAssertEqual(result.debuggerType, .cycript)
    }
    
    // MARK: - Result Serialization Tests
    
    func testDebuggerResultToMap() {
        detector.mockIsDebugging = true
        detector.mockDebuggerType = .frida
        detector.isDebugBuild = false
        
        let result = detector.detectDebugger()
        let map = result.toMap()
        
        XCTAssertEqual(map["isDebugging"] as? Bool, true)
        XCTAssertEqual(map["debuggerType"] as? String, "frida")
        XCTAssertNotNil(map["timestamp"])
    }
    
    func testDebuggerResultToMapWithoutType() {
        detector.mockIsDebugging = false
        detector.mockDebuggerType = nil
        detector.isDebugBuild = false
        
        let result = detector.detectDebugger()
        let map = result.toMap()
        
        XCTAssertEqual(map["isDebugging"] as? Bool, false)
        XCTAssertNil(map["debuggerType"])
    }
    
    // MARK: - Skip Alerts Toggle Tests
    
    func testSkipAlertsToggle() {
        detector.skipAlertsInDebugBuild = false
        XCTAssertFalse(detector.skipAlertsInDebugBuild)
        
        detector.skipAlertsInDebugBuild = true
        XCTAssertTrue(detector.skipAlertsInDebugBuild)
    }
}
