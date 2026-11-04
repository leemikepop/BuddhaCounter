import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/chant_songs.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/storage_service.dart';

/// 自動計數模式下，播放器的指令改由自動計數接手：在那裡「播放」就是開始念、
/// 「暫停」就是暫停計數。由 [AutoCountController] 實作並掛到 [PlaybackController.delegate]，
/// 播放器本身不需要知道計數規則。
abstract interface class PlaybackDelegate {
  /// 是否由自動計數接手播放指令 (正在計數，或停在自動計數畫面)
  bool get handlesPlayback;

  /// 是否正在自動計數
  bool get isCounting;

  /// 從頭播放 [songId] 並開始計數
  void startCountingWith(int songId);
  void pauseCounting();
  void resumeCounting();

  /// 使用者拖曳 / 快轉到 [position]
  void onSeek(Duration position);

  /// 系統媒體控制 (通知欄、鎖定畫面) 換了曲目
  void onTrackChangedExternally(ChantSong song);
}

/// 佛曲播放器的狀態與操作：目前曲目、播放 / 暫停、進度、循環模式。
///
/// 進度 ([positionListenable]、[durationListenable]) 走獨立的 ValueNotifier，
/// 只讓進度條重繪；其他狀態變化才呼叫 [notifyListeners]。
class PlaybackController extends ChangeNotifier {
  PlaybackController({
    required AudioService audio,
    required StorageService storage,
  })  : _audio = audio,
        _storage = storage,
        _currentSongId = storage.getLastSongId() {
    _subscriptions = [
      _audio.onDurationChanged.listen((d) => _duration.value = d),
      _audio.onPositionChanged.listen(_onPosition),
      _audio.onPlayerStateChanged.listen(_onPlayerState),
      _audio.onPlayStateChanged.listen(_onPlayStateFromSystem),
      _audio.onCurrentSongChanged.listen(_onSongFromSystem),
    ];
  }

  final AudioService _audio;
  final StorageService _storage;
  late final List<StreamSubscription<Object?>> _subscriptions;

  /// 自動計數掛上的接手者 (見 [PlaybackDelegate])
  PlaybackDelegate? delegate;

  bool get _counting => delegate?.isCounting ?? false;
  bool get _delegated => delegate?.handlesPlayback ?? false;

  int _currentSongId;
  int get currentSongId => _currentSongId;
  ChantSong get currentSong => ChantConstants.getSongById(_currentSongId);

  bool get isPlaying => _audio.isPlaying;

  ReleaseMode get releaseMode => _audio.releaseMode;
  bool get isLoopingOne => releaseMode == ReleaseMode.loop;

  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _duration = ValueNotifier(Duration.zero);
  ValueListenable<Duration> get positionListenable => _position;
  ValueListenable<Duration> get durationListenable => _duration;
  Duration get position => _position.value;
  Duration get duration => _duration.value;

  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast();

  /// 播放器回報的進度 (拖曳進度條期間不送)，供自動計數判斷節拍
  Stream<Duration> get positions => _positions.stream;

  bool _isScrubbing = false;

  /// 是否正在拖曳進度條 (期間忽略播放器進度，避免誤算節拍)
  bool get isScrubbing => _isScrubbing;

  // --- 使用者操作 ---

  /// 只選曲不播放 (經典模式自動計數頁的下拉選單)；正在計數時直接換曲重新開始
  void selectSong(int songId) {
    if (_counting) {
      delegate!.startCountingWith(songId);
      return;
    }
    _setCurrentSong(songId);
    _resetProgress();
    notifyListeners();
  }

  /// 選曲並從頭播放；自動計數模式下改為換曲重新開始計數
  void selectAndPlaySong(int songId) {
    if (_delegated) {
      delegate!.startCountingWith(songId);
    } else {
      playFromStart(songId);
    }
  }

  /// 清單與播放鍵的播放 / 暫停：點到其他曲目就改播那首
  void toggleChant(int songId) {
    if (songId != _currentSongId) {
      selectAndPlaySong(songId);
      return;
    }
    if (_counting) {
      delegate!.pauseCounting();
    } else if (isPlaying) {
      pause();
    } else if (_delegated) {
      delegate!.resumeCounting();
    } else {
      playFromStart(songId);
    }
  }

