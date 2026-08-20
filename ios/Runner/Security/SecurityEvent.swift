//
//  SecurityEvent.swift
//  Runner
//
//  iOS Binary Protection - Security Event Model
//

import Foundation

// MARK: - Security Event Type

/// Types of security events
enum SecurityEventType: String, Codable {
    case jailbreakDetected = "jailbreak_detected"
    case debuggerDetected = "debugger_detected"
    case integrityViolation = "integrity_violation"
    case runtimeThreat = "runtime_threat"
    case securityCheckPassed = "security_check_passed"
    case securityCheckFailed = "security_check_failed"
    case monitoringStarted = "monitoring_started"
    case monitoringStopped = "monitoring_stopped"
    case configurationUpdated = "configuration_updated"
}

// MARK: - Security Severity

/// Severity levels for security events
enum SecuritySeverity: String, Codable, Comparable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case info = "info"
    
    private var sortOrder: Int {
        switch self {
        case .critical: return 5
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        case .info: return 1
        }
    }
    
    static func < (lhs: SecuritySeverity, rhs: SecuritySeverity) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Security Event

/// Represents a security event in the system
struct SecurityEvent: Codable {
    let id: String
    let type: SecurityEventType
    let severity: SecuritySeverity
    let message: String
    let details: [String: String]
    let timestamp: Date
    
    init(id: String = UUID().uuidString,
         type: SecurityEventType,
         severity: SecuritySeverity,
         message: String,
         details: [String: String] = [:],
         timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.severity = severity
        self.message = message
        self.details = details
        self.timestamp = timestamp
    }
    
    /// Converts to Flutter-compatible map
    func toFlutterMap() -> [String: Any] {
        return [
            "id": id,
            "type": type.rawValue,
            "severity": severity.rawValue,
            "message": message,
            "details": details,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    
    /// Checks if the event contains sensitive data patterns
    func containsSensitiveData() -> Bool {
        let sensitivePatterns = [
            "password", "token", "secret", "key", "credential",
            "auth", "bearer", "api_key", "apikey", "private"
        ]
        
        let allText = (message + details.values.joined(separator: " ")).lowercased()
        
        for pattern in sensitivePatterns {
            if allText.contains(pattern) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Security Event Factory

/// Factory for creating common security events
struct SecurityEventFactory {
    
    static func jailbreakDetected(indicators: [JailbreakIndicator]) -> SecurityEvent {
        return SecurityEvent(
            type: .jailbreakDetected,
            severity: .critical,
            message: "Jailbroken device detected",
            details: ["indicators": indicators.map { $0.rawValue }.joined(separator: ", ")]
        )
    }
    
    static func debuggerDetected(debuggerType: DebuggerType?) -> SecurityEvent {
        var details: [String: String] = [:]
        if let type = debuggerType {
            details["debuggerType"] = type.rawValue
        }
        return SecurityEvent(
            type: .debuggerDetected,
            severity: .high,
            message: "Debugger attachment detected",
            details: details
        )
    }
    
    static func integrityViolation(violations: [IntegrityViolation]) -> SecurityEvent {
        return SecurityEvent(
            type: .integrityViolation,
            severity: .critical,
            message: "Application integrity violation detected",
            details: ["violations": violations.map { $0.rawValue }.joined(separator: ", ")]
        )
    }
    
    static func runtimeThreat(threats: [RuntimeThreat]) -> SecurityEvent {
        return SecurityEvent(
            type: .runtimeThreat,
            severity: .critical,
            message: "Runtime security threat detected",
            details: ["threats": threats.map { $0.rawValue }.joined(separator: ", ")]
        )
    }
    
    static func securityCheckPassed() -> SecurityEvent {
        return SecurityEvent(
            type: .securityCheckPassed,
            severity: .info,
            message: "Security check completed successfully"
        )
    }
    
    static func securityCheckFailed(reason: String) -> SecurityEvent {
        return SecurityEvent(
            type: .securityCheckFailed,
            severity: .high,
            message: "Security check failed",
            details: ["reason": reason]
        )
    }
    
    static func monitoringStarted() -> SecurityEvent {
        return SecurityEvent(
            type: .monitoringStarted,
            severity: .info,
            message: "Runtime security monitoring started"
        )
    }
    
    static func monitoringStopped() -> SecurityEvent {
        return SecurityEvent(
            type: .monitoringStopped,
            severity: .info,
            message: "Runtime security monitoring stopped"
        )
    }
}
