//
//  BinaryProtectionService.swift
//  Runner
//
//  iOS Binary Protection - Main Protection Service Implementation
//

import Foundation

// MARK: - Binary Protection Service

/// Central service coordinating all binary protection mechanisms
final class BinaryProtectionService: BinaryProtectionServiceProtocol {
    
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = BinaryProtectionService()
    
    /// Current configuration
    private(set) var configuration: SecurityConfiguration
    
    /// Jailbreak detector
    private let jailbreakDetector: JailbreakDetectorProtocol
    
    /// Debugger detector
    private let debuggerDetector: DebuggerDetectorProtocol
    
    /// Integrity checker
    private let integrityChecker: IntegrityCheckerProtocol
    
    /// Runtime protection
    private let runtimeProtection: RuntimeProtectionProtocol
    
    /// Security logger
    private let logger: SecurityLoggerProtocol
    
    /// Event callbacks
    private var eventCallbacks: [(SecurityEvent) -> Void] = []
    
    /// Monitoring timer
    private var monitoringTimer: Timer?
    
    /// Whether monitoring is active
    private(set) var isMonitoring: Bool = false
    
    /// Last security assessment
    private(set) var lastAssessment: SecurityAssessment?
    
    // MARK: - Initialization
    
    init(configuration: SecurityConfiguration = .default,
         jailbreakDetector: JailbreakDetectorProtocol = JailbreakDetector.shared,
         debuggerDetector: DebuggerDetectorProtocol = DebuggerDetector.shared,
         integrityChecker: IntegrityCheckerProtocol = IntegrityChecker.shared,
         runtimeProtection: RuntimeProtectionProtocol = RuntimeProtection.shared,
         logger: SecurityLoggerProtocol = SecurityLogger.shared) {
        self.configuration = configuration
        self.jailbreakDetector = jailbreakDetector
        self.debuggerDetector = debuggerDetector
        self.integrityChecker = integrityChecker
        self.runtimeProtection = runtimeProtection
        self.logger = logger
    }
    
    // MARK: - BinaryProtectionServiceProtocol
    
    /// Performs comprehensive security assessment
    func performSecurityCheck() -> SecurityAssessment {
        var jailbreakResult: JailbreakResult
        var debuggerResult: DebuggerResult
        var integrityResult: IntegrityResult
        var runtimeResult: RuntimeCheckResult
        
        // Perform jailbreak detection with error handling
        if configuration.jailbreakDetectionEnabled {
            do {
                jailbreakResult = try performJailbreakCheck()
            } catch {
                jailbreakResult = JailbreakResult(isJailbroken: true, confidence: .unknown, indicators: [])
                logError("Jailbreak detection failed", error: error)
            }
        } else {
            jailbreakResult = JailbreakResult(isJailbroken: false)
        }
        
        // Perform debugger detection with error handling
        if configuration.debuggerDetectionEnabled {
            do {
                debuggerResult = try performDebuggerCheck()
            } catch {
                debuggerResult = DebuggerResult(isDebugging: true, debuggerType: .unknown)
                logError("Debugger detection failed", error: error)
            }
        } else {
            debuggerResult = DebuggerResult(isDebugging: false)
        }
        
        // Perform integrity check with error handling
        if configuration.integrityCheckEnabled {
            do {
                integrityResult = try performIntegrityCheck()
            } catch {
                integrityResult = IntegrityResult(isValid: false, violations: [.invalidSignature])
                logError("Integrity check failed", error: error)
            }
        } else {
            integrityResult = IntegrityResult(isValid: true)
        }
        
        // Perform runtime protection check with error handling
        if configuration.runtimeProtectionEnabled {
            do {
                runtimeResult = try performRuntimeCheck()
            } catch {
                runtimeResult = RuntimeCheckResult(isSafe: false, threats: [.codeInjection])
                logError("Runtime check failed", error: error)
            }
        } else {
            runtimeResult = RuntimeCheckResult(isSafe: true)
        }
        
        // Calculate overall status
        let overallStatus = calculateOverallStatus(
            jailbreakResult: jailbreakResult,
            debuggerResult: debuggerResult,
            integrityResult: integrityResult,
            runtimeResult: runtimeResult
        )
        
        let assessment = SecurityAssessment(
            overallStatus: overallStatus,
            jailbreakResult: jailbreakResult,
            debuggerResult: debuggerResult,
            integrityResult: integrityResult,
            runtimeResult: runtimeResult
        )
        
        lastAssessment = assessment
        
        // Log and notify based on results
        logAndNotifyAssessment(assessment)
        
        return assessment
    }
    
    /// Starts continuous runtime monitoring
    func startRuntimeMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        let event = SecurityEventFactory.monitoringStarted()
        logger.log(event)
        notifyCallbacks(event)
        
