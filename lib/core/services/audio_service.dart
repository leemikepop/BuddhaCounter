import 'package:audioplayers/audioplayers.dart';
import '../constants/chant_songs.dart';
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

  Future<Duration?> getCurrentPosition() => _musicPlayer.getCurrentPosition();
  Future<Duration?> getDuration() => _musicPlayer.getDuration();

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
    _musicPlayer.setAudioContext(
      AudioContext(
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
      ),
    );

    _musicPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
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
    final song = ChantConstants.getSongById(songId);
    // 直接 play，audioplayers 會自動處理新音訊來源重置，不需多餘的 stop()
    await _musicPlayer.play(AssetSource(song.assetPath));
    _isPlaying = true;
  }

  /// 暫停播放
  Future<void> pauseChant() async {
    await _musicPlayer.pause();
    _isPlaying = false;
  }

  /// 恢復播放（若無法從暫停點恢復則自動重新載入播放）
  Future<void> resumeChant() async {
    try {
      await _musicPlayer.resume();
      if (_musicPlayer.state != PlayerState.playing) {
        await playChant(_currentSongId);
      } else {
        _isPlaying = true;
      }
    } catch (_) {
      await playChant(_currentSongId);
    }
  }

  /// 停止播放
  Future<void> stopChant() async {
    await _musicPlayer.stop();
    _isPlaying = false;
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
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}
