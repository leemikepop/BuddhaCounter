import 'package:audioplayers/audioplayers.dart';
import 'storage_service.dart';

class AudioService {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  AudioPlayer get musicPlayer => _musicPlayer;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _currentSongId = 1;
  int get currentSongId => _currentSongId;

  AudioService() {
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    _musicPlayer.setReleaseMode(ReleaseMode.loop);

    _musicPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
    });
  }

  /// 播放點擊音效（木魚或引磬）
  Future<void> playClickSfx(SoundEffectType type) async {
    if (type == SoundEffectType.none) return;
    final file = (type == SoundEffectType.bell) ? 'audio/ens.mp3' : 'audio/mus.mp3';
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource(file));
  }

  /// 播放指定佛曲
  Future<void> playChant(int songId) async {
    _currentSongId = songId;
    final file = 'audio/bb$songId.mp3';
    await _musicPlayer.stop();
    await _musicPlayer.play(AssetSource(file));
    _isPlaying = true;
  }

  /// 暫停/恢復播放
  Future<void> toggleChantPlay(int songId) async {
    if (_isPlaying) {
      await _musicPlayer.pause();
      _isPlaying = false;
    } else {
      if (_currentSongId != songId) {
        await playChant(songId);
      } else {
        await _musicPlayer.resume();
        _isPlaying = true;
      }
    }
  }

  Future<void> pauseChant() async {
    await _musicPlayer.pause();
    _isPlaying = false;
  }

  Future<void> resumeChant() async {
    await _musicPlayer.resume();
    _isPlaying = true;
  }

  Future<void> stopChant() async {
    await _musicPlayer.stop();
    _isPlaying = false;
  }

  void dispose() {
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}
