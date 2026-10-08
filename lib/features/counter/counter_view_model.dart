import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/storage_service.dart';

class CounterViewModel extends ChangeNotifier {
  final StorageService _storage;
  final AudioService _audio;

  int _count = 0;
  int get count => _count;

  // 計時器
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool get isTimerRunning => _isTimerRunning;

  // 自動計數
  Timer? _autoCountTimer;
  int _autoCount = 0;
  int get autoCount => _autoCount;
  bool _isAutoCounting = false;
  bool get isAutoCounting => _isAutoCounting;
  int _autoElapsedSeconds = 0;
  int _autoStopMinutes = 0;
  int get autoStopMinutes => _autoStopMinutes;

  // 設定與模式
  SoundEffectType _soundEffect;
  SoundEffectType get soundEffect => _soundEffect;

  AppUiMode _uiMode;
  AppUiMode get uiMode => _uiMode;

  bool _keepScreenHome = false;
  bool get keepScreenHome => _keepScreenHome;

  bool _keepScreenChant = false;
  bool get keepScreenChant => _keepScreenChant;

  bool _keepScreenSongs = false;
  bool get keepScreenSongs => _keepScreenSongs;

  bool _keepScreenAuto = false;
  bool get keepScreenAuto => _keepScreenAuto;

  int _currentSongId = 1;
  int get currentSongId => _currentSongId;

  AudioService get audioService => _audio;

  CounterViewModel({
    required StorageService storage,
    required AudioService audio,
  })  : _storage = storage,
        _audio = audio,
        _soundEffect = storage.getSoundEffect(),
        _uiMode = storage.getUiMode() {
    _count = _storage.getCounter();
    _currentSongId = _storage.getLastSongId();
    _keepScreenHome = _storage.getKeepScreenOnHome();
    _keepScreenChant = _storage.getKeepScreenOnChant();
    _keepScreenSongs = _storage.getKeepScreenOnSongs();
    _keepScreenAuto = _storage.getKeepScreenOnAuto();
  }

  // --- 手動計數 ---
  void increment() {
    _count++;
    _storage.setCounter(_count);
    _audio.playClickSfx(_soundEffect);
    notifyListeners();
  }

  void decrement() {
    if (_count > 0) {
      _count--;
      _storage.setCounter(_count);
      notifyListeners();
    }
  }

  void resetCount() {
    _count = 0;
    _storage.setCounter(_count);
    notifyListeners();
  }

  // --- 主頁計時器 ---
  String get formattedTimer {
    final h = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void startTimer() {
    if (_isTimerRunning) return;
    _isTimerRunning = true;
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void stopTimer() {
    _isTimerRunning = false;
    _stopwatchTimer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _isTimerRunning = false;
    _stopwatchTimer?.cancel();
    _elapsedSeconds = 0;
    notifyListeners();
  }

  // --- 自動計數（對應原 Main6Activity） ---
  String get formattedAutoTimer {
    final h = (_autoElapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_autoElapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_autoElapsedSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void setAutoStopMinutes(int mins) {
    _autoStopMinutes = mins;
    notifyListeners();
  }

  void startAutoCount({Duration interval = const Duration(seconds: 2)}) {
    if (_isAutoCounting) return;
    _isAutoCounting = true;
    _audio.playChant(_currentSongId);

    _autoCountTimer = Timer.periodic(interval, (timer) {
      _autoCount++;
      _autoElapsedSeconds += interval.inSeconds;

      // 檢查定時關閉
      if (_autoStopMinutes > 0 &&
          _autoElapsedSeconds >= _autoStopMinutes * 60) {
        stopAutoCount();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void stopAutoCount() {
    _isAutoCounting = false;
    _autoCountTimer?.cancel();
    _audio.stopChant();
    notifyListeners();
  }

  void resetAutoCount() {
    stopAutoCount();
    _autoCount = 0;
    _autoElapsedSeconds = 0;
    notifyListeners();
  }

  // --- 佛曲播放 ---
  void selectAndPlaySong(int songId) {
    _currentSongId = songId;
    _storage.setLastSongId(songId);
    _audio.playChant(songId);
    notifyListeners();
  }

  void toggleChant(int songId) {
    _currentSongId = songId;
    _storage.setLastSongId(songId);
    _audio.toggleChantPlay(songId);
    notifyListeners();
  }

  // --- 設定與防休眠 ---
  void setSoundEffect(SoundEffectType type) {
    _soundEffect = type;
    _storage.setSoundEffect(type);
    notifyListeners();
  }

  void setUiMode(AppUiMode mode) {
    _uiMode = mode;
    _storage.setUiMode(mode);
    notifyListeners();
  }

  void setKeepScreenHome(bool val) {
    _keepScreenHome = val;
    _storage.setKeepScreenOnHome(val);
    _updateWakelock(val);
    notifyListeners();
  }

  void setKeepScreenChant(bool val) {
    _keepScreenChant = val;
    _storage.setKeepScreenOnChant(val);
    notifyListeners();
  }

  void setKeepScreenSongs(bool val) {
    _keepScreenSongs = val;
    _storage.setKeepScreenOnSongs(val);
    notifyListeners();
  }

  void setKeepScreenAuto(bool val) {
    _keepScreenAuto = val;
    _storage.setKeepScreenOnAuto(val);
    notifyListeners();
  }

  void applyScreenWakelockForCurrentPage(bool enable) {
    _updateWakelock(enable);
  }

  void _updateWakelock(bool enable) {
    try {
      if (enable) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _autoCountTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }
}
