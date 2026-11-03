import AVKit

private let defaultPlaybackRate: Double = 1.0

private let defaultVolume: Double = 1.0

private let defaultReleaseMode: ReleaseMode = ReleaseMode.release

typealias Completer = () -> Void

typealias CompleterError = (Error?) -> Void

enum ReleaseMode: String {
  case stop
  case release
  case loop
}

@MainActor class WrappedMediaPlayer {
  private(set) var eventHandler: AudioPlayersStreamHandler
  private(set) var isPlaying: Bool
  var releaseMode: ReleaseMode {
    didSet {
      updateLooper()
    }
  }

  private var reference: AudioplayersDarwinPlugin
  private var player: AVQueuePlayer
  private var looper: AVPlayerLooper?
  private var playbackRate: Double
  private var volume: Double
  private var url: String?

  private var completionObserver: TimeObserver?
  private var playerItemStatusObservation: NSKeyValueObservation?

  init(
    reference: AudioplayersDarwinPlugin,
    eventHandler: AudioPlayersStreamHandler,
    player: AVQueuePlayer = AVQueuePlayer.init(),
    playbackRate: Double = defaultPlaybackRate,
    volume: Double = defaultVolume,
    releaseMode: ReleaseMode = defaultReleaseMode,
    url: String? = nil
  ) {
    self.reference = reference
    self.eventHandler = eventHandler
    self.player = player
    self.completionObserver = nil
    self.playerItemStatusObservation = nil

    self.isPlaying = false
    self.playbackRate = playbackRate
    self.volume = volume
    self.releaseMode = releaseMode
    self.url = url
  }

  func setSourceUrl(
    url: String,
    isLocal: Bool,
    mimeType: String? = nil
  ) async throws {
    let playbackStatus = player.currentItem?.status

    if self.url != url || playbackStatus == .failed || playbackStatus == nil {
      reset()
      self.url = url
      let playerItem = try createPlayerItem(url: url, isLocal: isLocal, mimeType: mimeType)
      // Need to observe item status immediately after creating:
      try await setUpPlayerItemStatusObservation(playerItem)
      // Needs to be called after the preparation has completed.
      self.updateDuration()

      self.setUpSoundCompletedObserver(self.player, playerItem)
      self.updateLooper()
      self.eventHandler.onPrepared(isPrepared: true)
    } else {
      if playbackStatus == .readyToPlay {
        self.updateLooper()
        self.eventHandler.onPrepared(isPrepared: true)
      }
    }
  }

  private func updateLooper() {
    if releaseMode == .loop {
      if looper == nil, let currentItem = player.currentItem {
        looper = AVPlayerLooper(player: player, templateItem: currentItem)
      }
    } else {
      looper?.disableLooping()
      looper = nil
    }
  }

  func getDuration() -> Int? {
    guard let duration = getDurationCMTime() else {
      return nil
    }
    return fromCMTime(time: duration)
  }

  func getCurrentPosition() -> Int? {
    guard let time = getCurrentCMTime() else {
      return nil
    }
    return fromCMTime(time: time)
  }

  func pause() {
    isPlaying = false
    player.pause()
  }

