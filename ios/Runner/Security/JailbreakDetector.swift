//
//  JailbreakDetector.swift
//  Runner
//
//  iOS Binary Protection - Jailbreak Detection Implementation
//

import Foundation
import UIKit
import MachO

// MARK: - Jailbreak Detector

/// Implementation of jailbreak detection for iOS devices
final class JailbreakDetector: JailbreakDetectorProtocol {
    
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = JailbreakDetector()
    
    /// File manager for file system checks
    private let fileManager: FileManager
    
    /// Logger for security events
    private let logger: SecurityLoggerProtocol
    
    /// Suspicious file paths associated with jailbreak
    private let suspiciousFilePaths: [String] = [
        "/Applications/Cydia.app",
        "/Applications/Sileo.app",
        "/Applications/Zebra.app",
        "/Applications/Installer.app",
        "/Applications/Icy.app",
        "/Applications/MxTube.app",
        "/Applications/RockApp.app",
        "/Applications/SBSettings.app",
        "/Applications/blackra1n.app",
        "/Applications/FakeCarrier.app",
        "/Applications/WinterBoard.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/Library/MobileSubstrate/DynamicLibraries",
        "/var/lib/apt",
        "/var/lib/cydia",
        "/var/cache/apt",
        "/var/log/syslog",
        "/var/tmp/cydia.log",
        "/bin/bash",
        "/bin/sh",
        "/usr/sbin/sshd",
        "/usr/bin/sshd",
        "/usr/libexec/sftp-server",
        "/usr/bin/ssh",
        "/etc/apt",
        "/etc/ssh/sshd_config",
        "/private/var/lib/apt",
        "/private/var/lib/cydia",
        "/private/var/stash",
        "/private/var/mobile/Library/SBSettings/Themes",
        "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        "/private/var/tmp/cydia.log",
        "/usr/libexec/cydia",
        "/usr/local/bin/cycript",
        "/usr/bin/cycript",
        "/usr/lib/libcycript.dylib"
    ]
    
    /// Suspicious URL schemes
    private let suspiciousURLSchemes: [String] = [
        "cydia://",
        "sileo://",
        "zbra://",
        "filza://",
        "undecimus://"
    ]
    
    /// Symbolic link paths to check
    private let symbolicLinkPaths: [String] = [
        "/Applications",
        "/var/stash/Library/Ringtones",
        "/var/stash/Library/Wallpaper",
        "/var/stash/usr/include",
        "/var/stash/usr/libexec",
        "/var/stash/usr/share",
        "/var/stash/usr/arm-apple-darwin9"
    ]
    
    /// Paths to test write access (sandbox violation)
    private let sandboxTestPaths: [String] = [
        "/private/jailbreak_test.txt",
        "/private/var/mobile/jailbreak_test.txt"
    ]
    
    // MARK: - Initialization
    
    init(fileManager: FileManager = .default, logger: SecurityLoggerProtocol = SecurityLogger.shared) {
        self.fileManager = fileManager
        self.logger = logger
    }
    
    // MARK: - JailbreakDetectorProtocol
    
    /// Performs comprehensive jailbreak detection
    func isJailbroken() -> JailbreakResult {
        // On simulator, skip jailbreak checks as they don't apply
        #if targetEnvironment(simulator)
        return JailbreakResult(
            isJailbroken: false,
            confidence: .unknown,
            indicators: []
        )
        #else
        
        var indicators: [JailbreakIndicator] = []
        
        // Check for Cydia
        if checkForCydia() {
            indicators.append(.cydiaInstalled)
        }
        
        // Check for Sileo
        if checkForSileo() {
            indicators.append(.sileoInstalled)
        }
        
        // Check for Zebra
        if checkForZebra() {
            indicators.append(.zebbraInstalled)
        }
        
        // Check for suspicious files
        if checkForSuspiciousFiles() {
            indicators.append(.suspiciousFiles)
        }
        
        // Check sandbox integrity
        if checkSandboxViolation() {
            indicators.append(.sandboxViolation)
        }
        
        // Check for symbolic links
        if checkForSymbolicLinks() {
            indicators.append(.symbolicLinks)
        }
        
        // Check for writable system paths
        if checkWritableSystemPaths() {
            indicators.append(.writableSystemPaths)
        }
        
        // Check for suspicious libraries
        if checkForSuspiciousLibraries() {
            indicators.append(.suspiciousLibraries)
        }
        
        // Check if fork is allowed
        if checkForkAllowed() {
            indicators.append(.forkAllowed)
        }
        
        // Check for suspicious URL schemes
        if checkForSuspiciousURLSchemes() {
            indicators.append(.suspiciousURLSchemes)
        }
        
        let isJailbroken = !indicators.isEmpty
        let confidence = calculateConfidence(indicators: indicators)
        
        return JailbreakResult(
            isJailbroken: isJailbroken,
            confidence: confidence,
            indicators: indicators
        )
        #endif
    }
    
    /// Returns detailed jailbreak indicators found
    func getJailbreakIndicators() -> [JailbreakIndicator] {
        return isJailbroken().indicators
    }
    
    // MARK: - Detection Methods
    
    /// Checks for Cydia app installation
    private func checkForCydia() -> Bool {
        let cydiaPath = "/Applications/Cydia.app"
        
        if fileManager.fileExists(atPath: cydiaPath) {
            return true
        }
        
        // Also check via URL scheme
        if let url = URL(string: "cydia://package/com.example.package") {
            return UIApplication.shared.canOpenURL(url)
        }
        
        return false
    }
    
