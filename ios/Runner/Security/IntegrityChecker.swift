//
//  IntegrityChecker.swift
//  Runner
//
//  iOS Binary Protection - Binary Integrity Verification Implementation
//

import Foundation
import UIKit
import MachO

// MARK: - Integrity Checker

/// Implementation of binary integrity verification for iOS applications
/// Note: iOS doesn't expose the same Security framework APIs as macOS,
/// so we use alternative methods for integrity verification.
final class IntegrityChecker: IntegrityCheckerProtocol {
    
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = IntegrityChecker()
    
    /// Configuration for expected values
    var configuration: SecurityConfiguration
    
    /// Logger for security events
    private let logger: SecurityLoggerProtocol
    
    /// Bundle for verification
    private let bundle: Bundle
    
    // MARK: - Initialization
    
    init(configuration: SecurityConfiguration = .default,
         logger: SecurityLoggerProtocol = SecurityLogger.shared,
         bundle: Bundle = .main) {
        self.configuration = configuration
        self.logger = logger
        self.bundle = bundle
    }
    
    // MARK: - IntegrityCheckerProtocol
    
    /// Verifies application signature by checking various integrity indicators
    func verifySignature() -> Bool {
        // On iOS, we can't directly access code signing APIs like on macOS
        // Instead, we verify integrity through multiple indirect checks
        
        // Check 1: Verify the app is running from expected location
        guard let bundlePath = bundle.bundlePath as String? else {
            return false
        }
        
        // App should be in /var/containers/Bundle/Application/ on device
        // or in simulator paths during development
        let validPrefixes = [
            "/var/containers/Bundle/Application/",
            "/private/var/containers/Bundle/Application/",
            "/Users/" // Simulator path
        ]
        
        let hasValidPath = validPrefixes.contains { bundlePath.hasPrefix($0) }
        if !hasValidPath {
            return false
        }
        
        // Check 2: Verify executable exists and is readable
        guard let executablePath = bundle.executablePath,
              FileManager.default.fileExists(atPath: executablePath),
              FileManager.default.isReadableFile(atPath: executablePath) else {
            return false
        }
        
        // Check 3: Verify Info.plist exists and is valid
        guard bundle.infoDictionary != nil else {
            return false
        }
        
        // Check 4: Verify embedded.mobileprovision exists (for non-App Store builds)
        // App Store builds don't have this file, so we only check in debug
        #if DEBUG
        let provisionPath = bundlePath + "/embedded.mobileprovision"
        // In debug, we expect the provision file to exist
        if !FileManager.default.fileExists(atPath: provisionPath) {
            // This is okay for simulator builds
            #if !targetEnvironment(simulator)
            return false
            #endif
        }
        #endif
        
        return true
    }
    
    /// Verifies bundle identifier
    func verifyBundleIdentifier() -> Bool {
        guard let bundleId = bundle.bundleIdentifier else {
            return false
        }
        
        let expectedBundleId = configuration.expectedBundleIdentifier
        
        // If no expected bundle ID is configured, use the current one
        if expectedBundleId.isEmpty {
            return true
        }
        
        return bundleId == expectedBundleId
    }
    
    /// Verifies team identifier
    func verifyTeamIdentifier() -> Bool {
        // Get team identifier from embedded provisioning profile
        guard let teamId = getTeamIdentifier() else {
            // If we can't get team ID, check if one is expected
            return configuration.expectedTeamIdentifier.isEmpty
        }
        
        let expectedTeamId = configuration.expectedTeamIdentifier
        
        // If no expected team ID is configured, accept any
        if expectedTeamId.isEmpty {
            return true
        }
        
        return teamId == expectedTeamId
    }
    
    /// Performs comprehensive integrity check
    func performIntegrityCheck() -> IntegrityResult {
        var violations: [IntegrityViolation] = []
        
        // On simulator, skip most checks as they don't apply
        #if targetEnvironment(simulator)
        return IntegrityResult(
            isValid: true,
            signatureValid: true,
            bundleIdentifierValid: true,
            teamIdentifierValid: true,
            violations: []
        )
        #else
        
        let signatureValid = verifySignature()
        if !signatureValid {
            violations.append(.invalidSignature)
        }
        
        let bundleIdValid = verifyBundleIdentifier()
        if !bundleIdValid {
            violations.append(.bundleIdentifierMismatch)
        }
        
        let teamIdValid = verifyTeamIdentifier()
        if !teamIdValid {
            violations.append(.teamIdentifierMismatch)
        }
        
        // Check for modified executable
        if checkExecutableModified() {
            violations.append(.modifiedExecutable)
        }
        
        // Check for suspicious libraries
        if checkSuspiciousLibraries() {
            violations.append(.suspiciousLibraries)
        }
        
        let isValid = violations.isEmpty
        
        return IntegrityResult(
            isValid: isValid,
            signatureValid: signatureValid,
            bundleIdentifierValid: bundleIdValid,
            teamIdentifierValid: teamIdValid,
            violations: violations
        )
        #endif
    }
    
    // MARK: - Private Methods
    
