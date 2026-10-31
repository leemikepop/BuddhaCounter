import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/chant_songs.dart';

/// 佛曲媒體播放會話處理器 (整合 Android MediaSession 與 iOS NowPlayingCenter / RemoteCommandCenter)
/// 支援系統通知欄、鎖定畫面、控制中心、動態島、耳機線控 (AirPods) 播放/暫停/上一首/下一首與進度控制
class ChantAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _musicPlayer = AudioPlayer();

  AudioPlayer get musicPlayer => _musicPlayer;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _playRequestId = 0;
  bool _isSwitchingTrack = false;
  bool get isSwitchingTrack => _isSwitchingTrack;

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

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  Stream<Duration> get onPositionChanged => _positionController.stream;

  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  Stream<Duration> get onDurationChanged => _durationController.stream;

  void _setPlayState(bool playing) {
    if (_isPlaying == playing) return;
    _isPlaying = playing;
    if (!_playStateController.isClosed) {
      _playStateController.add(playing);
    }
  }

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _currentDuration = Duration.zero;
  Duration get currentDuration => _currentDuration;

  late final Future<void> _initFuture;

  final Map<int, Future<File>> _inFlightFilePreps = {};

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
        AVAudioSessionOptions.defaultToSpeaker,
      },
    ),
  );

  ChantAudioHandler() {
    _initFuture = _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    // 關鍵效能優化：覆蓋 audioplayers 6.x 預設的 FramePositionUpdater（原本會在 90/120Hz 每一幀跨執行緒呼叫 getCurrentPosition），
    // 改為 250ms 定時更新，大幅降低 Platform MethodChannel 與主執行緒負擔
    _musicPlayer.positionUpdater = TimerPositionUpdater(
      interval: const Duration(milliseconds: 250),
      getPosition: _musicPlayer.getCurrentPosition,
    );

    // 監聽播放器狀態
    _musicPlayer.onPlayerStateChanged.listen((state) {
      if (_isSwitchingTrack && state != PlayerState.playing) {
        // 切歌準備期間忽略底層 MediaPlayer reset/stop 產生的暫態非播放事件，避免誤觸暫停迴圈
        return;
      }
      if (state == PlayerState.completed && _releaseMode == ReleaseMode.loop) {
        // 單曲循環模式下原生底層（iOS WrappedMediaPlayer 及 Android MediaPlayer）會自動無縫銜接重播，
        // 忽略 completed 暫態，避免觸發冗餘的 NowPlayingCenter 廣播或誤切暫停狀態
        return;
      }
      final nextPlaying = (state == PlayerState.playing);
      _setPlayState(nextPlaying);
      _broadcastPlaybackState();
    });

    // 監聽播放進度：Android MediaSession 與 iOS NowPlayingCenter 會依 updatePosition + speed 自動推算系統通知欄進度，
    // 切勿於每次進度更新都呼叫 _broadcastPlaybackState()，否則會造成 Binder/IPC 與主執行緒嚴重阻塞；
    // 僅在單曲循環回到開頭時同步一次系統進度
    _musicPlayer.onPositionChanged.listen((pos) {
      final prev = _currentPosition;
      _currentPosition = pos;
      if (!_positionController.isClosed) {
        _positionController.add(pos);
      }
      if (_isPlaying &&
          prev > const Duration(seconds: 2) &&
          pos < const Duration(milliseconds: 800)) {
        _broadcastPlaybackState();
      }
    });

    // 監聽長度更新
    _musicPlayer.onDurationChanged.listen((dur) {
      if (dur > Duration.zero) {
        _currentDuration = dur;
        if (!_durationController.isClosed) {
          _durationController.add(dur);
        }
        if (mediaItem.value != null) {
          mediaItem.add(mediaItem.value!.copyWith(duration: dur));
        }
      }
    });

    // 監聽播放完成
    _musicPlayer.onPlayerComplete.listen((_) async {
      if (!_isPlaying || _isSwitchingTrack) return;
      if (_releaseMode == ReleaseMode.loop) {
        // 在單曲循環模式下，底層（iOS WrappedMediaPlayer 及 Android MediaPlayer）
        // 原生均已自動無縫執行 seek(0) 並繼續 resume() 播放。
        // 切勿在此重複呼叫 seek(0) 或 resume()，否則在 iOS AVPlayer 上會打斷正在預載的解碼管線，
        // 造成 1~2 秒的卡頓停頓（Stuttering）。
        return;
      } else {
        await skipToNext();
      }
    });

    // 廣播初始佇列 (Queue)
    final queueItems = ChantConstants.allSongs.map((s) {
      return MediaItem(
        id: s.id.toString(),
        album: s.album,
        title: s.title,
        artist: s.artist,
      );
    }).toList();
    queue.add(queueItems);

    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setAudioContext(_musicAudioContext);
    } catch (_) {}
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

  /// 本機檔案預先提取快取管理（純 ASCII 檔名，徹底規避 URI 編碼與 AudioCache 跨平台路徑解析問題）
  Future<File> _prepareSongFile(ChantSong song) async {
    final existing = _inFlightFilePreps[song.id];
    if (existing != null) return existing;

    final future = _extractSongFile(song);
    _inFlightFilePreps[song.id] = future;
    try {
      return await future;
    } finally {
      _inFlightFilePreps.remove(song.id);
    }
  }

  Future<File> _extractSongFile(ChantSong song) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/buddha_chant_cache_v3');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final targetFile = File('${cacheDir.path}/song_${song.id}.ogg');
    if (await targetFile.exists() && (await targetFile.length()) > 0) {
      return targetFile;
    }

    final key = song.assetPath.startsWith('assets/')
        ? song.assetPath
        : 'assets/${song.assetPath}';
    final byteData = await rootBundle.load(key);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    final tmpFile = File('${targetFile.path}.tmp');
    await tmpFile.writeAsBytes(bytes, flush: true);
    await tmpFile.rename(targetFile.path);
    return targetFile;
  }

  /// 播放指定佛曲（具備請求序號防重入、本機檔案快取直讀與狀態回滾保護）
  Future<void> playSong(int songId) async {
    final reqId = ++_playRequestId;
    _isSwitchingTrack = true;
    _setPlayState(true);
    final songChanged = (_currentSongId != songId);
    _currentSongId = songId;
    if (songChanged && !_currentSongController.isClosed) {
      _currentSongController.add(songId);
    }
    _currentPosition = Duration.zero;
    _currentDuration = Duration.zero;
    if (!_positionController.isClosed) {
      _positionController.add(Duration.zero);
    }
    if (!_durationController.isClosed) {
      _durationController.add(Duration.zero);
    }

    final song = ChantConstants.getSongById(songId);
    final item = MediaItem(
      id: songId.toString(),
      album: song.album,
      title: song.title,
      artist: song.artist,
      duration: null,
      displayTitle: song.title,
      displaySubtitle: '${song.artist} · ${song.album}',
      displayDescription: '保持螢幕休眠或退至背景時佛曲持續播放',
    );
    mediaItem.add(item);
    _broadcastPlaybackState();

    try {
      await _initFuture;
      final file = await _prepareSongFile(song);
      if (reqId != _playRequestId || !_isPlaying) return;

      await _musicPlayer.play(
        DeviceFileSource(file.path, mimeType: 'audio/ogg'),
      );
      if (reqId != _playRequestId) return;

      _isSwitchingTrack = false;
      await _musicPlayer.setReleaseMode(_releaseMode).catchError((_) {});
      final dur = await _musicPlayer.getDuration().catchError((_) => null);
      if (reqId != _playRequestId) return;
      if (dur != null && dur > Duration.zero) {
        _currentDuration = dur;
        if (!_durationController.isClosed) {
          _durationController.add(dur);
        }
        if (mediaItem.value != null) {
          mediaItem.add(mediaItem.value!.copyWith(duration: dur));
        }
      }
    } catch (_) {
      if (reqId == _playRequestId) {
        _isSwitchingTrack = false;
        _setPlayState(false);
        _broadcastPlaybackState();
      }
    }
  }

  @override
  Future<void> play() async {
    if (_musicPlayer.state == PlayerState.paused) {
      ++_playRequestId;
      _isSwitchingTrack = false;
      _setPlayState(true);
      _broadcastPlaybackState();
      _musicPlayer.resume().catchError((_) {});
    } else {
      await playSong(_currentSongId);
    }
  }

  @override
  Future<void> pause() async {
    ++_playRequestId;
    _isSwitchingTrack = false;
    _setPlayState(false);
    _broadcastPlaybackState();
    _musicPlayer.pause().catchError((_) {});
  }

  @override
  Future<void> stop() async {
    ++_playRequestId;
    _isSwitchingTrack = false;
    _setPlayState(false);
    _currentPosition = Duration.zero;
    if (!_positionController.isClosed) {
      _positionController.add(Duration.zero);
    }
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
    _currentPosition = position;
    if (!_positionController.isClosed) {
      _positionController.add(position);
    }
    await _musicPlayer.seek(position).catchError((_) {});
    _broadcastPlaybackState();
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
    await _positionController.close();
    await _durationController.close();
  }
}
