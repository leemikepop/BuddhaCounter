import AVFoundation
import Flutter

/// 佛曲專用的 iOS 原生播放器：以 AVQueuePlayer + AVPlayerLooper 做到無縫單曲循環。
///
/// 為什麼不用 audioplayers：它在一遍播完後才通知 Dart，再由 Dart 叫播放器重新開始，
/// 這一來一回加上播放器冷啟動，每次重播都有明顯停頓。AVPlayerLooper 會預先把下一遍排進佇列，
/// 接縫完全由系統處理，不經過 Dart。
///
/// 音訊 session (playback、不混音) 仍由 Dart 端 ChantAudioHandler.configureIosAudioSession 統一設定。
/// 對應的 Dart 端：lib/core/services/ios_loop_chant_engine.dart
final class ChantLoopPlayer: NSObject, FlutterPlugin, FlutterStreamHandler {
  static let methodChannelName = "buddha_counter/chant_loop_player"
  static let eventChannelName = "buddha_counter/chant_loop_player/events"

  private let player = AVQueuePlayer()
  private var asset: AVURLAsset?
  private var looper: AVPlayerLooper?
  private var looperStatusObservation: NSKeyValueObservation?
  private var endObserver: NSObjectProtocol?
  private var looping = true
  /// AVPlayerLooper 無法處理這個檔案時，改在原生端播完立即回到開頭 (仍不經過 Dart)
  private var looperUnavailable = false
  private var eventSink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = ChantLoopPlayer()
    let methods = FlutterMethodChannel(
      name: methodChannelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let events = FlutterEventChannel(
      name: eventChannelName, binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // MARK: - Method calls

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "load":
      guard let path = args["path"] as? String else {
        result(FlutterError(code: "bad_args", message: "path is required", details: nil))
        return
      }
      load(
        path: path,
        mimeType: args["mimeType"] as? String,
        looping: args["looping"] as? Bool ?? true,
        result: result)
    case "play":
      activateSession()
      player.playImmediately(atRate: 1.0)
      result(nil)
    case "pause":
      player.pause()
      result(nil)
    case "stop":
      player.pause()
      seek(to: .zero, result: result)
    case "seek":
      let ms = (args["positionMs"] as? NSNumber)?.int64Value ?? 0
      seek(to: CMTime(value: ms, timescale: 1000), result: result)
    case "getPosition":
      result(Self.millis(player.currentItem?.currentTime()))
    case "getDuration":
      result(Self.millis(asset?.duration))
    case "setLooping":
      setLooping(args["looping"] as? Bool ?? true)
      result(nil)
    case "dispose":
      player.pause()
      teardown()
      asset = nil
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Playback

  private func load(
    path: String, mimeType: String?, looping: Bool, result: @escaping FlutterResult
  ) {
    player.pause()
    teardown()
    self.looping = looping
    looperUnavailable = false

    var options: [String: Any] = [:]
    if let mimeType = mimeType {
      if #available(iOS 17.0, *) {
        options[AVURLAssetOverrideMIMETypeKey] = mimeType
      } else {
        options["AVURLAssetOutOfBandMIMETypeKey"] = mimeType
      }
    }
    let asset = AVURLAsset(url: URL(fileURLWithPath: path), options: options)
    self.asset = asset

    asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
      DispatchQueue.main.async {
        // 載入期間又換了別首：放棄這次結果 (Dart 端以請求序號忽略)
        guard let self = self, self.asset === asset else {
          result(nil)
          return
        }
        var error: NSError?
        guard asset.statusOfValue(forKey: "duration", error: &error) == .loaded else {
          self.sendLog("load failed: \(error?.localizedDescription ?? "unknown") (\(path))")
          result(
            FlutterError(
              code: "load_failed", message: error?.localizedDescription, details: path))
          return
        }
        self.buildQueue(startAt: .zero)
        result(Self.millis(asset.duration))
      }
    }
  }

  /// 依目前的循環設定重建播放佇列
  private func buildQueue(startAt start: CMTime) {
    teardown()
    guard let asset = asset else { return }
    let template = AVPlayerItem(asset: asset)

    if looping && !looperUnavailable {
      player.actionAtItemEnd = .advance
      let looper = AVPlayerLooper(player: player, templateItem: template)
      self.looper = looper
      looperStatusObservation = looper.observe(\.status, options: [.initial, .new]) {
        [weak self] observed, _ in
        switch observed.status {
        case .ready:
          DispatchQueue.main.async { self?.sendLog("loop mode: AVPlayerLooper (gapless)") }
        case .failed:
          DispatchQueue.main.async { self?.fallBackFromLooper(observed) }
        default:
          break
        }
      }
    } else {
      // 播完停在最後一格，不讓佇列清空 (循環備援時才能 seek 回開頭)
      player.actionAtItemEnd = .pause
      player.insert(template, after: nil)
      endObserver = NotificationCenter.default.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime, object: template, queue: .main
      ) { [weak self] _ in
        self?.itemDidPlayToEnd()
      }
    }

    if CMTimeCompare(start, .zero) > 0 {
      player.seek(to: start, toleranceBefore: .zero, toleranceAfter: .zero)
    }
  }

  private func fallBackFromLooper(_ failed: AVPlayerLooper) {
    guard failed === looper else { return }
    sendLog(
      "loop mode: seek fallback (AVPlayerLooper failed: \(failed.error?.localizedDescription ?? "unknown"))"
    )
    let wasPlaying = player.rate != 0
    let position = player.currentItem?.currentTime() ?? .zero
    looperUnavailable = true
    buildQueue(startAt: position)
    if wasPlaying {
      player.playImmediately(atRate: 1.0)
    }
  }

  private func itemDidPlayToEnd() {
    if looping {
      // 循環備援：在原生端立即回到開頭續播，不等 Dart
      player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
      player.playImmediately(atRate: 1.0)
      return
    }
    eventSink?(["event": "complete"])
  }

  private func setLooping(_ newValue: Bool) {
    guard newValue != looping else { return }
    looping = newValue
    guard asset != nil, player.currentItem != nil else { return }
    // 備援模式下 itemDidPlayToEnd 會直接依 looping 判斷，不需重建
    if looperUnavailable { return }
    let wasPlaying = player.rate != 0
    let position = player.currentItem?.currentTime() ?? .zero
    buildQueue(startAt: position)
    if wasPlaying {
      player.playImmediately(atRate: 1.0)
    }
  }

  private func seek(to time: CMTime, result: @escaping FlutterResult) {
    player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
      DispatchQueue.main.async { result(nil) }
    }
  }

  private func teardown() {
    looperStatusObservation?.invalidate()
    looperStatusObservation = nil
    looper?.disableLooping()
    looper = nil
    if let observer = endObserver {
      NotificationCenter.default.removeObserver(observer)
      endObserver = nil
    }
    player.removeAllItems()
  }

  private func activateSession() {
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      sendLog("audio session activation failed: \(error.localizedDescription)")
    }
  }

  private func sendLog(_ message: String) {
    NSLog("ChantLoopPlayer: %@", message)
    eventSink?(["event": "log", "message": message])
  }

  private static func millis(_ time: CMTime?) -> Int? {
    guard let time = time, time.isNumeric else { return nil }
    let seconds = CMTimeGetSeconds(time)
    guard seconds.isFinite else { return nil }
    return Int((seconds * 1000).rounded())
  }
}
