import 'package:audioplayers/audioplayers.dart';
import '../constants/chant_songs.dart';
import 'background_audio_service.dart';
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

  final AudioPlayer _musicPlayer = AudioPlayer();

  AudioPlayer get musicPlayer => _musicPlayer;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _currentSongId = 0;
  int get currentSongId => _currentSongId;

  Stream<Duration> get onPositionChanged => _musicPlayer.onPositionChanged;
  Stream<Duration> get onDurationChanged => _musicPlayer.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged => _musicPlayer.onPlayerStateChanged;
  Stream<void> get onPlayerComplete => _musicPlayer.onPlayerComplete;

  Future<Duration?> getCurrentPosition() => _musicPlayer.getCurrentPosition();
  Future<Duration?> getDuration() => _musicPlayer.getDuration();

  static final AudioContext _sfxAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  static final AudioContext _musicAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  AudioService() {
    // 初始化點擊音效池：採用標準 MediaPlayer 模式，設置停止釋放模式，並配置無焦點搶佔上下文
    for (final player in _sfxPool) {
      player.setReleaseMode(ReleaseMode.stop);
      player.setAudioContext(_sfxAudioContext);
    }

    _musicPlayer.setReleaseMode(ReleaseMode.loop);

    // 佛曲播放器設為媒體播放模式
    _musicPlayer.setAudioContext(_musicAudioContext);

    _musicPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed && _releaseMode == ReleaseMode.loop) {
        // 在 loop 模式下，播放完畢時僅為微秒級暫態，依然保持播放狀態
        _isPlaying = true;
      } else {
        _isPlaying = (state == PlayerState.playing);
      }
    });

    // 關鍵修復：監聽曲目完成事件，確保在背景播放時達到 100% 循環可靠性
    _musicPlayer.onPlayerComplete.listen((_) async {
      if (_releaseMode == ReleaseMode.loop) {
        try {
          await _musicPlayer.seek(Duration.zero);
          await _musicPlayer.resume();
          await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        } catch (_) {
          await playChant(_currentSongId);
        }
      }
    });
  }

  /// 播放點擊音效（木魚或引磬）
  /// 採用輪詢音效池 (Round-Robin Pool) 架構：
  /// 1. 每次點擊均由獨立通道發聲，達成無延遲即時反饋
  /// 2. 允許多個敲擊聲在不同通道同時疊加（例如引磬之金屬餘音與後續木魚聲自然共鳴）
  /// 3. 播放前先清空該通道狀態，徹底解決 Android 原生端多擊後無聲/卡死的缺陷
  /// 4. 固定通道池不產生額外物件分配，兼顧極致效能與系統穩定性
  Future<void> playClickSfx(SoundEffectType type) async {
    if (type == SoundEffectType.none) return;
    final file = (type == SoundEffectType.bell) ? 'audio/ens.mp3' : 'audio/mus.mp3';

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

  /// 播放指定佛曲
  Future<void> playChant(int songId) async {
    _currentSongId = songId;
    _isPlaying = true;
    final song = ChantConstants.getSongById(songId);
    BackgroundAudioService.start(
      title: '念佛、拜佛計數器',
      chantName: '${song.title} · 念佛梵音播放中',
    );
    // 直接 play，並在加載後重新確認 setReleaseMode 與 AudioContext，
    // 防止 Android 原生 MediaPlayer reset() 時丟失 isLooping 與 PARTIAL_WAKE_LOCK
    await _musicPlayer.play(AssetSource(song.assetPath));
    await _musicPlayer.setReleaseMode(_releaseMode);
    await _musicPlayer.setAudioContext(_musicAudioContext);
  }

  /// 暫停播放
  Future<void> pauseChant() async {
    _isPlaying = false;
    BackgroundAudioService.stop();
    await _musicPlayer.pause();
  }

  /// 恢復播放（若無法從暫停點恢復則自動重新載入播放）
  Future<void> resumeChant() async {
    _isPlaying = true;
    final song = ChantConstants.getSongById(_currentSongId);
    BackgroundAudioService.start(
      title: '念佛、拜佛計數器',
      chantName: '${song.title} · 念佛梵音播放中',
    );
    try {
      await _musicPlayer.resume();
      await _musicPlayer.setReleaseMode(_releaseMode);
      if (_musicPlayer.state != PlayerState.playing) {
        await playChant(_currentSongId);
      }
    } catch (_) {
      await playChant(_currentSongId);
    }
  }

  /// 停止播放
  Future<void> stopChant() async {
    _isPlaying = false;
    BackgroundAudioService.stop();
    await _musicPlayer.stop();
  }

  /// 暫停/恢復播放指定佛曲（可靠的切換邏輯，支援連續開啟關閉開啟）
  Future<void> toggleChantPlay(int songId) async {
    if (_isPlaying) {
      if (_currentSongId == songId) {
        await pauseChant();
      } else {
        await playChant(songId);
      }
    } else {
      if (_currentSongId == songId && _musicPlayer.state == PlayerState.paused) {
        await resumeChant();
      } else {
        await playChant(songId);
      }
    }
  }

  /// 跳至指定播放位置
  Future<void> seek(Duration position) async {
    await _musicPlayer.seek(position);
  }

  /// 相對快轉或倒退
  Future<void> seekRelative(Duration offset) async {
    final cur = await _musicPlayer.getCurrentPosition() ?? Duration.zero;
    final dur = await _musicPlayer.getDuration() ?? Duration.zero;
    var target = cur + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (dur > Duration.zero && target > dur) target = dur;
    await _musicPlayer.seek(target);
  }

  ReleaseMode _releaseMode = ReleaseMode.loop;
  ReleaseMode get releaseMode => _releaseMode;

  Future<void> setReleaseMode(ReleaseMode mode) async {
    _releaseMode = mode;
    await _musicPlayer.setReleaseMode(mode);
  }

  void dispose() {
    BackgroundAudioService.stop();
    for (final player in _sfxPool) {
      player.dispose();
    }
    _musicPlayer.dispose();
  }
}
