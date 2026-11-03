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
    // 佛曲無縫循環播放器 (見 ChantLoopPlayer.swift)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ChantLoopPlayer") {
      ChantLoopPlayer.register(with: registrar)
    }
  }
}
