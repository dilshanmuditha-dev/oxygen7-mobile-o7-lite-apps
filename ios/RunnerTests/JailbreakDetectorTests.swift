//
//  JailbreakDetectorTests.swift
//  RunnerTests
//
//  iOS Binary Protection - Jailbreak Detector Tests
//  Feature: ios-binary-protection, Property 1: Jailbreak Indicator Detection Completeness
//  Validates: Requirements 1.1, 1.2, 1.3, 1.4
//

import XCTest
@testable import Runner

final class JailbreakDetectorTests: XCTestCase {
    
    var detector: TestableJailbreakDetector!
    
    override func setUp() {
        super.setUp()
        detector = TestableJailbreakDetector()
    }
    
    override func tearDown() {
        detector = nil
        super.tearDown()
    }
    
    // MARK: - Property 1: Jailbreak Indicator Detection Completeness
    // For any set of jailbreak indicators, if any indicator is present on the device,
    // the JailbreakDetector SHALL return isJailbroken = true with the detected indicators listed.
    
    /// Property test: Any present jailbreak indicator results in isJailbroken=true
    func testProperty1_AnyIndicatorResultsInJailbroken() {
        // Feature: ios-binary-protection, Property 1: Jailbreak Indicator Detection Completeness
        // Validates: Requirements 1.1, 1.2, 1.3, 1.4
        
        let allIndicators = JailbreakIndicator.allCases
        var testCount = 0
        
        // Test each individual indicator (10 indicators)
        for indicator in allIndicators {
            detector.mockIndicators = [indicator]
            let result = detector.isJailbroken()
            
            XCTAssertTrue(result.isJailbroken, 
                "Single indicator \(indicator.rawValue) should result in isJailbroken=true")
            XCTAssertTrue(result.indicators.contains(indicator),
                "Result should contain the detected indicator \(indicator.rawValue)")
            testCount += 1
        }
        
        // Test combinations of 2 indicators
        for i in 0..<allIndicators.count {
            for j in (i+1)..<allIndicators.count {
                detector.mockIndicators = [allIndicators[i], allIndicators[j]]
                let result = detector.isJailbroken()
                
                XCTAssertTrue(result.isJailbroken,
                    "Two indicators should result in isJailbroken=true")
                XCTAssertTrue(result.indicators.contains(allIndicators[i]))
                XCTAssertTrue(result.indicators.contains(allIndicators[j]))
                testCount += 1
            }
        }
        
        // Test combinations of 3 indicators
        for i in 0..<allIndicators.count {
            for j in (i+1)..<allIndicators.count {
                for k in (j+1)..<allIndicators.count {
                    detector.mockIndicators = [allIndicators[i], allIndicators[j], allIndicators[k]]
                    let result = detector.isJailbroken()
                    
                    XCTAssertTrue(result.isJailbroken,
                        "Three indicators should result in isJailbroken=true")
                    XCTAssertEqual(result.confidence, .high,
                        "Three or more indicators should have high confidence")
                    testCount += 1
                }
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100, 
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    /// Property test: No indicators results in isJailbroken=false
    func testProperty1_NoIndicatorsResultsInNotJailbroken() {
        // Feature: ios-binary-protection, Property 1: Jailbreak Indicator Detection Completeness
        // Validates: Requirements 1.1, 1.2, 1.3, 1.4
        
        // Run 100 iterations with empty indicators
        for _ in 0..<100 {
            detector.mockIndicators = []
            let result = detector.isJailbroken()
            
            XCTAssertFalse(result.isJailbroken,
                "No indicators should result in isJailbroken=false")
            XCTAssertTrue(result.indicators.isEmpty,
                "Indicators list should be empty")
            XCTAssertEqual(result.confidence, .unknown,
                "Confidence should be unknown when no indicators")
        }
    }
    
    /// Property test: All detected indicators are included in result
    func testProperty1_AllDetectedIndicatorsIncludedInResult() {
        // Feature: ios-binary-protection, Property 1: Jailbreak Indicator Detection Completeness
        // Validates: Requirements 1.1, 1.2, 1.3, 1.4
        
        let allIndicators = JailbreakIndicator.allCases
        
        // Test random subsets of indicators (100+ iterations)
        for seed in 0..<100 {
            // Create a deterministic "random" subset based on seed
            var subset: Set<JailbreakIndicator> = []
            for (index, indicator) in allIndicators.enumerated() {
                if (seed + index) % 3 == 0 { // Deterministic selection
                    subset.insert(indicator)
                }
            }
            
            detector.mockIndicators = subset
            let result = detector.isJailbroken()
            
            // Verify all mock indicators are in result
            for indicator in subset {
                XCTAssertTrue(result.indicators.contains(indicator),
                    "Result should contain indicator \(indicator.rawValue)")
            }
            
            // Verify result doesn't contain indicators not in mock
            for indicator in result.indicators {
                XCTAssertTrue(subset.contains(indicator),
                    "Result should not contain indicator \(indicator.rawValue) that wasn't mocked")
            }
        }
    }
    
    // MARK: - Unit Tests for Specific Indicators
    
    func testCydiaIndicator() {
        detector.mockIndicators = [.cydiaInstalled]
        let result = detector.isJailbroken()
        
        XCTAssertTrue(result.isJailbroken)
        XCTAssertTrue(result.indicators.contains(.cydiaInstalled))
    }
    
    func testSileoIndicator() {
        detector.mockIndicators = [.sileoInstalled]
        let result = detector.isJailbroken()
        
        XCTAssertTrue(result.isJailbroken)
        XCTAssertTrue(result.indicators.contains(.sileoInstalled))
    }
    
    func testSandboxViolationIndicator() {
        detector.mockIndicators = [.sandboxViolation]
        let result = detector.isJailbroken()
        
        XCTAssertTrue(result.isJailbroken)
        XCTAssertTrue(result.indicators.contains(.sandboxViolation))
    }
    
    func testSymbolicLinksIndicator() {
        detector.mockIndicators = [.symbolicLinks]
        let result = detector.isJailbroken()
        
        XCTAssertTrue(result.isJailbroken)
        XCTAssertTrue(result.indicators.contains(.symbolicLinks))
    }
    
    func testSuspiciousFilesIndicator() {
        detector.mockIndicators = [.suspiciousFiles]
        let result = detector.isJailbroken()
        
        XCTAssertTrue(result.isJailbroken)
        XCTAssertTrue(result.indicators.contains(.suspiciousFiles))
    }
    
    // MARK: - Confidence Level Tests
    
    func testConfidenceLevelHigh() {
        // High confidence with 3+ indicators
        detector.mockIndicators = [.cydiaInstalled, .sandboxViolation, .suspiciousLibraries]
        let result = detector.isJailbroken()
        
        XCTAssertEqual(result.confidence, .high)
    }
    
    func testConfidenceLevelMedium() {
        // Medium confidence with 2 indicators
        detector.mockIndicators = [.suspiciousFiles, .symbolicLinks]
        let result = detector.isJailbroken()
        
        XCTAssertEqual(result.confidence, .medium)
    }
    
    func testConfidenceLevelLow() {
        // Low confidence with 1 indicator
        detector.mockIndicators = [.suspiciousURLSchemes]
        let result = detector.isJailbroken()
        
        XCTAssertEqual(result.confidence, .low)
    }
    
    func testConfidenceLevelUnknown() {
        // Unknown confidence with no indicators
        detector.mockIndicators = []
        let result = detector.isJailbroken()
        
        XCTAssertEqual(result.confidence, .unknown)
    }
    
    // MARK: - Result Serialization Tests
    
    func testJailbreakResultToMap() {
        detector.mockIndicators = [.cydiaInstalled, .sandboxViolation]
        let result = detector.isJailbroken()
        let map = result.toMap()
        
        XCTAssertEqual(map["isJailbroken"] as? Bool, true)
        XCTAssertEqual(map["confidence"] as? String, "medium")
        XCTAssertNotNil(map["timestamp"])
        
        let indicators = map["indicators"] as? [String]
        XCTAssertNotNil(indicators)
        XCTAssertTrue(indicators?.contains("cydia_installed") ?? false)
        XCTAssertTrue(indicators?.contains("sandbox_violation") ?? false)
    }
    
    func testGetJailbreakIndicators() {
        detector.mockIndicators = [.cydiaInstalled, .sileoInstalled]
        let indicators = detector.getJailbreakIndicators()
        
        XCTAssertEqual(indicators.count, 2)
        XCTAssertTrue(indicators.contains(.cydiaInstalled))
        XCTAssertTrue(indicators.contains(.sileoInstalled))
    }
}
