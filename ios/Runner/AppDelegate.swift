import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TaskTimeZone") {
      FlutterMethodChannel(name: "tasks/timezone", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          if call.method == "local" { result(TimeZone.current.identifier) }
          else { result(FlutterMethodNotImplemented) }
        }
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
