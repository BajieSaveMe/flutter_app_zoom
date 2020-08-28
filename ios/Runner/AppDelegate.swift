import UIKit
import Flutter
import ZoomAuthentication
import LocalAuthentication

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    /// Flutter VC for bridging with Flutter code part
    private var flutterVC: FlutterViewController?
    var requestInProgress: Bool = false
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialise
        guard let window = self.window else { return false }
        let flutterVC = window.rootViewController as! FlutterViewController
        self.flutterVC = flutterVC
        
        // Opt-out from iOS 13.0+ dark mode
        if #available(iOS 13.0, *) {
            self.window.overrideUserInterfaceStyle = .light
        }
        
        self.initialiseServices()
        self.setupAllChannels()
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func setupAllChannels() {
        self.facetecChannelInvocation()
    }
    
    private func initialiseServices() {
        // ZoOm
        Zoom.sdk.initialize(licenseKeyIdentifier: ZoomGlobalState.DeviceLicenseKeyIdentifier, faceMapEncryptionKey: ZoomGlobalState.PublicFaceMapEncryptionKey) { (isSuccessful) in
            if (isSuccessful) {
                print("ZoOm initialisation success!")
            } else {
                print("ZoOm initialisation failed!")
            }
        }
    }
    
    private func facetecChannelInvocation() {
        if let flutterVC = self.flutterVC {
            let facetecChannel = FlutterMethodChannel(name: "facetec_plugin", binaryMessenger: flutterVC.binaryMessenger)
            facetecChannel.setMethodCallHandler { (call, result) in
                switch call.method {
                case "livenessCheck":
                    let _ = LivenessCheckProcessor(delegate: self, fromVC: flutterVC)
                    result("Success")
                case "enrollUser":
                    let _ = EnrollmentProcessor(delegate: self, fromVC: flutterVC)
                    result("Success")
                case "authenticateUser":
                    let _ = AuthenticateProcessor(delegate: self, fromVC: flutterVC)
                    result("Success")
                case "photoIDMatch":
                    let _ = PhotoIDMatchProcessor(delegate: self, fromVC: flutterVC)
                    result("Success")
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }
    }
}

// ZoOm processing delegate call
extension AppDelegate: ProcessingDelegate {
    func onProcessingComplete(isSuccess: Bool, zoomSessionResult: ZoomSessionResult?) {
        // TODO: Invoke to Flutter here
        print("ZoOm SDK =========== onProcessingComplete called!")
    }
    
    func onProcessingComplete(isSuccess: Bool, zoomSessionResult: ZoomSessionResult?, zoomIDScanResult: ZoomIDScanResult?) {
        // TODO: Invoke to Flutter here
        print("ZoOm SDK =========== onProcessingComplete zoomIDScanResult called!")
    }
    
    func onSessionTokenError() {
        // TODO: Invoke to Flutter here
        print("ZoOm SDK =========== onSessionTokenError!")
    }
}
