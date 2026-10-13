import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/constants/chant_songs.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/storage_service.dart';

class CounterViewModel extends ChangeNotifier {
  final StorageService _storage;
  final AudioService _audio;

  int _count = 0;
  int get count => _count;

  // 主頁計時器
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool get isTimerRunning => _isTimerRunning;

  // 自動計數（忠實對應原 Android Main6Activity）
  Timer? _autoElapsedTimer;      // 每 1 秒計時一次 (autoTsec++)
  Timer? _autoBeatPollingTimer;   // 每 100ms 輪詢音訊位置 (對應原 Timer scheduleAtFixedRate 100ms)
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _completeSubscription;
  StreamSubscription<int>? _currentSongSubscription;

  int _autoCount = 0;
  int get autoCount => _autoCount;

  bool _isAutoCounting = false;
  bool get isAutoCounting => _isAutoCounting;

  int _autoElapsedSeconds = 0;
  int _autoStopMinutes = 0;
  int get autoStopMinutes => _autoStopMinutes;

  // 音訊位置與時長狀態（對應原 Main6Activity 的 showVoice / vFlag）
  bool _showAudioPosition = false;
  bool get showAudioPosition => _showAudioPosition;

  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  Duration get audioPosition => _audioPosition;
  Duration get audioDuration => _audioDuration;

  // 節拍目標位置（毫秒，對應原版 ss = bb）
  int _targetNextBeatMs = 0;
  int _lastPositionMs = 0;
  bool _isWaitingForAudioRestart = false;
  bool _isAudioStarting = false;
  int _lastProgressNotifyMs = 0;
  int _lastPositionUpdateTimestamp = 0;

  // 當前活躍視圖分頁索引 (現代模式：0手動, 1自動, 2迴向) 與經典模式標記
  int _activeTabIndex = 0;
  int get activeTabIndex => _activeTabIndex;

  bool _isInLegacyAutoCountScreen = false;
  bool get isInLegacyAutoCountScreen => _isInLegacyAutoCountScreen;

  /// 判斷目前是否處於【自動計數模式】
  /// 1. 自動計數正在進行中 (即使短暫切換分頁，背景仍屬於自動計數狀態)
  /// 2. 處於現代模式的【自動計數】分頁 (Tab index 1)
  /// 3. 處於經典模式的【念佛自動計數】頁面 (LegacyAutoCountScreen)
  bool get isInAutoCountMode {
    if (_isAutoCounting) return true;
    if (_uiMode == AppUiMode.modern && _activeTabIndex == 1) return true;
    if (_uiMode == AppUiMode.legacy && _isInLegacyAutoCountScreen) return true;
    return false;
  }

  void setActiveTabIndex(int index) {
    if (_activeTabIndex == index) return;
    _activeTabIndex = index;
    // 解耦與同步各分頁獨立的防休眠策略
    if (_activeTabIndex == 0) {
      applyScreenWakelockForCurrentPage(_keepScreenHome);
    } else if (_activeTabIndex == 1) {
      applyScreenWakelockForCurrentPage(_keepScreenAuto);
    } else if (_activeTabIndex == 2) {
      applyScreenWakelockForCurrentPage(_keepScreenChant);
    }
    notifyListeners();
  }

  void setIsInLegacyAutoCountScreen(bool val) {
    if (_isInLegacyAutoCountScreen == val) return;
    _isInLegacyAutoCountScreen = val;
    notifyListeners();
  }

  // 設定與模式
  SoundEffectType _soundEffect;
  SoundEffectType get soundEffect => _soundEffect;

  AppUiMode _uiMode;
  AppUiMode get uiMode => _uiMode;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool _vibrationEnabled = true;
  bool get vibrationEnabled => _vibrationEnabled;

  int _targetCount = 108;
  int get targetCount => _targetCount;
  double get targetProgress => _targetCount > 0 ? (_count / _targetCount).clamp(0.0, 1.0) : 0.0;

  bool _fullscreenTap = false;
  bool get fullscreenTap => _fullscreenTap;

  bool _keepScreenHome = false;
  bool get keepScreenHome => _keepScreenHome;

  bool _keepScreenChant = false;
  bool get keepScreenChant => _keepScreenChant;

  bool _keepScreenSongs = false;
  bool get keepScreenSongs => _keepScreenSongs;

  bool _keepScreenAuto = false;
  bool get keepScreenAuto => _keepScreenAuto;

