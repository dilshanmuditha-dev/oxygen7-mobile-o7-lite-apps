//
//  SecurityProtocols.swift
//  Runner
//
//  iOS Binary Protection - Protocol Definitions
//

import Foundation

// MARK: - Jailbreak Detector Protocol

/// Protocol for jailbreak detection
protocol JailbreakDetectorProtocol {
    /// Performs jailbreak detection
    func isJailbroken() -> JailbreakResult
    
    /// Returns detailed jailbreak indicators found
    func getJailbreakIndicators() -> [JailbreakIndicator]
}

// MARK: - Debugger Detector Protocol

/// Protocol for debugger detection
protocol DebuggerDetectorProtocol {
    /// Checks if debugger is currently attached
    func isDebuggerAttached() -> Bool
    
    /// Performs comprehensive debugger detection
    func detectDebugger() -> DebuggerResult
    
    /// Enables anti-debugging measures
    func enableAntiDebugging()
    
    /// Whether to skip alerts in debug builds
    var skipAlertsInDebugBuild: Bool { get set }
}

// MARK: - Integrity Checker Protocol

/// Protocol for binary integrity verification
protocol IntegrityCheckerProtocol {
    /// Verifies application signature
    func verifySignature() -> Bool
    
    /// Verifies bundle identifier
    func verifyBundleIdentifier() -> Bool
    
    /// Verifies team identifier
    func verifyTeamIdentifier() -> Bool
    
    /// Performs comprehensive integrity check
    func performIntegrityCheck() -> IntegrityResult
    
    /// Configuration for expected values
    var configuration: SecurityConfiguration { get set }
}

// MARK: - Runtime Protection Protocol

/// Protocol for runtime application self-protection
protocol RuntimeProtectionProtocol {
    /// Detects Frida instrumentation framework
    func detectFrida() -> Bool
    
    /// Detects method swizzling on critical methods
    func detectSwizzling() -> Bool
    
    /// Detects code injection
    func detectCodeInjection() -> Bool
    
    /// Performs comprehensive runtime check
    func performRuntimeCheck() -> RuntimeCheckResult
}

// MARK: - Security Logger Protocol

/// Protocol for security event logging
protocol SecurityLoggerProtocol {
    /// Logs a security event
    func log(_ event: SecurityEvent)
    
    /// Gets recent security events
    func getRecentEvents(limit: Int) -> [SecurityEvent]
    
    /// Clears security logs
    func clearLogs()
    
    /// Whether verbose logging is enabled
    var verboseLoggingEnabled: Bool { get set }
}

// MARK: - Binary Protection Service Protocol

/// Protocol for the main binary protection service
protocol BinaryProtectionServiceProtocol {
    /// Performs comprehensive security assessment
    func performSecurityCheck() -> SecurityAssessment
    
    /// Starts continuous runtime monitoring
    func startRuntimeMonitoring()
    
    /// Stops runtime monitoring
    func stopRuntimeMonitoring()
    
    /// Returns current security status
    func getSecurityStatus() -> SecurityStatus
    
    /// Registers callback for security events
    func onSecurityEvent(_ callback: @escaping (SecurityEvent) -> Void)
    
    /// Updates security configuration
    func updateConfiguration(_ configuration: SecurityConfiguration)
    
    /// Current configuration
    var configuration: SecurityConfiguration { get }
}