    /// Checks for Sileo app installation
    private func checkForSileo() -> Bool {
        let sileoPath = "/Applications/Sileo.app"
        
        if fileManager.fileExists(atPath: sileoPath) {
            return true
        }
        
        if let url = URL(string: "sileo://package/com.example.package") {
            return UIApplication.shared.canOpenURL(url)
        }
        
        return false
    }
    
    /// Checks for Zebra app installation
    private func checkForZebra() -> Bool {
        let zebraPath = "/Applications/Zebra.app"
        
        if fileManager.fileExists(atPath: zebraPath) {
            return true
        }
        
        if let url = URL(string: "zbra://packages/com.example.package") {
            return UIApplication.shared.canOpenURL(url)
        }
        
        return false
    }
    
    /// Checks for suspicious file paths
    private func checkForSuspiciousFiles() -> Bool {
        for path in suspiciousFilePaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    /// Checks sandbox integrity by attempting to write outside sandbox
    private func checkSandboxViolation() -> Bool {
        for path in sandboxTestPaths {
            let testString = "jailbreak_test"
            
            do {
                try testString.write(toFile: path, atomically: true, encoding: .utf8)
                // If write succeeds, sandbox is violated
                try? fileManager.removeItem(atPath: path)
                return true
            } catch {
                // Write failed, sandbox is intact for this path
                continue
            }
        }
        return false
    }
    
    /// Checks for symbolic links in system directories
    private func checkForSymbolicLinks() -> Bool {
        for path in symbolicLinkPaths {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: path)
                if let fileType = attributes[.type] as? FileAttributeType,
                   fileType == .typeSymbolicLink {
                    return true
                }
            } catch {
                // Path doesn't exist or can't be accessed
                continue
            }
        }
        return false
    }
    
    /// Checks if system paths are writable
    private func checkWritableSystemPaths() -> Bool {
        let systemPaths = [
            "/",
            "/private",
            "/private/var",
            "/System"
        ]
        
        for path in systemPaths {
            if fileManager.isWritableFile(atPath: path) {
                return true
            }
        }
        return false
    }
    
    /// Checks for suspicious dynamic libraries
    private func checkForSuspiciousLibraries() -> Bool {
        let suspiciousLibraries = [
            "MobileSubstrate",
            "SubstrateLoader",
            "SubstrateInserter",
            "SubstrateBootstrap",
            "CydiaSubstrate",
            "cynject",
            "libcycript",
            "FridaGadget",
            "frida"
        ]
        
        // Check loaded libraries using dyld
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageNamePtr = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageNamePtr)
            
            for suspicious in suspiciousLibraries {
                if name.lowercased().contains(suspicious.lowercased()) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Checks if fork() is allowed (should be blocked on non-jailbroken devices)
    /// Note: fork() is unavailable on iOS, so we use alternative detection
    private func checkForkAllowed() -> Bool {
        // On iOS, fork() is not available. Instead, we check for other indicators
        // that would suggest the device has been modified to allow process spawning
        
        // Check for presence of bash/sh which would indicate jailbreak
        let shellPaths = ["/bin/bash", "/bin/sh", "/usr/bin/bash", "/usr/bin/sh"]
        for path in shellPaths {
            if fileManager.fileExists(atPath: path) {
                // Check if it's executable
                if fileManager.isExecutableFile(atPath: path) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Checks for suspicious URL schemes
    private func checkForSuspiciousURLSchemes() -> Bool {
        for scheme in suspiciousURLSchemes {
            if let url = URL(string: scheme) {
                if UIApplication.shared.canOpenURL(url) {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Helper Methods
    
    /// Calculates confidence level based on number and type of indicators
    private func calculateConfidence(indicators: [JailbreakIndicator]) -> DetectionConfidence {
        if indicators.isEmpty {
            return .unknown
        }
        
        // High confidence indicators
        let highConfidenceIndicators: Set<JailbreakIndicator> = [
            .cydiaInstalled,
            .sileoInstalled,
            .sandboxViolation,
            .suspiciousLibraries,
            .forkAllowed
        ]
        
        let hasHighConfidenceIndicator = indicators.contains { highConfidenceIndicators.contains($0) }
        
        if hasHighConfidenceIndicator || indicators.count >= 3 {
            return .high
        } else if indicators.count >= 2 {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Testable Interface

/// Protocol for mocking file system in tests
protocol FileSystemProtocol {
    func fileExists(atPath path: String) -> Bool
    func isWritableFile(atPath path: String) -> Bool
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
    func removeItem(atPath path: String) throws
}

extension FileManager: FileSystemProtocol {}

/// Testable version of JailbreakDetector
final class TestableJailbreakDetector: JailbreakDetectorProtocol {
    
    var mockIndicators: Set<JailbreakIndicator> = []
    
    func isJailbroken() -> JailbreakResult {
        let indicators = Array(mockIndicators)
        let isJailbroken = !indicators.isEmpty
        
        let confidence: DetectionConfidence
        if indicators.isEmpty {
            confidence = .unknown
        } else if indicators.count >= 3 {
            confidence = .high
        } else if indicators.count >= 2 {
            confidence = .medium
        } else {
            confidence = .low
        }
        
        return JailbreakResult(
            isJailbroken: isJailbroken,
            confidence: confidence,
            indicators: indicators
        )
    }
    
    func getJailbreakIndicators() -> [JailbreakIndicator] {
        return Array(mockIndicators)
    }
}