  bool _isOrientationLocked = false;
  bool get isOrientationLocked => _isOrientationLocked;

  bool _hasSeenModernGuide = false;
  bool get hasSeenModernGuide => _hasSeenModernGuide;

  int _currentSongId = 0;
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
    _autoCount = _storage.getAutoCounter();
    _autoElapsedSeconds = _storage.getAutoElapsedSeconds();
    _autoStopMinutes = _storage.getAutoStopMinutes();

    _keepScreenHome = _storage.getKeepScreenOnHome();
    _keepScreenChant = _storage.getKeepScreenOnChant();
    _keepScreenSongs = _storage.getKeepScreenOnSongs();
    _keepScreenAuto = _storage.getKeepScreenOnAuto();

    _isOrientationLocked = _storage.getOrientationLocked();
    if (_isOrientationLocked) {
      _applyOrientationLock();
    }

    final tmStr = _storage.getThemeMode();
    _themeMode = tmStr == 'dark'
        ? ThemeMode.dark
        : (tmStr == 'system' ? ThemeMode.system : ThemeMode.light);
    _vibrationEnabled = _storage.getVibrationEnabled();
    _targetCount = _storage.getTargetCount();
    _fullscreenTap = _storage.getFullscreenTap();
    _hasSeenModernGuide = _storage.getSeenModernGuide();

    // 監聽音訊時長變化
    _durationSubscription = _audio.onDurationChanged.listen((dur) {
      _audioDuration = dur;
      notifyListeners();
    });