  func resume() {
    isPlaying = true
    configParameters(player: player)
    if #available(iOS 10.0, macOS 10.12, *) {
      player.playImmediately(atRate: Float(playbackRate))
    } else {
      player.play()
    }
    updateDuration()
  }

  func setVolume(volume: Double) {
    self.volume = volume
    player.volume = Float(volume)
  }

  func setPlaybackRate(playbackRate: Double) {
    self.playbackRate = playbackRate
    if isPlaying {
      // Setting the rate causes the player to resume playing. So setting it only, when already playing.
      player.rate = Float(playbackRate)
    }
  }

  func seek(time: CMTime) async {
    guard let currentItem = player.currentItem else {
      return
    }
    let wasLooping = (self.releaseMode == .loop)
    if wasLooping {
      looper?.disableLooping()
      looper = nil
    }
    await currentItem.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    if !self.isPlaying {
      self.player.pause()
    }
    if wasLooping {
      updateLooper()
    }
    self.eventHandler.onSeekComplete()
  }

  func stop() async {
    pause()
    if releaseMode == ReleaseMode.release {
      await release()
    } else if (getCurrentPosition() ?? 0) != 0 {
      await seek(time: toCMTime(millis: 0))
    }
  }

  func release() async {
    if self.isPlaying {
      pause()
    }
    self.reset()
  }

  func dispose() async {
    await release()
    self.eventHandler.dispose()
  }

  private func getDurationCMTime() -> CMTime? {
    return player.currentItem?.asset.duration
  }

  private func getCurrentCMTime() -> CMTime? {
    return player.currentItem?.currentTime()
  }

  private func createPlayerItem(
    url: String,
    isLocal: Bool,
    mimeType: String? = nil
  ) throws -> AVPlayerItem {
    guard
      let parsedUrl = isLocal
        ? URL(fileURLWithPath: url.deletingPrefix("file://")) : URL(string: url)
    else {
      throw AudioPlayerError.error("Url not valid: \(url)")
    }

    let playerItem: AVPlayerItem

    if let unwrappedMimeType = mimeType {
      if #available(iOS 17, macOS 14.0, *) {
        let asset = AVURLAsset(
          url: parsedUrl, options: [AVURLAssetOverrideMIMETypeKey: unwrappedMimeType])
        playerItem = AVPlayerItem(asset: asset)
      } else {
        let asset = AVURLAsset(
          url: parsedUrl, options: ["AVURLAssetOutOfBandMIMETypeKey": unwrappedMimeType])
        playerItem = AVPlayerItem(asset: asset)
      }
    } else {
      playerItem = AVPlayerItem(url: parsedUrl)
    }

    playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.timeDomain
    return playerItem
  }

  private func setUpPlayerItemStatusObservation(
    _ playerItem: AVPlayerItem
  ) async throws {
    try await withCheckedThrowingContinuation { continuation in
      playerItemStatusObservation = playerItem.observe(\AVPlayerItem.status) {
        [weak self] (playerItem, change) in
        guard let self = self else {
          return
        }
        let status = playerItem.status
        self.eventHandler.onLog(message: "player status: \(status), change: \(change)")

        switch status {
        case .readyToPlay:
          continuation.resume()
        case .failed:
          self.reset()
          continuation.resume(throwing: AudioPlayerError.error("Failed to set playerItem"))
        default:
          // Do not resume continuation yet
          break
        }
      }
      // Replacing the player item triggers continuation of the observation.
      self.player.replaceCurrentItem(with: playerItem)
    }

    playerItemStatusObservation?.invalidate()
    playerItemStatusObservation = nil
  }

  private func setUpSoundCompletedObserver(_ player: AVPlayer, _ playerItem: AVPlayerItem) {
    let observer = NotificationCenter.default.addObserver(
      forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: nil
    ) {
      (notification) in
      Task { @MainActor [weak self] in
        guard let self = self else {
          return
        }
        await self.onSoundComplete()
      }
    }
    self.completionObserver = TimeObserver(player: player, observer: observer)
  }

  private func configParameters(player: AVPlayer) {
    if isPlaying {
      player.volume = Float(volume)
      player.rate = Float(playbackRate)
    }
  }

  private func reset() {
    looper?.disableLooping()
    looper = nil
    playerItemStatusObservation?.invalidate()
    playerItemStatusObservation = nil
    if let cObserver = completionObserver {
      NotificationCenter.default.removeObserver(cObserver.observer)
      completionObserver = nil
    }
    player.removeAllItems()
    self.url = nil
  }

  private func updateDuration() {
    guard let duration = player.currentItem?.asset.duration else {
      return
    }
    if CMTimeGetSeconds(duration) > 0 {
      let millis = fromCMTime(time: duration)
      eventHandler.onDuration(millis: millis)
    }
  }

  private func onSoundComplete() async {
    if !isPlaying {
      return
    }

    // 當開啟原生 AVPlayerLooper 時，底層無縫循環，不會進到此結束事件。
    // 若 looper 因極端狀況未接管，此處提供強化版防停頓備援：
    // 單曲循環時避免呼叫 controlAudioSession (避免 IPC 卡死) 與 eventHandler.onComplete (避免 Dart 端中斷計時器)
    if self.releaseMode != ReleaseMode.loop {
      reference.controlAudioSession()
      eventHandler.onComplete()
    }

    if let currentItem = player.currentItem {
      await currentItem.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    if self.releaseMode == ReleaseMode.loop {
      self.resume()
    } else if self.releaseMode == ReleaseMode.release {
      await self.release()
    } else {
      self.isPlaying = false
    }
  }
}

