//
//  SecurityTypes.swift
//  Runner
//
//  iOS Binary Protection - Core Types and Enums
//

import Foundation

// MARK: - Security Status

/// Overall security status of the device/application
enum SecurityStatus: String, Codable {
    case secure = "secure"
    case warning = "warning"
    case compromised = "compromised"
    case unknown = "unknown"
}

// MARK: - Detection Confidence

/// Confidence level for detection results
enum DetectionConfidence: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    case unknown = "unknown"
}

// MARK: - Jailbreak Types

/// Indicators of jailbreak presence
enum JailbreakIndicator: String, CaseIterable, Codable {
    case cydiaInstalled = "cydia_installed"
    case sileoInstalled = "sileo_installed"
    case zebbraInstalled = "zebbra_installed"
    case suspiciousFiles = "suspicious_files"
    case sandboxViolation = "sandbox_violation"
    case symbolicLinks = "symbolic_links"
    case writableSystemPaths = "writable_system_paths"
    case suspiciousLibraries = "suspicious_libraries"
    case forkAllowed = "fork_allowed"
    case suspiciousURLSchemes = "suspicious_url_schemes"
}

/// Result of jailbreak detection
struct JailbreakResult: Codable {
    let isJailbroken: Bool
    let confidence: DetectionConfidence
    let indicators: [JailbreakIndicator]
    let timestamp: Date
    
    init(isJailbroken: Bool, confidence: DetectionConfidence = .unknown, indicators: [JailbreakIndicator] = [], timestamp: Date = Date()) {
        self.isJailbroken = isJailbroken
        self.confidence = confidence
        self.indicators = indicators
        self.timestamp = timestamp
    }
    
