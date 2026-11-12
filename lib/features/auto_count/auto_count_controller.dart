import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/constants/chant_songs.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/time_format.dart';
import '../playback/playback_controller.dart';
import '../practice/practice_controller.dart';
import 'beat_tracker.dart';

/// 自動計數：播放佛曲，依進度 ([BeatTracker]) 自動累加聲數。
///
/// - 停止條件二擇一：念滿 [targetCount] 聲，或計時滿 [stopMinutes] 分鐘 (0 = 不限)。
/// - 在自動計數畫面上，播放器的播放 / 暫停就等於開始 / 暫停計數 (見 [PlaybackDelegate])。
/// - 聲數本身記在 [PracticeController.autoCount]，同時加到功課月曆當天的紀錄。
class AutoCountController extends ChangeNotifier implements PlaybackDelegate {
  AutoCountController({
    required PlaybackController playback,
    required PracticeController practice,
    required StorageService storage,
  })  : _playback = playback,
        _practice = practice,
        _storage = storage,
        _elapsedSeconds = storage.getAutoElapsedSeconds(),
        _stopMinutes = storage.getAutoStopMinutes(),
        _targetCount = storage.getAutoTargetCount(),
        _tracker = BeatTracker(playback.currentSong) {
    // 兩個停止條件理論上不會同時存在；萬一有，以既有的定時停止為準
    if (_targetCount > 0 && _stopMinutes > 0) {
      _targetCount = 0;
      _storage.setAutoTargetCount(0);
    }
    _playback.delegate = this;
    _positionSubscription = _playback.positions.listen(_onPosition);
  }

  /// 超過這麼久沒收到進度推播，就主動向播放器查詢位置
  static const Duration pollInterval = Duration(milliseconds: 300);

  final PlaybackController _playback;
  final PracticeController _practice;
  final StorageService _storage;
  final BeatTracker _tracker;
  late final StreamSubscription<Duration> _positionSubscription;

  Timer? _elapsedTimer;
  Timer? _pollTimer;
  int _lastPositionAtMs = 0;

  bool _isCounting = false;
  @override
  bool get isCounting => _isCounting;

  bool _isScreenVisible = false;

  /// 自動計數畫面是否正在顯示 (現代模式的自動計數分頁、經典模式的自動計數頁)
  bool get isScreenVisible => _isScreenVisible;

  /// 進出自動計數畫面時呼叫 (不重繪：只影響播放鍵按下去的行為)
  void setScreenVisible(bool visible) => _isScreenVisible = visible;

  @override
  bool get handlesPlayback => _isCounting || _isScreenVisible;

  int _elapsedSeconds;
  int get elapsedSeconds => _elapsedSeconds;
  String get formattedElapsed => formatHms(_elapsedSeconds);

  // --- 停止條件 ---

  int _stopMinutes;

  /// 定時停止的分鐘數 (0 = 不限)
  int get stopMinutes => _stopMinutes;

  int _targetCount;

  /// 念滿幾聲自動停止 (0 = 不限)
  int get targetCount => _targetCount;

  double get targetProgress => _targetCount > 0
      ? (_practice.autoCount / _targetCount).clamp(0.0, 1.0)
      : 0.0;
  bool get isTargetReached =>
      _targetCount > 0 && _practice.autoCount >= _targetCount;

  /// 定時停止已經過的比例 (0.0 → 1.0)
  double get stopElapsedProgress => _stopMinutes > 0
      ? (_elapsedSeconds / (_stopMinutes * 60)).clamp(0.0, 1.0)
      : 0.0;