  /// 經典首頁「念佛」鍵：播放 / 暫停目前曲目 (不會啟動自動計數)
  Future<void> togglePlayPause() async {
    if (_counting) {
      delegate!.pauseCounting();
      return;
    }
    await _audio.toggleChantPlay(_currentSongId);
    notifyListeners();
  }

  void playNextSong() =>
      selectAndPlaySong((_currentSongId + 1) % ChantConstants.allSongs.length);

  void playPreviousSong() {
    final total = ChantConstants.allSongs.length;
    selectAndPlaySong((_currentSongId - 1 + total) % total);
  }

  void beginScrubbing() => _isScrubbing = true;

  void endScrubbing(Duration position) {
    _isScrubbing = false;
    seek(position);
  }

  void seek(Duration position) {
    _audio.seek(position);
    _position.value = position;
    delegate?.onSeek(position);
  }

  /// 前進 / 倒退幾秒 (限制在曲目範圍內)
  void seekRelative(int seconds) {
    var target = position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    seek(target);
  }

  /// 單曲循環 ⇄ 清單播放
  void toggleLoopMode() {
    _audio.setReleaseMode(isLoopingOne ? ReleaseMode.stop : ReleaseMode.loop);
    notifyListeners();
  }

  // --- 低階播放 (自動計數與經典念佛頁使用) ---

  /// 切到 [songId] 並從頭播放
  void playFromStart(int songId) {
    _setCurrentSong(songId);
    _resetProgress();
    _audio.playChant(songId);
    notifyListeners();
  }

  /// 從頭重播目前曲目 (不重設時長，避免進度條閃動)
  void restartCurrent() {
    _position.value = Duration.zero;
    _audio.playChant(_currentSongId);
    notifyListeners();
  }

  void pause() {
    _audio.pauseChant();
    notifyListeners();
  }

  void resume() {
    _audio.resumeChant();
    notifyListeners();
  }

  void stop() {
    _audio.stopChant();
    notifyListeners();
  }

  /// 直接向播放器查詢目前位置 (進度推播中斷時的備援)，同時更新進度條
  Future<Duration?> pollPosition() async {
    final pos = await _audio.getCurrentPosition();
    if (pos != null && !_isScrubbing) _position.value = pos;
    return pos;
  }

  void resetPosition() => _position.value = Duration.zero;

  // --- 播放器事件 ---

  void _onPosition(Duration pos) {
    if (_isScrubbing) return;
    _position.value = pos;
    _positions.add(pos);
  }

  void _onPlayerState(PlayerState state) {
    if (_audio.handler.isSwitchingTrack) return;
    // 單曲循環時的 completed 只是暫態，不重繪
    if (state == PlayerState.completed && isLoopingOne) return;
    if (state == PlayerState.paused && _counting && !isPlaying) {
      delegate!.pauseCounting();
    } else {
      notifyListeners();
    }
  }

  /// 系統媒體控制 (通知欄、鎖定畫面、耳機線控、音訊焦點) 改變播放狀態
  void _onPlayStateFromSystem(bool playing) {
    // 落後於目前真實狀態的舊事件 (例如切歌瞬間的 false) 直接忽略，避免暫停 / 播放來回觸發
    if (playing != isPlaying) return;
    if (!playing && _counting) {
      delegate!.pauseCounting();
    } else if (playing && _delegated && !_counting) {
      delegate!.resumeCounting();
    } else {
      notifyListeners();
    }
  }

  void _onSongFromSystem(int songId) {
    if (songId == _currentSongId) return;
    _setCurrentSong(songId);
    if (_counting) {
      _resetProgress();
      delegate!.onTrackChangedExternally(currentSong);
    }
    notifyListeners();
  }

  void _setCurrentSong(int songId) {
    _currentSongId = songId;
    _storage.setLastSongId(songId);
  }

  void _resetProgress() {
    _position.value = Duration.zero;
    _duration.value = Duration.zero;
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _positions.close();
    _position.dispose();
    _duration.dispose();
    _audio.dispose();
    super.dispose();
  }
}
