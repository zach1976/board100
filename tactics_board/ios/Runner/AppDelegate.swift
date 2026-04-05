import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SharePlugin") {
      setupShareChannel(with: registrar)
    }
  }

  private func setupShareChannel(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.zach.tacticsboard/share", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { (call, result) in
      if call.method == "shareFile" {
        if let args = call.arguments as? [String: Any], let path = args["path"] as? String {
          self.shareFile(path: path)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing path", details: nil))
        }
      } else if call.method == "openUrl" {
        if let args = call.arguments as? [String: Any], let urlString = args["url"] as? String,
           let url = URL(string: urlString) {
          UIApplication.shared.open(url, options: [:]) { success in
            result(success)
          }
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing url", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func shareFile(path: String) {
    let url = URL(fileURLWithPath: path)
    guard let controller = self.topViewController() else { return }
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = controller.view
      popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.maxY - 100, width: 0, height: 0)
    }
    controller.present(activityVC, animated: true)
  }

  private func topViewController() -> UIViewController? {
    var vc: UIViewController?
    if #available(iOS 15.0, *) {
      vc = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController
    } else {
      vc = UIApplication.shared.keyWindow?.rootViewController
    }
    while let presented = vc?.presentedViewController {
      vc = presented
    }
    return vc
  }
}
