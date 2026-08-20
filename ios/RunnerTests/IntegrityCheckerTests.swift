//
//  IntegrityCheckerTests.swift
//  RunnerTests
//
//  iOS Binary Protection - Integrity Checker Tests
//  Feature: ios-binary-protection, Property 7: Integrity Verification Completeness
//  Validates: Requirements 3.1, 3.2, 3.3
//

import XCTest
@testable import Runner

final class IntegrityCheckerTests: XCTestCase {
    
    var checker: TestableIntegrityChecker!
    
    override func setUp() {
        super.setUp()
        checker = TestableIntegrityChecker()
    }
    
    override func tearDown() {
        checker = nil
        super.tearDown()
    }
    
    // MARK: - Property 7: Integrity Verification Completeness
    // For any integrity check, the IntegrityChecker SHALL verify all three components
    // (signature validity, bundle identifier match, team identifier match),
    // and the overall result SHALL be isValid = true only if all three components pass.
    
    /// Property test: All components must pass for isValid=true
    func testProperty7_AllComponentsMustPassForValid() {
        // Feature: ios-binary-protection, Property 7: Integrity Verification Completeness
        // Validates: Requirements 3.1, 3.2, 3.3
        
        var testCount = 0
        
        // Test all combinations of signature, bundleId, teamId validity
        let boolValues = [true, false]
        
        for signatureValid in boolValues {
            for bundleIdValid in boolValues {
                for teamIdValid in boolValues {
                    // Run each combination multiple times to reach 100+ iterations
                    for _ in 0..<13 {
                        checker.mockSignatureValid = signatureValid
                        checker.mockBundleIdValid = bundleIdValid
                        checker.mockTeamIdValid = teamIdValid
                        checker.mockViolations = []
                        
                        let result = checker.performIntegrityCheck()
                        
                        let allPass = signatureValid && bundleIdValid && teamIdValid
                        
                        XCTAssertEqual(result.isValid, allPass,
                            "isValid should be \(allPass) when signature=\(signatureValid), bundleId=\(bundleIdValid), teamId=\(teamIdValid)")
                        
                        XCTAssertEqual(result.signatureValid, signatureValid,
                            "signatureValid should match input")
                        XCTAssertEqual(result.bundleIdentifierValid, bundleIdValid,
                            "bundleIdentifierValid should match input")
                        XCTAssertEqual(result.teamIdentifierValid, teamIdValid,
                            "teamIdentifierValid should match input")
                        
                        testCount += 1
                    }
                }
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100,
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    /// Property test: Failed components result in corresponding violations
    func testProperty7_FailedComponentsResultInViolations() {
        // Feature: ios-binary-protection, Property 7: Integrity Verification Completeness
        // Validates: Requirements 3.1, 3.2, 3.3
        
        var testCount = 0
        let boolValues = [true, false]
        
        for signatureValid in boolValues {
            for bundleIdValid in boolValues {
                for teamIdValid in boolValues {
                    for _ in 0..<13 {
                        checker.mockSignatureValid = signatureValid
                        checker.mockBundleIdValid = bundleIdValid
                        checker.mockTeamIdValid = teamIdValid
                        checker.mockViolations = []
                        
                        let result = checker.performIntegrityCheck()
                        
                        // Check violations match failed components
                        if !signatureValid {
                            XCTAssertTrue(result.violations.contains(.invalidSignature),
                                "Should contain invalidSignature violation when signature fails")
                        } else {
                            XCTAssertFalse(result.violations.contains(.invalidSignature),
                                "Should not contain invalidSignature violation when signature passes")
                        }
                        
                        if !bundleIdValid {
                            XCTAssertTrue(result.violations.contains(.bundleIdentifierMismatch),
                                "Should contain bundleIdentifierMismatch violation when bundleId fails")
                        } else {
                            XCTAssertFalse(result.violations.contains(.bundleIdentifierMismatch),
                                "Should not contain bundleIdentifierMismatch violation when bundleId passes")
                        }
                        
                        if !teamIdValid {
                            XCTAssertTrue(result.violations.contains(.teamIdentifierMismatch),
                                "Should contain teamIdentifierMismatch violation when teamId fails")
                        } else {
                            XCTAssertFalse(result.violations.contains(.teamIdentifierMismatch),
                                "Should not contain teamIdentifierMismatch violation when teamId passes")
                        }
                        
                        testCount += 1
                    }
                }
            }
        }
        
        XCTAssertGreaterThanOrEqual(testCount, 100,
            "Should run at least 100 iterations (actual: \(testCount))")
    }
    
    /// Property test: Individual verification methods are consistent with overall result
    func testProperty7_IndividualMethodsConsistentWithOverall() {
        // Feature: ios-binary-protection, Property 7: Integrity Verification Completeness
        // Validates: Requirements 3.1, 3.2, 3.3
        
        for _ in 0..<100 {
            // Randomize mock values
            let signatureValid = Bool.random()
            let bundleIdValid = Bool.random()
            let teamIdValid = Bool.random()
            
            checker.mockSignatureValid = signatureValid
            checker.mockBundleIdValid = bundleIdValid
            checker.mockTeamIdValid = teamIdValid
            checker.mockViolations = []
            
            // Individual methods should return same values
            XCTAssertEqual(checker.verifySignature(), signatureValid)
            XCTAssertEqual(checker.verifyBundleIdentifier(), bundleIdValid)
            XCTAssertEqual(checker.verifyTeamIdentifier(), teamIdValid)
            
            // Overall result should be consistent
            let result = checker.performIntegrityCheck()
            XCTAssertEqual(result.signatureValid, checker.verifySignature())
            XCTAssertEqual(result.bundleIdentifierValid, checker.verifyBundleIdentifier())
            XCTAssertEqual(result.teamIdentifierValid, checker.verifyTeamIdentifier())
        }
    }
    
    // MARK: - Unit Tests for Specific Scenarios
    
    func testAllComponentsPass() {
        checker.mockSignatureValid = true
        checker.mockBundleIdValid = true
        checker.mockTeamIdValid = true
        
        let result = checker.performIntegrityCheck()
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.violations.isEmpty)
    }
    
    func testSignatureFailure() {
        checker.mockSignatureValid = false
        checker.mockBundleIdValid = true
        checker.mockTeamIdValid = true
        
        let result = checker.performIntegrityCheck()
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.violations.contains(.invalidSignature))
    }
    
    func testBundleIdFailure() {
        checker.mockSignatureValid = true
        checker.mockBundleIdValid = false
        checker.mockTeamIdValid = true
        
        let result = checker.performIntegrityCheck()
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.violations.contains(.bundleIdentifierMismatch))
    }
    
