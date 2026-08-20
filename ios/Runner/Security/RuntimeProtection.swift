//
//  RuntimeProtection.swift
//  Runner
//
//  iOS Binary Protection - Runtime Application Self-Protection Implementation
//

import Foundation
import ObjectiveC
import MachO

// MARK: - Runtime Protection

/// Implementation of runtime application self-protection (RASP)
final class RuntimeProtection: RuntimeProtectionProtocol {
    
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = RuntimeProtection()
    
    /// Logger for security events
    private let logger: SecurityLoggerProtocol
    
    /// Frida default ports to check
    private let fridaPorts: [UInt16] = [27042, 27043]
    
    /// Suspicious library patterns
    private let suspiciousLibraryPatterns: [String] = [
        "frida",
        "FridaGadget",
        "frida-agent",
        "substrate",
        "MobileSubstrate",
        "SubstrateLoader",
        "cycript",
        "libcycript",
        "cynject",
        "SSLKillSwitch",
        "snoop",
        "objection",
        "xcon"
    ]
    
    /// Critical methods to monitor for swizzling
    private var originalMethodImplementations: [String: IMP] = [:]
    
    // MARK: - Initialization
    
    init(logger: SecurityLoggerProtocol = SecurityLogger.shared) {
        self.logger = logger
        storeOriginalImplementations()
    }
    
    // MARK: - RuntimeProtectionProtocol
    
    /// Detects Frida instrumentation framework
    func detectFrida() -> Bool {
        // Check Frida ports
        for port in fridaPorts {
            if checkPortOpen(port: port) {
                return true
            }
        }
        
        // Check for Frida-related libraries
        if checkForFridaLibraries() {
            return true
        }
        
        // Check for Frida environment variables
        if checkFridaEnvironment() {
            return true
        }
        
        // Check for Frida named pipes
        if checkFridaNamedPipes() {
            return true
        }
        
        return false
    }
    
    /// Detects method swizzling on critical methods
    func detectSwizzling() -> Bool {
        return checkMethodSwizzling()
    }
    
    /// Detects code injection
    func detectCodeInjection() -> Bool {
        return checkSuspiciousLibraries() || checkDYLDEnvironment()
    }
    
    /// Performs comprehensive runtime check
    func performRuntimeCheck() -> RuntimeCheckResult {
        // On simulator, skip runtime checks as they can cause issues
        #if targetEnvironment(simulator)
        return RuntimeCheckResult(
            isSafe: true,
            fridaDetected: false,
            swizzlingDetected: false,
            injectionDetected: false,
            threats: []
        )
        #else
        
        var threats: [RuntimeThreat] = []
        
        // Check for Frida
        let fridaDetected = detectFrida()
        if fridaDetected {
            if checkPortOpen(port: 27042) {
                threats.append(.fridaServer)
            }
            if checkForFridaLibraries() {
                threats.append(.fridaGadget)
            }
        }
        
        // Check for method swizzling
        let swizzlingDetected = detectSwizzling()
        if swizzlingDetected {
            threats.append(.methodSwizzling)
        }
        
        // Check for code injection
        let injectionDetected = detectCodeInjection()
        if injectionDetected {
            if checkSuspiciousLibraries() {
                threats.append(.suspiciousLibrary)
            }
            if checkDYLDEnvironment() {
                threats.append(.codeInjection)
            }
        }
        
        // Check for hooking frameworks
        if checkForHookingFrameworks() {
            threats.append(.hookingFramework)
        }
        
        let isSafe = threats.isEmpty
        
        return RuntimeCheckResult(
            isSafe: isSafe,
            fridaDetected: fridaDetected,
            swizzlingDetected: swizzlingDetected,
            injectionDetected: injectionDetected,
            threats: threats
        )
        #endif
    }
    
    // MARK: - Frida Detection Methods
    
