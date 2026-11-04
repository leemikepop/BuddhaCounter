import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'chant_audio_handler.dart';
import 'storage_service.dart';

class AudioService {
  /// 點擊音效播放器池容量 (6 個獨立通道，支援極速連擊與疊音迴響，且記憶體佔用極低)
  static const int _sfxPoolSize = 6;

  /// 固定音效播放器池 (避免動態創建物件產生記憶體抖動與 GC 負擔)
  final List<AudioPlayer> _sfxPool = List.generate(
    _sfxPoolSize,
    (index) => AudioPlayer(playerId: 'sfx_pool_$index'),
  );

  /// 輪詢指針 (Round-Robin Pointer)
  int _sfxPoolIndex = 0;

  /// 系統級媒體處理器 (接軌 Android MediaSession 與 iOS NowPlayingCenter)
  final ChantAudioHandler _handler;
  ChantAudioHandler get handler => _handler;

  bool get isPlaying => _handler.isPlaying;

  int get currentSongId => _handler.currentSongId;

  Stream<Duration> get onPositionChanged => _handler.onPositionChanged;
  Stream<Duration> get onDurationChanged => _handler.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged => _handler.onPlayerStateChanged;
  Stream<void> get onPlayerComplete => _handler.onPlayerComplete;
  Stream<int> get onCurrentSongChanged => _handler.onCurrentSongChanged;
  Stream<bool> get onPlayStateChanged => _handler.onPlayStateChanged;

  Future<Duration?> getCurrentPosition() => _handler.getCurrentPosition();
  Future<Duration?> getDuration() => _handler.getDuration();

  /// 點擊音效 (木魚 / 引磬) 的 Android 音訊設定：不搶音訊焦點、不保持喚醒。
  /// iOS 不使用：iOS 只有一份全域 session，由 [ChantAudioHandler.configureIosAudioSession] 統一設定。
  static final AudioContext _sfxAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  AudioService({ChantAudioHandler? handler})
      : _handler = handler ?? ChantAudioHandler() {
    // 初始化點擊音效池：關閉進度輪詢（杜絕音效觸發 FramePositionUpdater 每幀 IPC），設置停止釋放模式與無焦點搶佔上下文
    for (final player in _sfxPool) {
      player.positionUpdater = null;
      player.setReleaseMode(ReleaseMode.stop);
      // iOS 上單一播放器的設定會覆蓋全域 session (過去的 mixWithOthers 即由此生效)，因此只在 Android 設定
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        player.setAudioContext(_sfxAudioContext).catchError((Object e) {
          debugPrint('AudioService: sfx audio context failed: $e');
        });
      }
    }
  }

  /// 播放點擊音效（木魚或引磬）
  /// 採用輪詢音效池 (Round-Robin Pool) 架構：
  /// 1. 每次點擊均由獨立通道發聲，達成無延遲即時反饋
  /// 2. 允許多個敲擊聲在不同通道同時疊加（例如引磬之金屬餘音與後續木魚聲自然共鳴）
  /// 3. 播放前先清空該通道狀態，徹底解決 Android 原生端多擊後無聲/卡死的缺陷
  /// 4. 固定通道池不產生額外物件分配，兼顧極致效能與系統穩定性
  Future<void> playClickSfx(SoundEffectType type) async {
    final file = type.assetPath;
    if (file == null) return;

    // 取得當前輪詢通道並推進指針
    final player = _sfxPool[_sfxPoolIndex];
    _sfxPoolIndex = (_sfxPoolIndex + 1) % _sfxPoolSize;

    // 非阻塞 (Fire-and-forget) 重置並播放：
    // 先 stop 清除通道狀態（重設 position 為 0 且 playing 標記為 false），
    // 隨即播放音訊，徹底杜絕連點時通道因播放未完成或狀態卡死而無聲的問題
    player.stop().then((_) {
      player.play(AssetSource(file)).catchError((_) {});
    }).catchError((_) {
      player.play(AssetSource(file)).catchError((_) {});
    });
  }

  /// 播放指定佛曲 (更新 OS 通知欄與鎖定畫面控制卡片)
  Future<void> playChant(int songId) => _handler.playSong(songId);

  /// 暫停播放
  Future<void> pauseChant() => _handler.pause();

  /// 恢復播放
  Future<void> resumeChant() => _handler.play();

  /// 停止播放
  Future<void> stopChant() => _handler.stop();

  /// 暫停/恢復播放指定佛曲
  Future<void> toggleChantPlay(int songId) => _handler.togglePlay(songId);

  /// 跳至上一首
  Future<void> playPrevSong() => _handler.skipToPrevious();

  /// 跳至下一首
  Future<void> playNextSong() => _handler.skipToNext();

  /// 跳至指定播放位置
  Future<void> seek(Duration position) => _handler.seek(position);

  /// 相對快轉或倒退
  Future<void> seekRelative(Duration offset) async {
    final cur = await getCurrentPosition() ?? Duration.zero;
    final dur = await getDuration() ?? Duration.zero;
    var target = cur + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (dur > Duration.zero && target > dur) target = dur;
    await seek(target);
  }

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