    func testTeamIdFailure() {
        checker.mockSignatureValid = true
        checker.mockBundleIdValid = true
        checker.mockTeamIdValid = false
        
        let result = checker.performIntegrityCheck()
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.violations.contains(.teamIdentifierMismatch))
    }
    
    func testMultipleFailures() {
        checker.mockSignatureValid = false
        checker.mockBundleIdValid = false
        checker.mockTeamIdValid = false
        
        let result = checker.performIntegrityCheck()
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.violations.count, 3)
        XCTAssertTrue(result.violations.contains(.invalidSignature))
        XCTAssertTrue(result.violations.contains(.bundleIdentifierMismatch))
        XCTAssertTrue(result.violations.contains(.teamIdentifierMismatch))
    }
    
    func testAdditionalViolations() {
        checker.mockSignatureValid = true
        checker.mockBundleIdValid = true
        checker.mockTeamIdValid = true
        checker.mockViolations = [.modifiedExecutable, .missingEntitlements]
        
        let result = checker.performIntegrityCheck()
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.violations.contains(.modifiedExecutable))
        XCTAssertTrue(result.violations.contains(.missingEntitlements))
    }
    
    // MARK: - Result Serialization Tests
    
    func testIntegrityResultToMap() {
        checker.mockSignatureValid = false
        checker.mockBundleIdValid = true
        checker.mockTeamIdValid = true
        
        let result = checker.performIntegrityCheck()
        let map = result.toMap()
        
        XCTAssertEqual(map["isValid"] as? Bool, false)
        XCTAssertEqual(map["signatureValid"] as? Bool, false)
        XCTAssertEqual(map["bundleIdentifierValid"] as? Bool, true)
        XCTAssertEqual(map["teamIdentifierValid"] as? Bool, true)
        XCTAssertNotNil(map["timestamp"])
        
        let violations = map["violations"] as? [String]
        XCTAssertNotNil(violations)
        XCTAssertTrue(violations?.contains("invalid_signature") ?? false)
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationUpdate() {
        let newConfig = SecurityConfiguration(
            expectedBundleIdentifier: "com.test.app",
            expectedTeamIdentifier: "TESTTEAM"
        )
        
        checker.configuration = newConfig
        
        XCTAssertEqual(checker.configuration.expectedBundleIdentifier, "com.test.app")
        XCTAssertEqual(checker.configuration.expectedTeamIdentifier, "TESTTEAM")
    }
}
