//
//  SecurityLogger.swift
//  Runner
//
//  iOS Binary Protection - Security Logger Implementation
//

import Foundation
import os.log

// MARK: - Security Logger

/// Implementation of security event logging
final class SecurityLogger: SecurityLoggerProtocol {
    
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = SecurityLogger()
    
    /// Whether verbose logging is enabled (disabled in release by default)
    var verboseLoggingEnabled: Bool
    
    /// Maximum number of events to store in memory
    private let maxStoredEvents: Int = 100
    
    /// In-memory event storage
    private var events: [SecurityEvent] = []
    
    /// Thread-safe queue for event operations
    private let queue = DispatchQueue(label: "com.oxpay.o7lite.security.logger", attributes: .concurrent)
    
    /// OS Log for system logging
    private let osLog: OSLog
    
    /// Patterns that indicate sensitive data
    private let sensitivePatterns: [String] = [
        "password", "passwd", "pwd",
        "token", "access_token", "refresh_token",
        "secret", "api_secret",
        "key", "api_key", "apikey", "private_key",
        "credential", "credentials",
        "auth", "authorization", "bearer",
        "ssn", "social_security",
        "credit_card", "card_number", "cvv", "cvc",
        "pin", "otp"
    ]
    
    // MARK: - Initialization
    
    init(verboseLoggingEnabled: Bool? = nil) {
        #if DEBUG
        self.verboseLoggingEnabled = verboseLoggingEnabled ?? true
        #else
        self.verboseLoggingEnabled = verboseLoggingEnabled ?? false
        #endif
        
        self.osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.oxpay.o7lite",
                          category: "Security")
    }
    
    // MARK: - SecurityLoggerProtocol
    
    /// Logs a security event
    func log(_ event: SecurityEvent) {
        // Sanitize the event before logging
        let sanitizedEvent = sanitizeEvent(event)
        
        // Store event in memory
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.events.append(sanitizedEvent)
            
            // Trim old events if exceeding max
            if self.events.count > self.maxStoredEvents {
                self.events.removeFirst(self.events.count - self.maxStoredEvents)
            }
        }
        
        // Log to system based on severity and build configuration
        logToSystem(sanitizedEvent)
    }
    
    /// Gets recent security events
    func getRecentEvents(limit: Int) -> [SecurityEvent] {
        var result: [SecurityEvent] = []
        
        queue.sync {
            let startIndex = max(0, events.count - limit)
            result = Array(events[startIndex...])
        }
        
        return result
    }
    
    /// Clears all stored security logs
    func clearLogs() {
        queue.async(flags: .barrier) { [weak self] in
            self?.events.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    /// Sanitizes an event to remove sensitive data
    private func sanitizeEvent(_ event: SecurityEvent) -> SecurityEvent {
        var sanitizedDetails: [String: String] = [:]
        
        for (key, value) in event.details {
            sanitizedDetails[key] = sanitizeString(value)
        }
        
        let sanitizedMessage = sanitizeString(event.message)
        
        return SecurityEvent(
            id: event.id,
            type: event.type,
            severity: event.severity,
            message: sanitizedMessage,
            details: sanitizedDetails,
            timestamp: event.timestamp
        )
    }
    
    /// Sanitizes a string by redacting sensitive patterns
    private func sanitizeString(_ input: String) -> String {
        var result = input
        let lowercased = input.lowercased()
        
        for pattern in sensitivePatterns {
            if lowercased.contains(pattern) {
                // Find and redact the sensitive value
                // This is a simple approach - in production, use regex for better matching
                result = redactSensitiveValue(in: result, pattern: pattern)
            }
        }
        
        return result
    }
    
    /// Redacts sensitive values in a string
    private func redactSensitiveValue(in input: String, pattern: String) -> String {
        // Simple redaction: replace value after pattern with [REDACTED]
        let patterns = [
            "\(pattern)=",
            "\(pattern):",
            "\(pattern) ",
            "\"\(pattern)\":"
        ]
        
        var result = input
        
        for p in patterns {
            if let range = result.lowercased().range(of: p) {
                let afterPattern = result.index(range.upperBound, offsetBy: 0)
                let remaining = String(result[afterPattern...])
                
                // Find the end of the value (space, comma, quote, or end of string)
                if let endIndex = remaining.firstIndex(where: { $0 == " " || $0 == "," || $0 == "\"" || $0 == "'" || $0 == "}" }) {
                    let valueRange = afterPattern..<result.index(afterPattern, offsetBy: remaining.distance(from: remaining.startIndex, to: endIndex))
                    result.replaceSubrange(valueRange, with: "[REDACTED]")
                }
            }
        }
        
        return result
    }
    
    /// Logs event to system log based on severity
    private func logToSystem(_ event: SecurityEvent) {
        // In release mode, only log high severity events
        #if !DEBUG
        guard event.severity >= .medium else { return }
        #endif
        
        // Skip verbose logging if disabled
        if !verboseLoggingEnabled && event.severity == .info {
            return
        }
        
        let logType: OSLogType
        switch event.severity {
        case .critical:
            logType = .fault
        case .high:
            logType = .error
        case .medium:
            logType = .default
        case .low:
            logType = .info
        case .info:
            logType = .debug
        }
        
        // Format the log message
        let logMessage = formatLogMessage(event)
        
        os_log("%{public}@", log: osLog, type: logType, logMessage)
    }
    
    /// Formats an event into a log message string
    private func formatLogMessage(_ event: SecurityEvent) -> String {
        var message = "[\(event.severity.rawValue.uppercased())] \(event.type.rawValue): \(event.message)"
        
        if verboseLoggingEnabled && !event.details.isEmpty {
            let detailsString = event.details.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            message += " | Details: \(detailsString)"
        }
        
        return message
    }
    
    // MARK: - Utility Methods
    
    /// Checks if a string contains sensitive data patterns
    func containsSensitiveData(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return sensitivePatterns.contains { lowercased.contains($0) }
    }
    
    /// Returns the current log level based on build configuration
    var currentLogLevel: SecuritySeverity {
        #if DEBUG
        return .info
        #else
        return verboseLoggingEnabled ? .low : .medium
        #endif
    }
    
    /// Checks if an event would be logged given current configuration
    func wouldLog(_ event: SecurityEvent) -> Bool {
        #if DEBUG
        return true
        #else
        if !verboseLoggingEnabled && event.severity == .info {
            return false
        }
        return event.severity >= .medium
        #endif
    }
}

// MARK: - Build Configuration Helper

/// Helper to detect build configuration at runtime
struct BuildConfiguration {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isRelease: Bool {
        return !isDebug
    }
}
