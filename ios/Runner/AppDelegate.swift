import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let cameraChannel = FlutterMethodChannel(
      name: "com.example.dual_recorder/camera_capability",
      binaryMessenger: controller.binaryMessenger)
    
    cameraChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "hasConcurrentCameraSupport":
        result(self.hasConcurrentCameraSupport())
      case "getCameraIds":
        result(self.getCameraIds())
      case "getDeviceModel":
        result(self.getDeviceModel())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func hasConcurrentCameraSupport() -> Bool {
    // iOS 13+ supports multi-camera sessions
    guard #available(iOS 13.0, *) else { return false }
    
    // Check if the device supports multi-camera capture
    if #available(iOS 13.1, *) {
      return AVCaptureMultiCamSession.isMultiCamSupported
    }
    return false
  }
  
  private func getCameraIds() -> [String] {
    var cameraIds: [String] = []
    
    if #available(iOS 10.0, *) {
      let session = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera],
        mediaType: .video,
        position: .unspecified)
      
      for (index, device) in session.devices.enumerated() {
        cameraIds.append("\(index)")
      }
    }
    
    return cameraIds
  }
  
  private func getDeviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let modelCode = withUnsafeBytes(of: &systemInfo.machine) { ptr in
      ptr.compactMap { $0 > 0 ? Character(UnicodeScalar($0)) : nil }.string
    }
    return modelCode
  }
}
