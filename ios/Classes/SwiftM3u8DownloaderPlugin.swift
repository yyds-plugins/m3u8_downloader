import Flutter
import UIKit

public class SwiftM3u8DownloaderPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "vincent/m3u8_downloader", binaryMessenger: registrar.messenger())
    let instance = SwiftM3u8DownloaderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
}