    /// Gets the team identifier from embedded provisioning profile
    private func getTeamIdentifier() -> String? {
        guard let bundlePath = bundle.bundlePath as String? else {
            return nil
        }
        
        let provisionPath = bundlePath + "/embedded.mobileprovision"
        
        guard let provisionData = FileManager.default.contents(atPath: provisionPath) else {
            // Try to get from entitlements via app groups
            return getTeamIdFromAppGroups()
        }
        
        // Parse the provisioning profile (it's a signed plist)
        guard let provisionString = String(data: provisionData, encoding: .ascii) else {
            return nil
        }
        
        // Find the plist content between <?xml and </plist>
        guard let startRange = provisionString.range(of: "<?xml"),
              let endRange = provisionString.range(of: "</plist>") else {
            return nil
        }
        
        let plistString = String(provisionString[startRange.lowerBound...endRange.upperBound])
        
        guard let plistData = plistString.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }
        
        // Get TeamIdentifier from the profile
        if let teamIds = plist["TeamIdentifier"] as? [String], let teamId = teamIds.first {
            return teamId
        }
        
        return nil
    }
    
    /// Attempts to get team ID from app groups entitlement
    private func getTeamIdFromAppGroups() -> String? {
        // App groups are formatted as "group.TEAMID.bundleid"
        // We can try to extract the team ID from there
        guard let bundleId = bundle.bundleIdentifier else {
            return nil
        }
        
        // Check if we have any app group containers
        let fileManager = FileManager.default
        let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.\(bundleId)")
        
        if containerURL != nil {
            // We have access to an app group, but can't easily extract team ID
            // Return nil and let the caller handle it
            return nil
        }
        
        return nil
    }
    
    /// Checks if the executable has been modified
    private func checkExecutableModified() -> Bool {
        guard let executablePath = bundle.executablePath else {
            return true // Can't verify, assume modified
        }
        
        // Check if executable exists and is readable
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: executablePath),
              fileManager.isReadableFile(atPath: executablePath) else {
            return true
        }
        
        // Verify the executable is in the expected location
        let expectedPrefix = bundle.bundlePath
        guard executablePath.hasPrefix(expectedPrefix) else {
            return true
        }
        
        // Check Mach-O header validity
        if !verifyMachOHeader() {
            return true
        }
        
        return false
    }
    
    /// Verifies the Mach-O header of the executable
    private func verifyMachOHeader() -> Bool {
        guard let executablePath = bundle.executablePath else {
            return false
        }
        
        guard let fileHandle = FileHandle(forReadingAtPath: executablePath) else {
            return false
        }
        
        defer { fileHandle.closeFile() }
        
        // Read the magic number (first 4 bytes)
        let magicData = fileHandle.readData(ofLength: 4)
        guard magicData.count == 4 else {
            return false
        }
        
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        // Valid Mach-O magic numbers
        let validMagics: [UInt32] = [
            MH_MAGIC,      // 32-bit
            MH_CIGAM,      // 32-bit swapped
            MH_MAGIC_64,   // 64-bit
            MH_CIGAM_64,   // 64-bit swapped
            FAT_MAGIC,     // Fat binary
            FAT_CIGAM      // Fat binary swapped
        ]
        
        return validMagics.contains(magic)
    }
    
    /// Checks for suspicious loaded libraries
    private func checkSuspiciousLibraries() -> Bool {
        let suspiciousPatterns = [
            "MobileSubstrate",
            "SubstrateLoader",
            "CydiaSubstrate",
            "libcycript",
            "cynject",
            "FridaGadget",
            "frida"
        ]
        
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageNamePtr = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageNamePtr).lowercased()
            
            for pattern in suspiciousPatterns {
                if name.contains(pattern.lowercased()) {
                    return true
                }
            }
        }
        
        return false
    }
}

// MARK: - Testable Interface

/// Testable version of IntegrityChecker for unit tests
final class TestableIntegrityChecker: IntegrityCheckerProtocol {
    
    var configuration: SecurityConfiguration
    
    var mockSignatureValid: Bool = true
    var mockBundleIdValid: Bool = true
    var mockTeamIdValid: Bool = true
    var mockViolations: [IntegrityViolation] = []
    
    init(configuration: SecurityConfiguration = .default) {
        self.configuration = configuration
    }
    
    func verifySignature() -> Bool {
        return mockSignatureValid
    }
    
    func verifyBundleIdentifier() -> Bool {
        return mockBundleIdValid
    }
    
    func verifyTeamIdentifier() -> Bool {
        return mockTeamIdValid
    }
    
    func performIntegrityCheck() -> IntegrityResult {
        var violations = mockViolations
        
        if !mockSignatureValid && !violations.contains(.invalidSignature) {
            violations.append(.invalidSignature)
        }
        if !mockBundleIdValid && !violations.contains(.bundleIdentifierMismatch) {
            violations.append(.bundleIdentifierMismatch)
        }
        if !mockTeamIdValid && !violations.contains(.teamIdentifierMismatch) {
            violations.append(.teamIdentifierMismatch)
        }
        
        let isValid = mockSignatureValid && mockBundleIdValid && mockTeamIdValid && mockViolations.isEmpty
        
        return IntegrityResult(
            isValid: isValid,
            signatureValid: mockSignatureValid,
            bundleIdentifierValid: mockBundleIdValid,
            teamIdentifierValid: mockTeamIdValid,
            violations: violations
        )
    }
}
