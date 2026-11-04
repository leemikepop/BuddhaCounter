import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'chant_audio_handler.dart';
import 'storage_service.dart';

/// App 的所有聲音：佛曲 (交給 [ChantAudioHandler]，連動系統媒體控制) 與點擊音效 (木魚 / 引磬)
class AudioService {
  AudioService({ChantAudioHandler? handler})
      : _handler = handler ?? ChantAudioHandler() {
    for (final player in _sfxPool) {
      // 音效不需要進度回報，關掉可省下每幀一次的平台通道呼叫
      player.positionUpdater = null;
      player.setReleaseMode(ReleaseMode.stop);
      // iOS 只有一份全域 audio session (見 ChantAudioHandler.configureIosAudioSession)，
      // 單一播放器設定 context 會覆蓋它，所以只在 Android 設定
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        player.setAudioContext(_sfxAudioContext).catchError((Object e) {
          debugPrint('AudioService: sfx audio context failed: $e');
        });
      }
    }
  }

  /// 同時可疊加的音效數 (引磬餘音未停時連敲木魚也不會被切掉)
  static const int _sfxPoolSize = 6;

  /// 點擊音效的 Android 音訊設定：不搶音訊焦點 (不會暫停佛曲或其他 App 的音樂)
  static final AudioContext _sfxAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  final List<AudioPlayer> _sfxPool = List.generate(
    _sfxPoolSize,
    (i) => AudioPlayer(playerId: 'sfx_pool_$i'),
  );
  int _sfxPoolIndex = 0;

  final ChantAudioHandler _handler;
  ChantAudioHandler get handler => _handler;

  bool get isPlaying => _handler.isPlaying;

  Stream<Duration> get onPositionChanged => _handler.onPositionChanged;
  Stream<Duration> get onDurationChanged => _handler.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged => _handler.onPlayerStateChanged;
  Stream<int> get onCurrentSongChanged => _handler.onCurrentSongChanged;

  /// 播放狀態變化 (包含系統媒體控制、耳機線控、音訊焦點造成的)
  Stream<bool> get onPlayStateChanged => _handler.onPlayStateChanged;

  Future<Duration?> getCurrentPosition() => _handler.getCurrentPosition();

  /// 播放點擊音效。輪流使用固定的播放器池，每聲先 stop 再播，
  /// 避免 Android 連點時某個播放器停在未完成狀態而沒有聲音。
  Future<void> playClickSfx(SoundEffectType type) async {
    final file = type.assetPath;
    if (file == null) return;

    final player = _sfxPool[_sfxPoolIndex];
    _sfxPoolIndex = (_sfxPoolIndex + 1) % _sfxPoolSize;

    void play() => player.play(AssetSource(file)).catchError((_) {});
    player.stop().then((_) => play()).catchError((_) => play());
  }

  /// 從頭播放指定佛曲 (同步更新系統通知欄與鎖定畫面)
  Future<void> playChant(int songId) => _handler.playSong(songId);
  Future<void> pauseChant() => _handler.pause();
  Future<void> resumeChant() => _handler.play();
  Future<void> stopChant() => _handler.stop();

  /// 播放中就暫停，否則播放 [songId] (暫停中的同一首會接續播放)
  Future<void> toggleChantPlay(int songId) => _handler.togglePlay(songId);

  Future<void> seek(Duration position) => _handler.seek(position);

  ReleaseMode get releaseMode => _handler.releaseMode;
  Future<void> setReleaseMode(ReleaseMode mode) =>
      _handler.setReleaseMode(mode);

  void dispose() {
    for (final player in _sfxPool) {
      player.dispose();
    }
    _handler.disposePlayer();
  }
}