    /// Checks if a specific port is open using poll (more portable than select)
    private func checkPortOpen(port: UInt16) -> Bool {
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        
        defer { close(sock) }
        
        // Set socket to non-blocking
        var flags = fcntl(sock, F_GETFL, 0)
        flags |= O_NONBLOCK
        _ = fcntl(sock, F_SETFL, flags)
        
        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                connect(sock, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        if result == 0 {
            return true
        }
        
        // Check if connection is in progress using poll instead of select
        if errno == EINPROGRESS {
            var pollFd = pollfd(fd: sock, events: Int16(POLLOUT), revents: 0)
            let pollResult = poll(&pollFd, 1, 50) // 50ms timeout
            
            if pollResult > 0 && (pollFd.revents & Int16(POLLOUT)) != 0 {
                var error: Int32 = 0
                var len = socklen_t(MemoryLayout<Int32>.size)
                getsockopt(sock, SOL_SOCKET, SO_ERROR, &error, &len)
                return error == 0
            }
        }
        
        return false
    }
    
    /// Checks for Frida-related libraries
    private func checkForFridaLibraries() -> Bool {
        let fridaPatterns = ["frida", "FridaGadget", "frida-agent", "frida-gadget"]
        
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageNamePtr = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageNamePtr).lowercased()
            
            for pattern in fridaPatterns {
                if name.contains(pattern.lowercased()) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Checks for Frida environment variables
    private func checkFridaEnvironment() -> Bool {
        let fridaEnvVars = [
            "FRIDA_SCRIPT",
            "FRIDA_GADGET_CONFIG",
            "FRIDA_AGENT_PATH"
        ]
        
        for envVar in fridaEnvVars {
            if ProcessInfo.processInfo.environment[envVar] != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Checks for Frida named pipes
    private func checkFridaNamedPipes() -> Bool {
        let fridaPipes = [
            "/tmp/frida-",
            "/var/tmp/frida-"
        ]
        
        let fileManager = FileManager.default
        
        for pipePrefix in fridaPipes {
            // Check if any files starting with the prefix exist
            let directory = (pipePrefix as NSString).deletingLastPathComponent
            let prefix = (pipePrefix as NSString).lastPathComponent
            
            if let contents = try? fileManager.contentsOfDirectory(atPath: directory) {
                for item in contents {
                    if item.hasPrefix(prefix) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    // MARK: - Swizzling Detection Methods
    
    /// Stores original method implementations for later comparison
    private func storeOriginalImplementations() {
        // Store implementations of critical security methods
        let criticalSelectors: [(AnyClass, Selector)] = [
            (URLSession.self, #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)),
            (Bundle.self, #selector(getter: Bundle.bundleIdentifier))
        ]
        
        for (cls, selector) in criticalSelectors {
            if let method = class_getInstanceMethod(cls, selector) {
                let key = "\(NSStringFromClass(cls))_\(NSStringFromSelector(selector))"
                originalMethodImplementations[key] = method_getImplementation(method)
            }
        }
    }
    
    /// Checks if critical methods have been swizzled
    private func checkMethodSwizzling() -> Bool {
        for (key, originalImp) in originalMethodImplementations {
            let components = key.components(separatedBy: "_")
            guard components.count >= 2,
                  let cls = NSClassFromString(components[0]) else {
                continue
            }
            
            let selectorName = components.dropFirst().joined(separator: "_")
            let selector = NSSelectorFromString(selectorName)
            
            if let method = class_getInstanceMethod(cls, selector) {
                let currentImp = method_getImplementation(method)
                if currentImp != originalImp {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Code Injection Detection Methods
    
    /// Checks for suspicious loaded libraries
    private func checkSuspiciousLibraries() -> Bool {
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageNamePtr = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageNamePtr).lowercased()
            
            for pattern in suspiciousLibraryPatterns {
                if name.contains(pattern.lowercased()) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Checks for DYLD injection environment variables
    private func checkDYLDEnvironment() -> Bool {
        let dyldEnvVars = [
            "DYLD_INSERT_LIBRARIES",
            "DYLD_LIBRARY_PATH",
            "DYLD_FRAMEWORK_PATH"
        ]
        
        for envVar in dyldEnvVars {
            if ProcessInfo.processInfo.environment[envVar] != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Checks for hooking frameworks
    private func checkForHookingFrameworks() -> Bool {
        let hookingPatterns = [
            "substrate",
            "MobileSubstrate",
            "SubstrateLoader",
            "SubstrateInserter",
            "CydiaSubstrate",
            "libhooker",
            "Substitute"
        ]
        
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageNamePtr = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageNamePtr).lowercased()
            
            for pattern in hookingPatterns {
                if name.contains(pattern.lowercased()) {
                    return true
                }
            }
        }
        
        return false
    }
}

// MARK: - Testable Interface

/// Testable version of RuntimeProtection for unit tests
final class TestableRuntimeProtection: RuntimeProtectionProtocol {
    
    var mockFridaDetected: Bool = false
    var mockSwizzlingDetected: Bool = false
    var mockInjectionDetected: Bool = false
    var mockThreats: [RuntimeThreat] = []
    
    func detectFrida() -> Bool {
        return mockFridaDetected
    }
    
    func detectSwizzling() -> Bool {
        return mockSwizzlingDetected
    }
    
    func detectCodeInjection() -> Bool {
        return mockInjectionDetected
    }
    
    func performRuntimeCheck() -> RuntimeCheckResult {
        var threats = mockThreats
        
        if mockFridaDetected && !threats.contains(.fridaServer) && !threats.contains(.fridaGadget) {
            threats.append(.fridaServer)
        }
        if mockSwizzlingDetected && !threats.contains(.methodSwizzling) {
            threats.append(.methodSwizzling)
        }
        if mockInjectionDetected && !threats.contains(.codeInjection) && !threats.contains(.suspiciousLibrary) {
            threats.append(.codeInjection)
        }
        
        let isSafe = !mockFridaDetected && !mockSwizzlingDetected && !mockInjectionDetected && mockThreats.isEmpty
        
        return RuntimeCheckResult(
            isSafe: isSafe,
            fridaDetected: mockFridaDetected,
            swizzlingDetected: mockSwizzlingDetected,
            injectionDetected: mockInjectionDetected,
            threats: threats
        )
    }
}
