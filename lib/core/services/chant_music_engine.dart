import 'dart:async';

import 'package:audioplayers/audioplayers.dart' show PlayerState;

/// 佛曲的底層播放引擎：只負責「播放一個本機音檔」，
/// 曲目切換、系統媒體控制 (MediaSession / Now Playing) 由 ChantAudioHandler 負責。
///
/// 正式 App 在兩個平台都用 NativeLoopChantEngine (原生無縫循環)；
/// 測試可以注入自己的實作。
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
