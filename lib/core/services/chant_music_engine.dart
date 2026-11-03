import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// 佛曲的底層播放引擎：只負責「播放一個本機音檔」，
/// 曲目切換、系統媒體控制 (MediaSession / Now Playing) 由 ChantAudioHandler 負責。
///
/// 各平台實作：
/// - Android：[AudioplayersChantEngine] (MediaPlayer 原生循環)
/// - iOS：IosLoopChantEngine (AVQueuePlayer + AVPlayerLooper 無縫循環)
abstract class ChantMusicEngine {
  /// 播放狀態變化 (playing / paused / stopped / completed)
  Stream<PlayerState> get onStateChanged;

  /// 音檔長度更新
  Stream<Duration> get onDurationChanged;

  /// 不循環時播完一遍觸發；循環模式下由引擎自行接回開頭，不會觸發
  Stream<void> get onComplete;

  PlayerState get state;

  Future<void> init();

  /// 載入本機音檔並從頭開始播放
  Future<void> playFile(String path, {required bool looping});

  Future<void> resume();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<Duration?> getPosition();
  Future<Duration?> getDuration();

  /// 切換單曲循環 (播放中切換不中斷)
  Future<void> setLooping(bool looping);

  Future<void> dispose();
}

/// 以 audioplayers 單一播放器實作 (Android)
class AudioplayersChantEngine implements ChantMusicEngine {
  AudioplayersChantEngine({this.audioContext});

  /// 套用到播放器的音訊設定 (Android：取得音訊焦點並保持喚醒)
  final AudioContext? audioContext;

  final AudioPlayer _player = AudioPlayer(playerId: 'chant_music_player');

  @override
  Stream<PlayerState> get onStateChanged => _player.onPlayerStateChanged;

  @override
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  PlayerState get state => _player.state;

  @override
  Future<void> init() async {
    // 進度由 ChantAudioHandler 以 250ms 定時查詢，關閉 audioplayers 預設的逐幀查詢 (每幀跨執行緒呼叫)
    _player.positionUpdater = null;
    await _player.setReleaseMode(ReleaseMode.loop);
    if (audioContext != null) {
      await _player.setAudioContext(audioContext!);
    }
  }

  @override
  Future<void> playFile(String path, {required bool looping}) async {
    await _player.setReleaseMode(looping ? ReleaseMode.loop : ReleaseMode.stop);
    await _player.play(DeviceFileSource(path, mimeType: 'audio/ogg'));
  }

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<Duration?> getPosition() => _player.getCurrentPosition();

  @override
  Future<Duration?> getDuration() => _player.getDuration();

  @override
  Future<void> setLooping(bool looping) =>
      _player.setReleaseMode(looping ? ReleaseMode.loop : ReleaseMode.stop);

  @override
  Future<void> dispose() => _player.dispose();
}
