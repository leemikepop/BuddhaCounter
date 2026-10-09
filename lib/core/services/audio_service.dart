import 'package:audioplayers/audioplayers.dart';
import '../constants/chant_songs.dart';
import 'background_audio_service.dart';
import 'storage_service.dart';

class AudioService {
  final AudioPlayer _sfxPlayer = AudioPlayer();
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
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    _musicPlayer.setReleaseMode(ReleaseMode.loop);

    // 關鍵設定：點擊音效 (木魚/引磬) 走媒體音效通道 (Media stream)，不隨手機靜音鍵靜音，且無焦點搶佔避免中斷佛曲
    _sfxPlayer.setAudioContext(
      AudioContext(
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
      ),
    );

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
  Future<void> playClickSfx(SoundEffectType type) async {
    if (type == SoundEffectType.none) return;
    final file = (type == SoundEffectType.bell) ? 'audio/ens.mp3' : 'audio/mus.mp3';
    // 直接 play，無需額外 stop() 避免 Android MediaPlayer 非法狀態
    await _sfxPlayer.play(AssetSource(file));
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
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}
