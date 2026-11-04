import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../l10n/app_language.dart';
import '../../l10n/generated/app_localizations.dart';
import '../constants/chant_songs.dart';
import 'chant_music_engine.dart';
import 'ios_loop_chant_engine.dart';

/// 佛曲媒體播放會話處理器 (整合 Android MediaSession 與 iOS NowPlayingCenter / RemoteCommandCenter)
/// 支援系統通知欄、鎖定畫面、控制中心、動態島、耳機線控 (AirPods) 播放/暫停/上一首/下一首與進度控制
///
/// 實際發聲交給 [ChantMusicEngine]：iOS 用原生 AVPlayerLooper (無縫循環)，Android 用 audioplayers。
class ChantAudioHandler extends BaseAudioHandler with SeekHandler {
  final ChantMusicEngine _engine;

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

  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  Stream<PlayerState> get onPlayerStateChanged => _playerStateController.stream;

  final StreamController<void> _playerCompleteController =
      StreamController<void>.broadcast();
  Stream<void> get onPlayerComplete => _playerCompleteController.stream;

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

  /// 佛曲播放的音訊設定。
  ///
  /// iOS：整個 App 只有一份 AVAudioSession (audioplayers 對單一播放器的設定也會覆蓋全域)，
  /// 因此只在 [configureIosAudioSession] 設定一次。必須是「playback 且不混音」：
  /// - `mixWithOthers` 會讓 iOS 不把 App 視為 Now Playing → 控制中心 / 鎖定畫面不顯示播放控制
  /// - `defaultToSpeaker` 只能搭配 playAndRecord，搭配 playback 會讓整組設定失敗
  ///
  /// Android：每個播放器各自設定，佛曲取得音訊焦點 (gain) 並保持喚醒。
  static final AudioContext musicAudioContext = AudioContext(
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

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// 設定 iOS 全域音訊 session (僅一次，唯一的設定點)
  static Future<void> configureIosAudioSession() async {
    if (!_isIOS) return;
    try {
      await AudioPlayer.global.setAudioContext(musicAudioContext);
    } catch (e) {
      debugPrint('ChantAudioHandler: iOS audio session setup failed: $e');
    }
  }

  Timer? _positionTimer;

  /// 系統通知欄 / 鎖定畫面文字使用的翻譯
  AppLocalizations _l10n = lookupAppLocalizations(kZhHant);

  MediaItem _queueItemFor(ChantSong s) => MediaItem(
        id: s.id.toString(),
        album: s.album,
        title: s.title,
        artist: s.artist,
      );

  MediaItem _mediaItemFor(ChantSong song, {Duration? duration}) => MediaItem(
        id: song.id.toString(),
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: duration,
        displayTitle: song.title,
        displaySubtitle: _l10n.mediaSubtitle(song.artist, song.album),
        displayDescription: _l10n.audioChannelDesc,
      );

  /// 語言變更時重建佇列與目前曲目的系統媒體資訊 (不影響播放狀態)
  void refreshMediaItems(AppLocalizations l10n) {
    _l10n = l10n;
    queue.add(ChantConstants.allSongs.map(_queueItemFor).toList());
    final current = mediaItem.value;
    final id = current == null ? null : int.tryParse(current.id);
    if (id != null) {
      mediaItem.add(_mediaItemFor(
        ChantConstants.getSongById(id),
        duration: current!.duration,
      ));
    }
  }

  ChantAudioHandler({ChantMusicEngine? engine})
      : _engine = engine ??
            (_isIOS
                ? IosLoopChantEngine()
                : AudioplayersChantEngine(audioContext: musicAudioContext)) {
    _initFuture = _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _engine.onStateChanged.listen(_onEngineState);
    _engine.onDurationChanged.listen(_onEngineDuration);
    _engine.onComplete.listen((_) => _onEngineComplete());

    // 廣播初始佇列 (Queue)
    final queueItems = ChantConstants.allSongs.map(_queueItemFor).toList();
    queue.add(queueItems);

    try {
      await configureIosAudioSession();
      await _engine.init();
    } catch (e) {
      debugPrint('ChantAudioHandler: player setup failed: $e');
    }
  }

  // 進度以 250ms 定時查詢 (不逐幀跨執行緒呼叫)，系統通知欄 / 鎖定畫面會依 updatePosition + speed 自行推算
  void _startPositionTicker() {
    _positionTimer ??= Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _pollPosition(),
    );
  }