    func toMap() -> [String: Any] {
        return [
            "isJailbroken": isJailbroken,
            "confidence": confidence.rawValue,
            "indicators": indicators.map { $0.rawValue },
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
}

// MARK: - Debugger Types

/// Types of debuggers that can be detected
enum DebuggerType: String, Codable {
    case lldb = "lldb"
    case gdb = "gdb"
    case frida = "frida"
    case cycript = "cycript"
    case unknown = "unknown"
}

/// Result of debugger detection
struct DebuggerResult: Codable {
    let isDebugging: Bool
    let debuggerType: DebuggerType?
    let timestamp: Date
    
    init(isDebugging: Bool, debuggerType: DebuggerType? = nil, timestamp: Date = Date()) {
        self.isDebugging = isDebugging
        self.debuggerType = debuggerType
        self.timestamp = timestamp
    }
    
    func toMap() -> [String: Any] {
        var map: [String: Any] = [
            "isDebugging": isDebugging,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        if let debuggerType = debuggerType {
            map["debuggerType"] = debuggerType.rawValue
        }
        return map
    }
}

// MARK: - Integrity Types

/// Types of integrity violations
enum IntegrityViolation: String, Codable {
    case invalidSignature = "invalid_signature"
    case bundleIdentifierMismatch = "bundle_id_mismatch"
    case teamIdentifierMismatch = "team_id_mismatch"
    case modifiedExecutable = "modified_executable"
    case missingEntitlements = "missing_entitlements"
    case suspiciousLibraries = "suspicious_libraries"
}

/// Result of integrity verification
struct IntegrityResult: Codable {
    let isValid: Bool
    let signatureValid: Bool
    let bundleIdentifierValid: Bool
    let teamIdentifierValid: Bool
    let violations: [IntegrityViolation]
    let timestamp: Date
    
    init(isValid: Bool, signatureValid: Bool = true, bundleIdentifierValid: Bool = true, 
         teamIdentifierValid: Bool = true, violations: [IntegrityViolation] = [], timestamp: Date = Date()) {
        self.isValid = isValid
        self.signatureValid = signatureValid
        self.bundleIdentifierValid = bundleIdentifierValid
        self.teamIdentifierValid = teamIdentifierValid
        self.violations = violations
        self.timestamp = timestamp
    }
    
    func toMap() -> [String: Any] {
        return [
            "isValid": isValid,
            "signatureValid": signatureValid,
            "bundleIdentifierValid": bundleIdentifierValid,
            "teamIdentifierValid": teamIdentifierValid,
            "violations": violations.map { $0.rawValue },
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
}

// MARK: - Runtime Protection Types

/// Types of runtime threats
enum RuntimeThreat: String, Codable {
    case fridaServer = "frida_server"
    case fridaGadget = "frida_gadget"
    case methodSwizzling = "method_swizzling"
    case codeInjection = "code_injection"
    case suspiciousLibrary = "suspicious_library"
    case hookingFramework = "hooking_framework"
}

/// Result of runtime protection check
struct RuntimeCheckResult: Codable {
    let isSafe: Bool
    let fridaDetected: Bool
    let swizzlingDetected: Bool
    let injectionDetected: Bool
    let threats: [RuntimeThreat]
    let timestamp: Date
    
    init(isSafe: Bool, fridaDetected: Bool = false, swizzlingDetected: Bool = false,
         injectionDetected: Bool = false, threats: [RuntimeThreat] = [], timestamp: Date = Date()) {
        self.isSafe = isSafe
        self.fridaDetected = fridaDetected
        self.swizzlingDetected = swizzlingDetected
        self.injectionDetected = injectionDetected
        self.threats = threats
        self.timestamp = timestamp
    }
    
    func toMap() -> [String: Any] {
        return [
            "isSafe": isSafe,
            "fridaDetected": fridaDetected,
            "swizzlingDetected": swizzlingDetected,
            "injectionDetected": injectionDetected,
            "threats": threats.map { $0.rawValue },
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
}

// MARK: - Security Assessment

/// Comprehensive security assessment result
struct SecurityAssessment: Codable {
    let overallStatus: SecurityStatus
    let jailbreakResult: JailbreakResult
    let debuggerResult: DebuggerResult
    let integrityResult: IntegrityResult
    let runtimeResult: RuntimeCheckResult
    let timestamp: Date
    let assessmentId: String
    
    var isSecure: Bool {
        return overallStatus == .secure
    }
    
    init(overallStatus: SecurityStatus, jailbreakResult: JailbreakResult, debuggerResult: DebuggerResult,
         integrityResult: IntegrityResult, runtimeResult: RuntimeCheckResult, 
         timestamp: Date = Date(), assessmentId: String = UUID().uuidString) {
        self.overallStatus = overallStatus
        self.jailbreakResult = jailbreakResult
        self.debuggerResult = debuggerResult
        self.integrityResult = integrityResult
        self.runtimeResult = runtimeResult
        self.timestamp = timestamp
        self.assessmentId = assessmentId
    }
    
    func toFlutterMap() -> [String: Any] {
        return [
            "overallStatus": overallStatus.rawValue,
            "isJailbroken": jailbreakResult.isJailbroken,
            "isDebugging": debuggerResult.isDebugging,
            "integrityValid": integrityResult.isValid,
            "runtimeSafe": runtimeResult.isSafe,
            "timestamp": timestamp.timeIntervalSince1970,
            "assessmentId": assessmentId,
            "jailbreakResult": jailbreakResult.toMap(),
            "debuggerResult": debuggerResult.toMap(),
            "integrityResult": integrityResult.toMap(),
            "runtimeResult": runtimeResult.toMap()
        ]
    }
}

// MARK: - Security Configuration

/// Configuration for security checks
struct SecurityConfiguration {
    let jailbreakDetectionEnabled: Bool
    let debuggerDetectionEnabled: Bool
    let integrityCheckEnabled: Bool
    let runtimeProtectionEnabled: Bool
    let monitoringInterval: TimeInterval
    let allowJailbrokenDevices: Bool
    let expectedBundleIdentifier: String
    let expectedTeamIdentifier: String
    
    static let `default` = SecurityConfiguration(
        jailbreakDetectionEnabled: true,
        debuggerDetectionEnabled: true,
        integrityCheckEnabled: true,
        runtimeProtectionEnabled: true,
        monitoringInterval: 30.0,
        allowJailbrokenDevices: false,
        expectedBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.oxpay.o7lite",
        expectedTeamIdentifier: ""
    )
    
    init(jailbreakDetectionEnabled: Bool = true,
         debuggerDetectionEnabled: Bool = true,
         integrityCheckEnabled: Bool = true,
         runtimeProtectionEnabled: Bool = true,
         monitoringInterval: TimeInterval = 30.0,
         allowJailbrokenDevices: Bool = false,
         expectedBundleIdentifier: String = "",
         expectedTeamIdentifier: String = "") {
        self.jailbreakDetectionEnabled = jailbreakDetectionEnabled
        self.debuggerDetectionEnabled = debuggerDetectionEnabled
        self.integrityCheckEnabled = integrityCheckEnabled
        self.runtimeProtectionEnabled = runtimeProtectionEnabled
        self.monitoringInterval = monitoringInterval
        self.allowJailbrokenDevices = allowJailbrokenDevices
        self.expectedBundleIdentifier = expectedBundleIdentifier.isEmpty ? 
            (Bundle.main.bundleIdentifier ?? "com.oxpay.o7lite") : expectedBundleIdentifier
        self.expectedTeamIdentifier = expectedTeamIdentifier
    }
}