  /// 定時停止剩餘秒數 (未設定時為 0)
  int get stopRemainingSeconds {
    if (_stopMinutes <= 0) return 0;
    final remaining = _stopMinutes * 60 - _elapsedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  /// 設定定時停止；大於 0 時清掉聲數目標 (兩者互斥)
  void setStopMinutes(int minutes) {
    _stopMinutes = minutes;
    _storage.setAutoStopMinutes(minutes);
    if (minutes > 0 && _targetCount != 0) _setTargetCount(0);
    notifyListeners();
  }

  /// 設定聲數目標；大於 0 時清掉定時停止 (兩者互斥)
  void setTargetCount(int value) {
    _setTargetCount(value);
    if (value > 0 && _stopMinutes != 0) {
      _stopMinutes = 0;
      _storage.setAutoStopMinutes(0);
    }
    notifyListeners();
  }

  /// 不設停止條件，一直念下去
  void clearStopCondition() {
    _setTargetCount(0);
    _stopMinutes = 0;
    _storage.setAutoStopMinutes(0);
    notifyListeners();
  }

  void _setTargetCount(int value) {
    _targetCount = value;
    _storage.setAutoTargetCount(value);
  }

  // --- 經典模式的音訊位置顯示 ---

  bool _showAudioPosition = false;

  /// 經典自動計數頁是否顯示「音訊 時長 : 位置」
  bool get showAudioPosition => _showAudioPosition;

  void toggleShowAudioPosition() {
    _showAudioPosition = !_showAudioPosition;
    notifyListeners();
  }

  // --- 開始 / 暫停 / 停止 ---

  /// 從頭開始念目前曲目
  void start() => _resume(fromBeginning: true);

  void toggle() => _isCounting ? pause() : _resume();

  /// 暫停計數與播放 (保留聲數與計時)
  void pause() {
    if (!_isCounting) return;
    _stopSession();
    _playback.pause();
    notifyListeners();
  }

  /// 停止計數與播放
  void stop() {
    _stopSession();
    _playback.stop();
    notifyListeners();
  }

  /// 只把計時歸零 (聲數不變)
  void resetElapsed() {
    _setElapsed(0);
    notifyListeners();
  }

  /// 停止並把聲數與計時都歸零
  void resetAll() {
    stop();
    _practice.resetAutoCount();
    _setElapsed(0);
    _playback.resetPosition();
    notifyListeners();
  }

  void _resume({bool fromBeginning = false}) {
    if (_isCounting) return;
    _isCounting = true;
    final song = _playback.currentSong;
    if (fromBeginning || _playback.position == Duration.zero) {
      _tracker.restart(song);
      _playback.restartCurrent();
    } else {
      _tracker.alignTo(_playback.position.inMilliseconds, song: song);
      if (!_playback.isPlaying) _playback.resume();
    }
    _startTimers();
    notifyListeners();
  }

  void _stopSession() {
    _isCounting = false;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _startTimers() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isCounting) return;
      _setElapsed(_elapsedSeconds + 1);
      if (_stopMinutes > 0 && _elapsedSeconds >= _stopMinutes * 60) stop();
      notifyListeners();
    });

    // 備援：進度推播中斷超過 pollInterval 時才主動查詢，平常不額外佔用平台通道
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) async {
      if (!_isCounting || _playback.isScrubbing) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastPositionAtMs < pollInterval.inMilliseconds) return;
      final pos = await _playback.pollPosition();
      if (pos != null && _isCounting && !_playback.isScrubbing) {
        _countBeats(pos);
      }
    });
  }

  void _setElapsed(int seconds) {
    _elapsedSeconds = seconds;
    _storage.setAutoElapsedSeconds(seconds);
  }

  // --- 節拍 ---

  void _onPosition(Duration pos) {
    _lastPositionAtMs = DateTime.now().millisecondsSinceEpoch;
    if (_isCounting) _countBeats(pos);
  }

  void _countBeats(Duration pos) {
    _lastPositionAtMs = DateTime.now().millisecondsSinceEpoch;
    final count = _practice.autoCount;
    // 還沒念滿目標時，最多只算到剛好念滿；已念滿後按開始繼續念則不設上限
    final remaining =
        _targetCount > 0 && count < _targetCount ? _targetCount - count : null;
    final beats = _tracker.advance(pos.inMilliseconds, maxBeats: remaining);
    _practice.addAutoBeats(beats);
    if (remaining != null && beats >= remaining) stop();
  }

  // --- PlaybackDelegate ---

  @override
  void startCountingWith(int songId) {
    _playback.playFromStart(songId);
    _isCounting = true;
    _tracker.restart(_playback.currentSong);
    _startTimers();
    notifyListeners();
  }

  @override
  void pauseCounting() => pause();

  @override
  void resumeCounting() => _resume();

  @override
  void onSeek(Duration position) {
    if (_isCounting) _tracker.alignTo(position.inMilliseconds);
  }

  @override
  void onTrackChangedExternally(ChantSong song) => _tracker.restart(song);

  @override
  void dispose() {
    _stopSession();
    _positionSubscription.cancel();
    if (identical(_playback.delegate, this)) _playback.delegate = null;
    super.dispose();
  }
}
