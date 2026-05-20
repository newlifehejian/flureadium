import Flutter
import ReadiumShared

class ReadiumReaderChannel: FlutterMethodChannel {
  // Compiles fine without this init, but then mysteriously crashes later with EXC_BAD_ACCESS when calling any member function later.
  init(name: String, binaryMessenger messenger: FlutterBinaryMessenger) {
    super.init(
      name: name, binaryMessenger: messenger, codec: FlutterStandardMethodCodec.sharedInstance(),
      taskQueue: nil)
  }

  func onPageChanged(locator: Locator) {
    invokeMethod("onPageChanged", arguments: locator.jsonString as String?)
  }

  func onExternalLinkActivated(url: URL) {
    invokeMethod("onExternalLinkActivated", arguments: url.absoluteString as String?)
  }

  // Per-view delivery for selection/decoration. The global EventChannels share
  // one channel name across all reader instances, so any instance's
  // subscribe/cancel clobbers the others. This per-view MethodChannel is tied
  // to a single reader, mirroring onPageChanged, and avoids that interference.
  func onSelectionChanged(locatorJson: String?) {
    invokeMethod("onSelectionChanged", arguments: locatorJson)
  }

  func onDecorationActivated(eventJson: String?) {
    invokeMethod("onDecorationActivated", arguments: eventJson)
  }
}
