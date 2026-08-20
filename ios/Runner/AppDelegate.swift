import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    /// Security method channel reference
    private var securityChannel: SecurityMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        
        // Setup uptime channel
        setupUptimeChannel(controller: controller)
        
        // Setup security channel
        setupSecurityChannel(controller: controller)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Channel Setup
    
    /// Sets up the uptime method channel
    private func setupUptimeChannel(controller: FlutterViewController) {
        let uptimeChannel = FlutterMethodChannel(
            name: "CHANNEL_ANDROID_SYSTEM",
            binaryMessenger: controller.binaryMessenger
        )
        
        uptimeChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard call.method == "getUptime" else {
                result(FlutterMethodNotImplemented)
                return
            }
            self?.receiveUptime(result: result)
        }
    }
    
    /// Sets up the security method channel
    private func setupSecurityChannel(controller: FlutterViewController) {
        // Initialize security channel
        securityChannel = SecurityMethodChannel(
            binaryMessenger: controller.binaryMessenger
        )
        
        // Defer security initialization to avoid blocking app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.initializeSecurityServices()
        }
    }
    
    /// Initializes security services after app launch
    private func initializeSecurityServices() {
        // Enable anti-debugging measures in release builds only
        #if !DEBUG
        // Skip on simulator as some checks don't work properly
        #if !targetEnvironment(simulator)
        DebuggerDetector.shared.enableAntiDebugging()
        #endif
        #endif
        
        // Start runtime monitoring on background thread
        DispatchQueue.global(qos: .utility).async {
            BinaryProtectionService.shared.startRuntimeMonitoring()
        }
    }
    
    // MARK: - Method Handlers
    
    private func receiveUptime(result: FlutterResult) {
        let uptime = ProcessInfo.processInfo.systemUptime
        result(Int(uptime * 1000)) // Convert to milliseconds
    }
}