    // 監聽播放進度推播 (節流優化：每 200ms 最多通知一次，消弭高頻重繪造成的掉幀與滑動卡頓)
    _positionSubscription = _audio.onPositionChanged.listen((pos) {
      _audioPosition = pos;
      _lastPositionUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
      if (_isAutoCounting) {
        final song = ChantConstants.getSongById(_currentSongId);
        _processAudioPosition(pos, song.beatIntervalMs);
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastProgressNotifyMs >= 200) {
          _lastProgressNotifyMs = now;
          notifyListeners();
        }
      }
    });

    // 監聽播放狀態變化（用以即時更新首頁念佛按鈕顏色等）
    _playerStateSubscription = _audio.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _isAudioStarting = false;
      } else if (state == PlayerState.paused && _isAutoCounting && !_isAudioStarting) {
        // 系統音訊焦點丟失、耳機拔除或外部暫停時，自動同步暫停自動計數與計時碼表
        pauseAutoCount();
      }
      notifyListeners();
    });

    // 監聽播放完成（浮動播放器非單曲循環時自動播放下一首）
    _completeSubscription = _audio.onPlayerComplete.listen((_) {
      if (_audio.releaseMode != ReleaseMode.loop) {
        playNextSong();
      }
    });

    // 監聽外部（系統通知欄/鎖定螢幕）切換曲目事件
    _currentSongSubscription = _audio.onCurrentSongChanged.listen((songId) {
      if (_currentSongId != songId) {
        _currentSongId = songId;
        _storage.setLastSongId(songId);
        notifyListeners();
      }
    });
  }

  bool get isChantPlaying => _audio.isPlaying;

  // --- 手動計數 ---
  void increment() {
    _count++;
    _storage.setCounter(_count);
    _audio.playClickSfx(_soundEffect);
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    notifyListeners();
  }

  void decrement() {
    if (_count > 0) {
      _count--;
      _storage.setCounter(_count);
      if (_vibrationEnabled) {
        HapticFeedback.selectionClick();
      }
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

  int get autoElapsedSeconds => _autoElapsedSeconds;

  String get formattedAutoTimer {
    final h = (_autoElapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_autoElapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_autoElapsedSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formattedAudioPosition {
    if (!_showAudioPosition) return '0.0 : 0.0';
    final durSec = (_audioDuration.inMilliseconds / 1000).toStringAsFixed(1);
    final posSec = (_audioPosition.inMilliseconds / 1000).toStringAsFixed(1);
    return '$durSec : $posSec';
  }

  void toggleShowAudioPosition() {
    _showAudioPosition = !_showAudioPosition;
    notifyListeners();
  }

  void setAutoStopMinutes(int mins) {
    _autoStopMinutes = mins;
    _storage.setAutoStopMinutes(mins);
    notifyListeners();
  }

  /// 定時停止剩餘進度比例 (1.0 倒數至 0.0)
  double get autoStopProgress {
    if (_autoStopMinutes <= 0) return 0.0;
    final totalSeconds = _autoStopMinutes * 60;
    final remainingSeconds = totalSeconds - _autoElapsedSeconds;
    if (remainingSeconds <= 0) return 0.0;
    return (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  /// 啟動自動計數與佛曲播放
  void startAutoCount() {
    resumeOrStartAutoCount(fromBeginning: true);
  }

  /// 恢復或啟動自動計數與佛曲播放
  void resumeOrStartAutoCount({bool fromBeginning = false}) {
    if (_isAutoCounting) return;
    _isAutoCounting = true;
    _isAudioStarting = true;

    final song = ChantConstants.getSongById(_currentSongId);
    final bb = song.beatIntervalMs;

    if (fromBeginning || _audioPosition == Duration.zero) {
      _targetNextBeatMs = bb;
      _lastPositionMs = 0;
      _isWaitingForAudioRestart = true;

      // 重設音訊至開頭並播放，保證計數與佛曲旋律精準同步，避免從非零跳計
      _audio.seek(Duration.zero);
      _audio.playChant(_currentSongId);
    } else {
      // 從目前暫停點平順恢復
      final posMs = _audioPosition.inMilliseconds;
      _targetNextBeatMs = ((posMs ~/ bb) + 1) * bb;
      _lastPositionMs = posMs;
      _isWaitingForAudioRestart = false;
      if (!_audio.isPlaying) {
        _audio.resumeChant();
      }
    }

    // 1 秒計時器 (計算總時長與自動停止)
    _autoElapsedTimer?.cancel();
    _autoElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isAutoCounting) return;
      _autoElapsedSeconds++;
      _storage.setAutoElapsedSeconds(_autoElapsedSeconds);

      // 檢查自動定時關閉
      if (_autoStopMinutes > 0 &&
          _autoElapsedSeconds >= _autoStopMinutes * 60) {
        stopAutoCount();
      }
      notifyListeners();
    });

    // 備援輪詢計時器：每 300ms 檢查一次，僅在逾時 (超過 300ms 未收到音訊推播) 時發起 IPC 查詢，避免常態佔用 Android 主線程
    _autoBeatPollingTimer?.cancel();
    _autoBeatPollingTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (!_isAutoCounting) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastPositionUpdateTimestamp >= 300) {
        final pos = await _audio.getCurrentPosition();
        if (pos != null) {
          _processAudioPosition(pos, bb);
        }
      }
    });

    notifyListeners();
  }

  /// 音訊節拍同步計數處理演算法
  void _processAudioPosition(Duration pos, int bb) {
    final posMs = pos.inMilliseconds;
    _audioPosition = pos;
    _lastPositionUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;

    // 若正在等待音訊重新回到開頭，忽略重啟前的舊進度推播，避免從半途位置累加
    if (_isWaitingForAudioRestart) {
      if (posMs > 350) {
        return; // 忽略尚未歸零的舊音訊推播
      }
      _isWaitingForAudioRestart = false;
      _targetNextBeatMs = bb;
      _lastPositionMs = posMs;
      return;
    }

    // 當音樂循環回到開頭時 (進度倒退或小於 200ms)，重設目標節拍位置為第一拍
    if (posMs < _lastPositionMs - 500 || posMs < 200) {
      _targetNextBeatMs = bb;
    }

    var beatChanged = false;
    // 當播放進度跨過目標節拍點時遞增計數
    while (posMs >= _targetNextBeatMs) {
      _autoCount++;
      _storage.setAutoCounter(_autoCount);
      _targetNextBeatMs += bb;
      beatChanged = true;
    }

    _lastPositionMs = posMs;

    // 關鍵效能提升：當計數遞增時立即零延遲通知 UI；計數未變時節流至每 200ms 通知一次供進度條滑動
    final now = DateTime.now().millisecondsSinceEpoch;
    if (beatChanged || now - _lastProgressNotifyMs >= 200) {
      _lastProgressNotifyMs = now;
      notifyListeners();
    }
  }

  /// 暫停自動計數與佛曲播放 (保留計時與計數，供三元件同步暫停)
  void pauseAutoCount() {
    if (!_isAutoCounting) return;
    _isAutoCounting = false;
    _isWaitingForAudioRestart = false;
    _isAudioStarting = false;
    _autoElapsedTimer?.cancel();
    _autoElapsedTimer = null;
    _autoBeatPollingTimer?.cancel();
    _autoBeatPollingTimer = null;
    _audio.pauseChant();
    notifyListeners();
  }

  /// 停止自動計數與佛曲播放 (完全停止)
  void stopAutoCount() {
    _isAutoCounting = false;
    _isWaitingForAudioRestart = false;
    _isAudioStarting = false;
    _autoElapsedTimer?.cancel();
    _autoElapsedTimer = null;
    _autoBeatPollingTimer?.cancel();
    _autoBeatPollingTimer = null;
    _audio.stopChant();
    notifyListeners();
  }

  /// 開始 / 暫停自動計數切換
  void toggleAutoCount() {
    if (_isAutoCounting) {
      pauseAutoCount();
    } else {
      resumeOrStartAutoCount();
    }
  }

  /// 僅重置自動計時時間（不影響計數）
  void resetAutoTimer() {
    _autoElapsedSeconds = 0;
    _storage.setAutoElapsedSeconds(0);
    notifyListeners();
  }

  /// 僅重置自動計數聲數（不影響計時）
  void resetAutoCount() {
    _autoCount = 0;
    _storage.setAutoCounter(0);
    notifyListeners();
  }

  /// 歸 0（計數與計時同時重置）
  void resetAllAuto() {
    stopAutoCount();
    _autoCount = 0;
    _autoElapsedSeconds = 0;
    _audioPosition = Duration.zero;
    _storage.setAutoCounter(0);
    _storage.setAutoElapsedSeconds(0);
    notifyListeners();
  }

  // --- 佛曲選擇與播放 ---
  void selectSong(int songId) {
    _currentSongId = songId;
    _storage.setLastSongId(songId);

    if (_isAutoCounting) {
      // 若正在計數播放中，切換歌曲後自動以新曲目的速度重新開始
      stopAutoCount();
      resumeOrStartAutoCount(fromBeginning: true);
    } else {
      notifyListeners();
    }
  }

  void selectAndPlaySong(int songId) {
    if (isInAutoCountMode) {
      _currentSongId = songId;
      _storage.setLastSongId(songId);
      stopAutoCount();
      resumeOrStartAutoCount(fromBeginning: true);
    } else {
      selectSong(songId);
      if (!_isAutoCounting) {
        _audio.playChant(songId);
      }
    }
  }

  /// 佛曲播放/暫停切換（核心連動：自動計數模式下連動自動計數與碼表，非自動計數模式則作為背景音效）
  void toggleChant(int songId) {
    _currentSongId = songId;
    _storage.setLastSongId(songId);

    if (_isAutoCounting) {
      // 若自動計數進行中，透過共用音樂播放器暫停，連動暫停自動計數與碼表
      pauseAutoCount();
    } else if (_audio.isPlaying) {
      // 若佛曲已在播放中 (但未處於自動計數中)，點擊暫停純粹暫停音訊
      _audio.pauseChant();
      notifyListeners();
    } else {
      // 音樂未在播放中：根據是否處於自動計數模式決定連動行為
      if (isInAutoCountMode) {
        // 處於自動計數模式，連動啟動/恢復自動計數與碼表
        resumeOrStartAutoCount();
      } else {
        // 非自動計數模式，單純播放背景佛曲
        _audio.playChant(songId);
        notifyListeners();
      }
    }
  }

  /// 首頁【念佛】按鈕：播放/暫停當前佛曲開關（播放音效＋切換播放）
  Future<void> toggleHomeChant() async {
    _audio.playClickSfx(_soundEffect);
    if (_isAutoCounting) {
      pauseAutoCount();
    } else {
      await _audio.toggleChantPlay(_currentSongId);
      notifyListeners();
    }
  }

  /// 進入【念佛頁】時自動播放當前佛曲
  void playChantForChantPage() {
    _audio.playChant(_currentSongId);
    notifyListeners();
  }

  /// 停止佛曲播放
  void stopChant() {
    _audio.stopChant();
    notifyListeners();
  }

  // --- 現代播放器控制 ---
  void playNextSong() {
    final total = ChantConstants.allSongs.length;
    final nextId = (_currentSongId + 1) % total;
    if (isInAutoCountMode && _isAutoCounting) {
      selectSong(nextId);
    } else {
      _currentSongId = nextId;
      _storage.setLastSongId(nextId);
      _audio.playChant(nextId);
      notifyListeners();
    }
  }

  void playPreviousSong() {
    final total = ChantConstants.allSongs.length;
    final prevId = (_currentSongId - 1 + total) % total;
    if (isInAutoCountMode && _isAutoCounting) {
      selectSong(prevId);
    } else {
      _currentSongId = prevId;
      _storage.setLastSongId(prevId);
      _audio.playChant(prevId);
      notifyListeners();
    }
  }

  void seekAudio(Duration position) {
    _audio.seek(position);
    _audioPosition = position;
    if (_isAutoCounting) {
      final song = ChantConstants.getSongById(_currentSongId);
      final bb = song.beatIntervalMs;
      final posMs = position.inMilliseconds;
      _targetNextBeatMs = ((posMs ~/ bb) + 1) * bb;
      _lastPositionMs = posMs;
      _isWaitingForAudioRestart = false;
    }
    notifyListeners();
  }

  void seekAudioRelative(int seconds) {
    final cur = _audioPosition;
    final target = cur + Duration(seconds: seconds);
    final clampedTarget = target < Duration.zero ? Duration.zero : target;
    seekAudio(clampedTarget);
  }

  ReleaseMode get releaseMode => _audio.releaseMode;

  void toggleAudioLoop() {
    final newMode = (_audio.releaseMode == ReleaseMode.loop)
        ? ReleaseMode.stop
        : ReleaseMode.loop;
    _audio.setReleaseMode(newMode);
    notifyListeners();
  }

  // --- 主題、震動、目標功課設定 ---
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    final str = (mode == ThemeMode.light)
        ? 'light'
        : (mode == ThemeMode.dark)
            ? 'dark'
            : 'system';
    _storage.setThemeMode(str);
    notifyListeners();
  }

  void setVibrationEnabled(bool val) {
    _vibrationEnabled = val;
    _storage.setVibrationEnabled(val);
    notifyListeners();
  }

  void setTargetCount(int val) {
    _targetCount = val;
    _storage.setTargetCount(val);
    notifyListeners();
  }

  void setFullscreenTap(bool val) {
    _fullscreenTap = val;
    _storage.setFullscreenTap(val);
    notifyListeners();
  }

  Future<void> markModernGuideSeen() async {
    _hasSeenModernGuide = true;
    await _storage.setSeenModernGuide(true);
    notifyListeners();
  }

  // --- 螢幕方向鎖定 ---
  void toggleOrientationLock([Orientation? currentOrientation]) {
    _isOrientationLocked = !_isOrientationLocked;
    _storage.setOrientationLocked(_isOrientationLocked);
    _applyOrientationLock(currentOrientation);
    notifyListeners();
  }

  void setOrientationLocked(bool val, [Orientation? currentOrientation]) {
    if (_isOrientationLocked == val) return;
    _isOrientationLocked = val;
    _storage.setOrientationLocked(val);
    _applyOrientationLock(currentOrientation);
    notifyListeners();
  }

  void _applyOrientationLock([Orientation? currentOrientation]) {
    try {
      if (_isOrientationLocked) {
        if (currentOrientation == Orientation.landscape) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        }
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } catch (_) {}
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
    _updateWakelock(val);
    notifyListeners();
  }

  void setKeepScreenSongs(bool val) {
    _keepScreenSongs = val;
    _storage.setKeepScreenOnSongs(val);
    _updateWakelock(val);
    notifyListeners();
  }

  void setKeepScreenAuto(bool val) {
    _keepScreenAuto = val;
    _storage.setKeepScreenOnAuto(val);
    _updateWakelock(val);
    notifyListeners();
  }

  /// 當前畫面是否啟用螢幕常亮（防止休眠）
  bool get isCurrentScreenAwake => _keepScreenHome;

  /// 設定螢幕常亮（防止休眠）
  void setScreenAwake(bool enable) {
    setKeepScreenHome(enable);
    setKeepScreenAuto(enable);
    setKeepScreenChant(enable);
    setKeepScreenSongs(enable);
  }

  /// 一鍵切換當前畫面螢幕常亮（防止休眠）
  void toggleCurrentScreenAwake() {
    setScreenAwake(!isCurrentScreenAwake);
  }

  void applyScreenWakelockForCurrentPage(bool enable) {
    _updateWakelock(enable);
  }

  void _updateWakelock(bool enable) {
    try {
      final future = enable ? WakelockPlus.enable() : WakelockPlus.disable();
      future.catchError((_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _autoElapsedTimer?.cancel();
    _autoBeatPollingTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _completeSubscription?.cancel();
    _currentSongSubscription?.cancel();
    _audio.dispose();
    super.dispose();
  }
}
