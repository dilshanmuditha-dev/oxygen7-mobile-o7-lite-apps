//
//  DebuggerDetector.swift
//  Runner
//
//  iOS Binary Protection - Debugger Detection Implementation
//

import Foundation
import MachO

// MARK: - Debugger Detector

/// Implementation of debugger detection for iOS applications
final class DebuggerDetector: DebuggerDetectorProtocol {
    
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = DebuggerDetector()
    
    /// Whether to skip alerts in debug builds
    var skipAlertsInDebugBuild: Bool = true
    
    /// Logger for security events
    private let logger: SecurityLoggerProtocol
    
    /// Frida default port
    private let fridaDefaultPort: UInt16 = 27042
    
    /// Known debugger process names
    private let debuggerProcessNames: [String] = [
        "lldb",
        "gdb",
        "debugserver",
        "frida-server",
        "cycript"
    ]
    
    // MARK: - Initialization
    
    init(logger: SecurityLoggerProtocol = SecurityLogger.shared) {
        self.logger = logger
    }
    
    // MARK: - DebuggerDetectorProtocol
    
    /// Checks if debugger is currently attached
    func isDebuggerAttached() -> Bool {
        // Skip in debug builds if configured
        #if DEBUG
        if skipAlertsInDebugBuild {
            return false
        }
        #endif
        
        return checkSysctlDebugger()
    }
    
    /// Performs comprehensive debugger detection
    func detectDebugger() -> DebuggerResult {
        // Skip on simulator as checks don't apply properly
        #if targetEnvironment(simulator)
        return DebuggerResult(isDebugging: false, debuggerType: nil)
        #endif
        
        // Skip in debug builds if configured
        #if DEBUG
        if skipAlertsInDebugBuild {
            return DebuggerResult(isDebugging: false, debuggerType: nil)
        }
        #endif
        
        var debuggerType: DebuggerType? = nil
        var isDebugging = false
        
        // Check using sysctl
        if checkSysctlDebugger() {
            isDebugging = true
            debuggerType = .lldb // Most common on iOS
        }
        
        // Check for Frida
        if checkForFrida() {
            isDebugging = true
            debuggerType = .frida
        }
        
        // Check for Cycript
        if checkForCycript() {
            isDebugging = true
            debuggerType = .cycript
        }
        
        // Check environment variables
        if checkDebugEnvironment() {
            isDebugging = true
            if debuggerType == nil {
                debuggerType = .unknown
            }
        }
        
        return DebuggerResult(
            isDebugging: isDebugging,
            debuggerType: debuggerType
        )
    }
    
    /// Enables anti-debugging measures
    func enableAntiDebugging() {
        #if !DEBUG
        // Deny ptrace attachment using inline assembly or dlsym
        denyPtraceAttachment()
        #endif
    }
    
    // MARK: - Detection Methods
    
    /// Checks for debugger using sysctl
    private func checkSysctlDebugger() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        if result != 0 {
            // sysctl failed - treat as potentially compromised
            return true
        }
        
        // Check P_TRACED flag
        let isTraced = (info.kp_proc.p_flag & P_TRACED) != 0
        return isTraced
    }
    
    /// Denies ptrace attachment (anti-debugging measure)
    private func denyPtraceAttachment() {
        // PT_DENY_ATTACH = 31
        // Use dlsym to get ptrace function pointer
        typealias PtraceType = @convention(c) (CInt, pid_t, UnsafeMutableRawPointer?, CInt) -> CInt
        
        guard let handle = dlopen(nil, RTLD_NOW) else { return }
        defer { dlclose(handle) }
        
        guard let sym = dlsym(handle, "ptrace") else { return }
        
        let ptrace = unsafeBitCast(sym, to: PtraceType.self)
        let PT_DENY_ATTACH: CInt = 31
        _ = ptrace(PT_DENY_ATTACH, 0, nil, 0)
    }
    
    /// Checks for Frida instrumentation framework
    private func checkForFrida() -> Bool {
        // Check for Frida server port
        if checkPortOpen(port: fridaDefaultPort) {
            return true
        }
        
        // Check for Frida-related libraries
        let fridaLibraries = [
            "FridaGadget",
            "frida-agent",
            "frida-gadget"
        ]
        
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageNamePtr = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageNamePtr).lowercased()
            
            for fridaLib in fridaLibraries {
                if name.contains(fridaLib.lowercased()) {
                    return true
                }
            }
        }
        
        // Check for Frida-related environment variables
        let fridaEnvVars = ["FRIDA_SCRIPT", "FRIDA_GADGET_CONFIG"]
        for envVar in fridaEnvVars {
            if ProcessInfo.processInfo.environment[envVar] != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Checks for Cycript
    private func checkForCycript() -> Bool {
        // Check for Cycript library
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageNamePtr = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageNamePtr).lowercased()
            
            if name.contains("cycript") || name.contains("libcycript") {
                return true
            }
        }
        
        return false
    }
    
    /// Checks for debug-related environment variables
    private func checkDebugEnvironment() -> Bool {
        let debugEnvVars = [
            "DYLD_INSERT_LIBRARIES",
            "DYLD_LIBRARY_PATH",
            "_MSSafeMode",
            "LLDB_DEBUGSERVER_PATH"
        ]
        
        for envVar in debugEnvVars {
            if ProcessInfo.processInfo.environment[envVar] != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Checks if a specific port is open (for Frida detection)
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
            return true // Port is open
        }
        
        // Check if connection is in progress using poll instead of select
        if errno == EINPROGRESS {
            var pollFd = pollfd(fd: sock, events: Int16(POLLOUT), revents: 0)
            let pollResult = poll(&pollFd, 1, 100) // 100ms timeout
            
            if pollResult > 0 && (pollFd.revents & Int16(POLLOUT)) != 0 {
                var error: Int32 = 0
                var len = socklen_t(MemoryLayout<Int32>.size)
                getsockopt(sock, SOL_SOCKET, SO_ERROR, &error, &len)
                return error == 0
            }
        }
        
        return false
    }
}

// MARK: - Testable Interface

/// Testable version of DebuggerDetector for unit tests
final class TestableDebuggerDetector: DebuggerDetectorProtocol {
    
    var mockIsDebugging: Bool = false
    var mockDebuggerType: DebuggerType? = nil
    var skipAlertsInDebugBuild: Bool = true
    var isDebugBuild: Bool = false
    
    func isDebuggerAttached() -> Bool {
        if isDebugBuild && skipAlertsInDebugBuild {
            return false
        }
        return mockIsDebugging
    }
    
    func detectDebugger() -> DebuggerResult {
        if isDebugBuild && skipAlertsInDebugBuild {
            return DebuggerResult(isDebugging: false, debuggerType: nil)
        }
        return DebuggerResult(
            isDebugging: mockIsDebugging,
            debuggerType: mockDebuggerType
        )
    }
    
    func enableAntiDebugging() {
        // No-op for testing
    }
}