        // Schedule periodic checks on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.monitoringTimer = Timer.scheduledTimer(
                withTimeInterval: self.configuration.monitoringInterval,
                repeats: true
            ) { [weak self] _ in
                self?.performPeriodicCheck()
            }
        }
        
        // Run initial check on background thread to avoid blocking
        DispatchQueue.global(qos: .utility).async { [weak self] in
            _ = self?.performSecurityCheck()
        }
    }
    
    /// Stops runtime monitoring
    func stopRuntimeMonitoring() {
        guard isMonitoring else { return }
        
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
        
        let event = SecurityEventFactory.monitoringStopped()
        logger.log(event)
        notifyCallbacks(event)
    }
    
    /// Returns current security status
    func getSecurityStatus() -> SecurityStatus {
        return lastAssessment?.overallStatus ?? .unknown
    }
    
    /// Registers callback for security events
    func onSecurityEvent(_ callback: @escaping (SecurityEvent) -> Void) {
        eventCallbacks.append(callback)
    }
    
    /// Updates security configuration
    func updateConfiguration(_ newConfiguration: SecurityConfiguration) {
        configuration = newConfiguration
        
        // Update integrity checker configuration
        if var checker = integrityChecker as? IntegrityChecker {
            checker.configuration = newConfiguration
        }
        
        // Update debugger detector settings
        if var detector = debuggerDetector as? DebuggerDetector {
            detector.skipAlertsInDebugBuild = true
        }
        
        // Restart monitoring if active with new interval
        if isMonitoring {
            stopRuntimeMonitoring()
            startRuntimeMonitoring()
        }
        
        let event = SecurityEvent(
            type: .configurationUpdated,
            severity: .info,
            message: "Security configuration updated"
        )
        logger.log(event)
        notifyCallbacks(event)
    }
    
    // MARK: - Private Methods
    
    /// Performs jailbreak check with error handling
    private func performJailbreakCheck() throws -> JailbreakResult {
        return jailbreakDetector.isJailbroken()
    }
    
    /// Performs debugger check with error handling
    private func performDebuggerCheck() throws -> DebuggerResult {
        return debuggerDetector.detectDebugger()
    }
    
    /// Performs integrity check with error handling
    private func performIntegrityCheck() throws -> IntegrityResult {
        return integrityChecker.performIntegrityCheck()
    }
    
    /// Performs runtime check with error handling
    private func performRuntimeCheck() throws -> RuntimeCheckResult {
        return runtimeProtection.performRuntimeCheck()
    }
    
    /// Calculates overall security status from individual results
    private func calculateOverallStatus(
        jailbreakResult: JailbreakResult,
        debuggerResult: DebuggerResult,
        integrityResult: IntegrityResult,
        runtimeResult: RuntimeCheckResult
    ) -> SecurityStatus {
        // Critical issues result in compromised status
        if !integrityResult.isValid {
            return .compromised
        }
        
        if !runtimeResult.isSafe {
            return .compromised
        }
        
        // Jailbreak with high confidence is compromised
        if jailbreakResult.isJailbroken && jailbreakResult.confidence == .high {
            return configuration.allowJailbrokenDevices ? .warning : .compromised
        }
        
        // Debugger in release mode is compromised
        #if !DEBUG
        if debuggerResult.isDebugging {
            return .compromised
        }
        #endif
        
        // Jailbreak with lower confidence is warning
        if jailbreakResult.isJailbroken {
            return configuration.allowJailbrokenDevices ? .warning : .compromised
        }
        
        return .secure
    }
    
    /// Logs and notifies about assessment results
    private func logAndNotifyAssessment(_ assessment: SecurityAssessment) {
        // Log jailbreak detection
        if assessment.jailbreakResult.isJailbroken {
            let event = SecurityEventFactory.jailbreakDetected(
                indicators: assessment.jailbreakResult.indicators
            )
            logger.log(event)
            notifyCallbacks(event)
        }
        
        // Log debugger detection
        if assessment.debuggerResult.isDebugging {
            let event = SecurityEventFactory.debuggerDetected(
                debuggerType: assessment.debuggerResult.debuggerType
            )
            logger.log(event)
            notifyCallbacks(event)
        }
        
        // Log integrity violations
        if !assessment.integrityResult.isValid {
            let event = SecurityEventFactory.integrityViolation(
                violations: assessment.integrityResult.violations
            )
            logger.log(event)
            notifyCallbacks(event)
        }
        
        // Log runtime threats
        if !assessment.runtimeResult.isSafe {
            let event = SecurityEventFactory.runtimeThreat(
                threats: assessment.runtimeResult.threats
            )
            logger.log(event)
            notifyCallbacks(event)
        }
        
        // Log overall result
        if assessment.isSecure {
            let event = SecurityEventFactory.securityCheckPassed()
            logger.log(event)
            notifyCallbacks(event)
        } else {
            let event = SecurityEventFactory.securityCheckFailed(
                reason: "Security assessment failed: \(assessment.overallStatus.rawValue)"
            )
            logger.log(event)
            notifyCallbacks(event)
        }
    }
    
    /// Performs periodic security check during monitoring
    private func performPeriodicCheck() {
        let assessment = performSecurityCheck()
        
        // Compare with last assessment and notify if status changed
        if let last = lastAssessment, last.overallStatus != assessment.overallStatus {
            let event = SecurityEvent(
                type: .securityCheckFailed,
                severity: .high,
                message: "Security status changed from \(last.overallStatus.rawValue) to \(assessment.overallStatus.rawValue)"
            )
            logger.log(event)
            notifyCallbacks(event)
        }
    }
    
    /// Logs an error
    private func logError(_ message: String, error: Error) {
        let event = SecurityEvent(
            type: .securityCheckFailed,
            severity: .high,
            message: message,
            details: ["error": error.localizedDescription]
        )
        logger.log(event)
        notifyCallbacks(event)
    }
    
    /// Notifies all registered callbacks
    private func notifyCallbacks(_ event: SecurityEvent) {
        for callback in eventCallbacks {
            callback(event)
        }
    }
}

