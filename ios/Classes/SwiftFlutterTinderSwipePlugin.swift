import Flutter
import UIKit

public class SwiftFlutterTinderSwipePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_tinder_swipe", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterTinderSwipePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
