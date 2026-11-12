import Flutter
import UIKit

public class GtAudioPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.govindtank.gt_audio/channel", binaryMessenger: registrar.messenger())
    let instance = GtAudioPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getArtworkAuthority":
      result("")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