  void _stopPositionTicker() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> _pollPosition() async {
    final pos = await _engine.getPosition().catchError((_) => null);
    if (pos == null || _positionTimer == null) return;
    final prev = _currentPosition;
    _currentPosition = pos;
    if (!_positionController.isClosed) {
      _positionController.add(pos);
    }
    // 切勿每次進度更新都廣播 (會造成 IPC 與主執行緒阻塞)；僅在單曲循環回到開頭時同步一次系統進度
    if (_isPlaying &&
        prev > const Duration(seconds: 2) &&
        pos < const Duration(milliseconds: 800)) {
      _broadcastPlaybackState();
    }
  }

  void _onEngineState(PlayerState state) {
    if (!_playerStateController.isClosed) {
      _playerStateController.add(state);
    }
    if (_isSwitchingTrack && state != PlayerState.playing) {
      // 切歌準備期間忽略底層 reset/stop 產生的暫態非播放事件，避免誤觸暫停迴圈
      return;
    }
    if (state == PlayerState.completed && _releaseMode == ReleaseMode.loop) {
      // 單曲循環由引擎原生接回開頭，completed 只是暫態
      return;
    }
    _setPlayState(state == PlayerState.playing);
    _broadcastPlaybackState();
  }

  void _onEngineDuration(Duration dur) {
    if (dur <= Duration.zero) return;
    _currentDuration = dur;
    if (!_durationController.isClosed) {
      _durationController.add(dur);
    }
    if (mediaItem.value != null) {
      mediaItem.add(mediaItem.value!.copyWith(duration: dur));
    }
  }

  Future<void> _onEngineComplete() async {
    if (!_playerCompleteController.isClosed) {
      _playerCompleteController.add(null);
    }
    if (!_isPlaying || _isSwitchingTrack) return;
    // 單曲循環由引擎原生處理，切勿在此 seek(0) / resume()，否則會打斷音訊管線造成停頓
    if (_releaseMode == ReleaseMode.loop) return;
    await skipToNext();
  }

  void _broadcastPlaybackState() {
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
        processingState: AudioProcessingState.ready,
        playing: _isPlaying,
        updatePosition: _currentPosition,
        bufferedPosition: _currentPosition,
        speed: _isPlaying ? 1.0 : 0.0,
      ),
    );
  }

  /// 把佛曲從 assets 解到暫存資料夾再播放 (檔名只用 ASCII，避開中文路徑的 URI 編碼問題)；
  /// 同一首同時只解一次
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

  /// 從頭播放指定佛曲。連續快速切歌時只有最後一次請求生效 (請求序號)，載入失敗時還原播放狀態
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
    final item = _mediaItemFor(song);
    mediaItem.add(item);
    _broadcastPlaybackState();

    try {
      await _initFuture;
      final file = await _prepareSongFile(song);
      if (reqId != _playRequestId || !_isPlaying) return;

      await _engine.playFile(file.path,
          looping: _releaseMode == ReleaseMode.loop);
      if (reqId != _playRequestId) return;

      _isSwitchingTrack = false;
      _startPositionTicker();
      final dur = await _engine.getDuration().catchError((_) => null);
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
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.media:
        if (_isPlaying) {
          await pause();
        } else {
          await play();
        }
        break;
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
    }
  }

  @override
  Future<void> play() async {
    ++_playRequestId;
    _isSwitchingTrack = false;
    _setPlayState(true);
    _broadcastPlaybackState();
    if (_engine.state == PlayerState.paused) {
      _startPositionTicker();
      await _engine.resume().catchError((_) {});
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
    _stopPositionTicker();
    await _engine.pause().catchError((_) {});
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
    _stopPositionTicker();
    await _engine.stop().catchError((_) {});
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 0.0,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    _currentPosition = position;
    if (!_positionController.isClosed) {
      _positionController.add(position);
    }
    await _engine.seek(position).catchError((_) {});
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
      if (_currentSongId == songId && _engine.state == PlayerState.paused) {
        await play();
      } else {
        await playSong(songId);
      }
    }
  }

  Future<void> setReleaseMode(ReleaseMode mode) async {
    _releaseMode = mode;
    await _engine.setLooping(mode == ReleaseMode.loop);
  }

  Future<Duration?> getCurrentPosition() => _engine.getPosition();

  Future<Duration?> getDuration() => _engine.getDuration();

  Future<void> disposePlayer() async {
    await stop();
    await _engine.dispose();
    await _currentSongController.close();
    await _playStateController.close();
    await _positionController.close();
    await _durationController.close();
    await _playerStateController.close();
    await _playerCompleteController.close();
  }
}
