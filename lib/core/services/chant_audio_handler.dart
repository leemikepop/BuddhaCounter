import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/chant_songs.dart';

/// 佛曲媒體播放會話處理器 (整合 Android MediaSession 與 iOS NowPlayingCenter / RemoteCommandCenter)
/// 支援系統通知欄、鎖定畫面、控制中心、動態島、耳機線控 (AirPods) 播放/暫停/上一首/下一首與進度控制
class ChantAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _musicPlayer = AudioPlayer();

  AudioPlayer get musicPlayer => _musicPlayer;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _currentSongId = 0;
  int get currentSongId => _currentSongId;

  ReleaseMode _releaseMode = ReleaseMode.loop;
  ReleaseMode get releaseMode => _releaseMode;

  final StreamController<int> _currentSongController =
      StreamController<int>.broadcast();
  Stream<int> get onCurrentSongChanged => _currentSongController.stream;

  final StreamController<bool> _playStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get onPlayStateChanged => _playStateController.stream;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _currentDuration = Duration.zero;
  Duration get currentDuration => _currentDuration;

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
      options: const {},
    ),
  );

  ChantAudioHandler() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicPlayer.setAudioContext(_musicAudioContext);

    // 監聽播放器狀態
    _musicPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed && _releaseMode == ReleaseMode.loop) {
        _isPlaying = true;
      } else {
        _isPlaying = (state == PlayerState.playing);
      }
      _playStateController.add(_isPlaying);
      _broadcastPlaybackState();
    });

    // 監聽播放進度
    _musicPlayer.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      _broadcastPlaybackState();
    });

    // 監聽長度更新
    _musicPlayer.onDurationChanged.listen((dur) {
      _currentDuration = dur;
      if (mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: dur));
      }
    });

    // 監聽播放完成
    _musicPlayer.onPlayerComplete.listen((_) async {
      if (_releaseMode == ReleaseMode.loop) {
        try {
          await _musicPlayer.seek(Duration.zero);
          await _musicPlayer.resume();
          await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        } catch (_) {
          await playSong(_currentSongId);
        }
      } else {
        await skipToNext();
      }
    });

    // 廣播初始佇列 (Queue)
    final queueItems = ChantConstants.allSongs.map((s) {
      return MediaItem(
        id: s.id.toString(),
        album: '念佛計數器',
        title: s.title,
        artist: '三寶弟子',
      );
    }).toList();
    queue.add(queueItems);
  }

  void _broadcastPlaybackState() {
    final isReady = _isPlaying ||
        _musicPlayer.state == PlayerState.playing ||
        _musicPlayer.state == PlayerState.paused;
    final processingState =
        isReady ? AudioProcessingState.ready : AudioProcessingState.idle;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (_isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2], // 顯示上一首、播放/暫停、下一首
        processingState: processingState,
        playing: _isPlaying,
        updatePosition: _currentPosition,
        bufferedPosition: _currentPosition,
        speed: 1.0,
      ),
    );
  }

  /// 播放指定佛曲
  Future<void> playSong(int songId) async {
    _isPlaying = true;
    _playStateController.add(true);
    _currentSongId = songId;
    _currentSongController.add(songId);
    _currentPosition = Duration.zero;
    _currentDuration = Duration.zero;

    final song = ChantConstants.getSongById(songId);
    final item = MediaItem(
      id: songId.toString(),
      album: '念佛計數器',
      title: song.title,
      artist: '三寶弟子',
      duration: null,
      displayTitle: song.title,
      displaySubtitle: '念佛計數器佛曲播放',
      displayDescription: '保持螢幕休眠或退至背景時佛曲持續播放',
    );
    mediaItem.add(item);
    _broadcastPlaybackState();

    _musicPlayer.play(AssetSource(song.assetPath)).then((_) {
      _musicPlayer.setReleaseMode(_releaseMode).catchError((_) {});
      _musicPlayer.getDuration().then((dur) {
        if (dur != null && dur > Duration.zero) {
          _currentDuration = dur;
          if (mediaItem.value != null) {
            mediaItem.add(mediaItem.value!.copyWith(duration: dur));
          }
        }
      }).catchError((_) {});
    }).catchError((_) {});
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    _playStateController.add(true);
    _broadcastPlaybackState();
    if (_musicPlayer.state == PlayerState.paused) {
      _musicPlayer.resume().catchError((_) {});
    } else {
      await playSong(_currentSongId);
    }
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _playStateController.add(false);
    _broadcastPlaybackState();
    _musicPlayer.pause().catchError((_) {});
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _playStateController.add(false);
    _currentPosition = Duration.zero;
    _musicPlayer.stop().catchError((_) {});
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    _musicPlayer.seek(position).catchError((_) {});
  }

  @override
  Future<void> skipToNext() async {
    final nextId = (_currentSongId + 1) % ChantConstants.allSongs.length;
    await playSong(nextId);
  }

  @override
  Future<void> skipToPrevious() async {
    final prevId = (_currentSongId - 1 + ChantConstants.allSongs.length) %
        ChantConstants.allSongs.length;
    await playSong(prevId);
  }

  Future<void> togglePlay(int songId) async {
    if (_isPlaying) {
      if (_currentSongId == songId) {
        await pause();
      } else {
        await playSong(songId);
      }
    } else {
      if (_currentSongId == songId && _musicPlayer.state == PlayerState.paused) {
        await play();
      } else {
        await playSong(songId);
      }
    }
  }

  Future<void> setReleaseMode(ReleaseMode mode) async {
    _releaseMode = mode;
    await _musicPlayer.setReleaseMode(mode);
  }

  Future<void> disposePlayer() async {
    await stop();
    await _musicPlayer.dispose();
    await _currentSongController.close();
    await _playStateController.close();
  }
}
