//
//  SecurityMethodChannel.swift
//  Runner
//
//  iOS Binary Protection - Flutter Method Channel Handler
//

import Foundation
import Flutter

// MARK: - Security Method Channel

/// Handles Flutter method channel communication for security features
final class SecurityMethodChannel {
    
    // MARK: - Constants
    
    /// Channel name for security communication
    static let channelName = "CHANNEL_IOS_SECURITY"
    
    /// Method names
    enum Method: String {
        case getSecurityStatus = "getSecurityStatus"
        case performSecurityCheck = "performSecurityCheck"
        case startMonitoring = "startMonitoring"
        case stopMonitoring = "stopMonitoring"
        case getSecurityEvents = "getSecurityEvents"
        case setConfiguration = "setConfiguration"
        case isMonitoring = "isMonitoring"
    }
    
    // MARK: - Properties
    
    /// The Flutter method channel
    private let channel: FlutterMethodChannel
    
    /// The binary protection service
    private let protectionService: BinaryProtectionServiceProtocol
    
    /// The security logger
    private let logger: SecurityLoggerProtocol
    
    // MARK: - Initialization
    
    init(binaryMessenger: FlutterBinaryMessenger,
         protectionService: BinaryProtectionServiceProtocol = BinaryProtectionService.shared,
         logger: SecurityLoggerProtocol = SecurityLogger.shared) {
        self.channel = FlutterMethodChannel(
            name: SecurityMethodChannel.channelName,
            binaryMessenger: binaryMessenger
        )
        self.protectionService = protectionService
        self.logger = logger
        
        setupMethodCallHandler()
        setupEventForwarding()
    }
    
    // MARK: - Setup
    
    /// Sets up the method call handler
    private func setupMethodCallHandler() {
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handleMethodCall(call, result: result)
        }
    }
    
    /// Sets up event forwarding to Flutter
    private func setupEventForwarding() {
        protectionService.onSecurityEvent { [weak self] event in
            self?.sendEventToFlutter(event)
        }
    }
    
    // MARK: - Method Call Handling
    
    /// Handles incoming method calls from Flutter
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = Method(rawValue: call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        switch method {
        case .getSecurityStatus:
            handleGetSecurityStatus(result: result)
            
        case .performSecurityCheck:
            handlePerformSecurityCheck(result: result)
            
        case .startMonitoring:
            handleStartMonitoring(result: result)
            
        case .stopMonitoring:
            handleStopMonitoring(result: result)
            
        case .getSecurityEvents:
            handleGetSecurityEvents(call: call, result: result)
            
        case .setConfiguration:
            handleSetConfiguration(call: call, result: result)
            
        case .isMonitoring:
            handleIsMonitoring(result: result)
        }
    }
    
    // MARK: - Method Handlers
    
    /// Handles getSecurityStatus method
    private func handleGetSecurityStatus(result: @escaping FlutterResult) {
        do {
            let status = protectionService.getSecurityStatus()
            result(status.rawValue)
        } catch {
            result(FlutterError(
                code: "SECURITY_ERROR",
                message: "Failed to get security status",
                details: error.localizedDescription
            ))
        }
    }
    
    /// Handles performSecurityCheck method
    private func handlePerformSecurityCheck(result: @escaping FlutterResult) {
        // Perform check on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "SECURITY_ERROR",
                        message: "Service unavailable",
                        details: nil
                    ))
                }
                return
            }
            
            let assessment = self.protectionService.performSecurityCheck()
            
            DispatchQueue.main.async {
                result(assessment.toFlutterMap())
            }
        }
    }
    
    /// Handles startMonitoring method
    private func handleStartMonitoring(result: @escaping FlutterResult) {
        protectionService.startRuntimeMonitoring()
        result(true)
    }
    
    /// Handles stopMonitoring method
    private func handleStopMonitoring(result: @escaping FlutterResult) {
        protectionService.stopRuntimeMonitoring()
        result(true)
    }
    
    /// Handles getSecurityEvents method
    private func handleGetSecurityEvents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let limit: Int
        if let args = call.arguments as? [String: Any],
           let limitArg = args["limit"] as? Int {
            limit = limitArg
        } else {
            limit = 50
        }
        
        let events = logger.getRecentEvents(limit: limit)
        let eventMaps = events.map { $0.toFlutterMap() }
        result(eventMaps)
    }
    
    /// Handles setConfiguration method
    private func handleSetConfiguration(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Configuration arguments required",
                details: nil
            ))
            return
        }
        
        let configuration = SecurityConfiguration(
            jailbreakDetectionEnabled: args["jailbreakDetectionEnabled"] as? Bool ?? true,
            debuggerDetectionEnabled: args["debuggerDetectionEnabled"] as? Bool ?? true,
            integrityCheckEnabled: args["integrityCheckEnabled"] as? Bool ?? true,
            runtimeProtectionEnabled: args["runtimeProtectionEnabled"] as? Bool ?? true,
            monitoringInterval: args["monitoringInterval"] as? TimeInterval ?? 30.0,
            allowJailbrokenDevices: args["allowJailbrokenDevices"] as? Bool ?? false,
            expectedBundleIdentifier: args["expectedBundleIdentifier"] as? String ?? "",
            expectedTeamIdentifier: args["expectedTeamIdentifier"] as? String ?? ""
        )
        
        protectionService.updateConfiguration(configuration)
        result(true)
    }
    
    /// Handles isMonitoring method
    private func handleIsMonitoring(result: @escaping FlutterResult) {
        if let service = protectionService as? BinaryProtectionService {
            result(service.isMonitoring)
        } else if let testService = protectionService as? TestableBinaryProtectionService {
            result(testService.isMonitoring)
        } else {
            result(false)
        }
    }
    
    // MARK: - Event Sending
    
    /// Sends a security event to Flutter
    private func sendEventToFlutter(_ event: SecurityEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("onSecurityEvent", arguments: event.toFlutterMap())
        }
    }
    
    /// Sends a security status change to Flutter
    func sendStatusChangeToFlutter(_ status: SecurityStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("onSecurityStatusChanged", arguments: status.rawValue)
        }
    }
}

// MARK: - AppDelegate Extension

extension AppDelegate {
    
    /// Sets up the security method channel
    func setupSecurityChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        
        // Create and store the security channel
        let securityChannel = SecurityMethodChannel(
            binaryMessenger: controller.binaryMessenger
        )
        
        // Store reference to prevent deallocation
        objc_setAssociatedObject(
            self,
            "securityChannel",
            securityChannel,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // Start runtime monitoring
        BinaryProtectionService.shared.startRuntimeMonitoring()
    }
}