// MARK: - Testable Interface

/// Testable version of BinaryProtectionService for unit tests
final class TestableBinaryProtectionService: BinaryProtectionServiceProtocol {
    
    var configuration: SecurityConfiguration
    var mockJailbreakResult: JailbreakResult?
    var mockDebuggerResult: DebuggerResult?
    var mockIntegrityResult: IntegrityResult?
    var mockRuntimeResult: RuntimeCheckResult?
    var mockOverallStatus: SecurityStatus = .secure
    var shouldThrowError: Bool = false
    
    private var eventCallbacks: [(SecurityEvent) -> Void] = []
    private(set) var isMonitoring: Bool = false
    private(set) var lastAssessment: SecurityAssessment?
    
    init(configuration: SecurityConfiguration = .default) {
        self.configuration = configuration
    }
    
    func performSecurityCheck() -> SecurityAssessment {
        let jailbreakResult = mockJailbreakResult ?? JailbreakResult(isJailbroken: false)
        let debuggerResult = mockDebuggerResult ?? DebuggerResult(isDebugging: false)
        let integrityResult = mockIntegrityResult ?? IntegrityResult(isValid: true)
        let runtimeResult = mockRuntimeResult ?? RuntimeCheckResult(isSafe: true)
        
        let status: SecurityStatus
        if shouldThrowError {
            status = .compromised
        } else {
            status = mockOverallStatus
        }
        
        let assessment = SecurityAssessment(
            overallStatus: status,
            jailbreakResult: jailbreakResult,
            debuggerResult: debuggerResult,
            integrityResult: integrityResult,
            runtimeResult: runtimeResult
        )
        
        lastAssessment = assessment
        
        // Notify callbacks
        if jailbreakResult.isJailbroken {
            let event = SecurityEventFactory.jailbreakDetected(indicators: jailbreakResult.indicators)
            notifyCallbacks(event)
        }
        if debuggerResult.isDebugging {
            let event = SecurityEventFactory.debuggerDetected(debuggerType: debuggerResult.debuggerType)
            notifyCallbacks(event)
        }
        if !integrityResult.isValid {
            let event = SecurityEventFactory.integrityViolation(violations: integrityResult.violations)
            notifyCallbacks(event)
        }
        if !runtimeResult.isSafe {
            let event = SecurityEventFactory.runtimeThreat(threats: runtimeResult.threats)
            notifyCallbacks(event)
        }
        
        return assessment
    }
    
    func startRuntimeMonitoring() {
        isMonitoring = true
        let event = SecurityEventFactory.monitoringStarted()
        notifyCallbacks(event)
    }
    
    func stopRuntimeMonitoring() {
        isMonitoring = false
        let event = SecurityEventFactory.monitoringStopped()
        notifyCallbacks(event)
    }
    
    func getSecurityStatus() -> SecurityStatus {
        return lastAssessment?.overallStatus ?? mockOverallStatus
    }
    
    func onSecurityEvent(_ callback: @escaping (SecurityEvent) -> Void) {
        eventCallbacks.append(callback)
    }
    
    func updateConfiguration(_ newConfiguration: SecurityConfiguration) {
        configuration = newConfiguration
    }
    
    private func notifyCallbacks(_ event: SecurityEvent) {
        for callback in eventCallbacks {
            callback(event)
        }
    }
}
