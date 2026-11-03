import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/constants/chant_songs.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/practice_record_service.dart';
import '../../core/services/storage_service.dart';

class CounterViewModel extends ChangeNotifier {
  final StorageService _storage;
  final AudioService _audio;
  final PracticeRecordService _practiceRecords;
  final NotificationService _notifications;

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

  /// 獨立輕量音訊進度通知器：僅局部重繪進度條/滑桿，避免播放期間每秒多次重建整棵 App Widget 樹
  final ValueNotifier<Duration> _audioPositionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> _audioDurationNotifier =
      ValueNotifier<Duration>(Duration.zero);

  ValueListenable<Duration> get audioPositionListenable =>
      _audioPositionNotifier;
  ValueListenable<Duration> get audioDurationListenable =>
      _audioDurationNotifier;

  void _setAudioPosition(Duration pos) {
    _audioPosition = pos;
    if (_audioPositionNotifier.value != pos) {
      _audioPositionNotifier.value = pos;
    }
  }

  void _setAudioDuration(Duration dur) {
    _audioDuration = dur;
    if (_audioDurationNotifier.value != dur) {
      _audioDurationNotifier.value = dur;
    }
  }

  // 節拍目標位置（毫秒，對應原版 ss = bb）
  int _targetNextBeatMs = 0;
  int _nextMarkerIndex = 0; // 當前等待跨過的佛號標記索引（phraseMarkersMs 模式）
  int _lastPositionMs = 0;
  bool _isWaitingForAudioRestart = false;
  int _lastProgressNotifyMs = 0;
  int _lastPositionUpdateTimestamp = 0;
  bool _isScrubbing = false; // 是否正在手動拖曳進度條（防誤觸發計數）
  bool get isScrubbing => _isScrubbing;

  StreamSubscription<bool>? _playStateSubscription;

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
    } else if (_activeTabIndex == 3) {
      applyScreenWakelockForCurrentPage(false);
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

  int _huiXiangIndex = 0;
  int get huiXiangIndex => _huiXiangIndex;

  int _currentSongId = 0;
  int get currentSongId => _currentSongId;

  AudioService get audioService => _audio;
  PracticeRecordService get practiceRecords => _practiceRecords;
  NotificationService get notifications => _notifications;

  int get streakDays => _practiceRecords.calculateStreak();
  int get todayPracticeCount => _practiceRecords.getCount(DateTime.now());
  int get weeklyPracticeCount => _practiceRecords.getWeeklyTotal(DateTime.now());
  int get monthlyPracticeCount =>
      _practiceRecords.getMonthlyTotal(DateTime.now().year, DateTime.now().month);

  bool get isReminderEnabled => _storage.getReminderEnabled();
  int get reminderHour => _storage.getReminderHour();
  int get reminderMinute => _storage.getReminderMinute();

  CounterViewModel({
    required StorageService storage,
    required AudioService audio,
    PracticeRecordService? practiceRecords,
    NotificationService? notifications,
  })  : _storage = storage,
        _audio = audio,
        _practiceRecords = practiceRecords ?? PracticeRecordService(storage),
        _notifications = notifications ?? NotificationService(storage),
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
    final maxHxIdx = ChantConstants.huiXiangItems.length - 1;
    _huiXiangIndex = _storage.getHuiXiangIndex().clamp(0, maxHxIdx);

    // 監聽音訊時長變化（透過獨立 ValueListenable 更新進度條，不觸發全頁重建）
    _durationSubscription = _audio.onDurationChanged.listen((dur) {
      _setAudioDuration(dur);
      if (_showAudioPosition) {
        notifyListeners();
      }
    });

    // 監聽播放進度推播：僅更新獨立進度 ValueListenable，非計數跳動時絕不呼叫全體 notifyListeners()
    _positionSubscription = _audio.onPositionChanged.listen((pos) {
      if (_isScrubbing) return; // 拖動進度條期間不覆蓋指針與觸發計數
      _setAudioPosition(pos);
      _lastPositionUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
      if (_isAutoCounting) {
        final song = ChantConstants.getSongById(_currentSongId);
        _processAudioPosition(pos, song.effectiveBeatIntervalMs);
      } else if (_showAudioPosition) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastProgressNotifyMs >= 250) {
          _lastProgressNotifyMs = now;
          notifyListeners();
        }
      }
    });

    // 監聽播放狀態變化（用以即時更新首頁念佛按鈕顏色等）
    _playerStateSubscription = _audio.onPlayerStateChanged.listen((state) {
      if (_audio.handler.isSwitchingTrack) return;
      if (state == PlayerState.completed && _audio.releaseMode == ReleaseMode.loop) {
        // 單曲循環播放時忽略 completed 暫態事件，避免 UI 抖動與全頁 Rebuild 搶佔 CPU / 音訊解碼資源
        return;
      }
      if (state == PlayerState.paused && _isAutoCounting && !_audio.isPlaying) {
        pauseAutoCount();
      } else {
        notifyListeners();
      }
    });

    // 監聽外部媒體控制播放/暫停事件（支援系統通知欄、鎖定畫面、耳機線控、音訊焦點丟失）
    _playStateSubscription = _audio.onPlayStateChanged.listen((playing) {
      // 關鍵防重入保護：若非同步廣播事件已落後於目前真實播放狀態（例如切歌瞬間過時的 false），
      // 必須直接忽略，徹底杜絕 false <-> true 微任務無限乒乓迴圈導致 mmap 耗盡與 OOM 閃退
      if (playing != _audio.isPlaying) return;

      if (!playing) {
        if (_isAutoCounting) {
          pauseAutoCount();
        } else {
          notifyListeners();
        }
      } else {
        if (isInAutoCountMode && !_isAutoCounting) {
          resumeOrStartAutoCount();
        } else {
          notifyListeners();
        }
      }
    });

    // 監聽播放完成（清單切歌已由 ChantAudioHandler.onPlayerComplete 統一推進並透過 onCurrentSongChanged 同步，避免雙重跳首）
    _completeSubscription = _audio.onPlayerComplete.listen((_) {});

    // 監聽外部（系統通知欄/鎖定螢幕）切換曲目事件
    _currentSongSubscription = _audio.onCurrentSongChanged.listen((songId) {
      if (_currentSongId != songId) {
        _currentSongId = songId;
        _storage.setLastSongId(songId);
        if (_isAutoCounting) {
          final song = ChantConstants.getSongById(songId);
          _setAudioPosition(Duration.zero);
          _setAudioDuration(Duration.zero);
          _targetNextBeatMs = song.effectiveBeatIntervalMs;
          _nextMarkerIndex = 0;
          _lastPositionMs = 0;
          _isWaitingForAudioRestart = true;
        }
        notifyListeners();
      }
    });

    // 初始化時即時同步一次桌面 Widget 數據
    _practiceRecords.syncWidget();

    // 啟動換日檢查 (若跨日則歸零或恢復今日紀錄)
    checkDateRollover();
  }

  /// 檢查跨日 (午夜 12 點換日) 邏輯：
  /// 1. 若系統日期已跨入新的一天，今日計數自動歸零，昨日及過往計數妥善保留於功課月曆中。
  /// 2. 若今日已有獨立計數記錄（例如今日稍早開啟過），則恢復今日的計數。
  /// 3. 自我修復舊版本將昨日計數錯誤複製播種至今日的歷史污染資料。
  void checkDateRollover() {
    final now = DateTime.now();
    final todayKey = PracticeRecordService.formatDateKey(now);
    final lastActiveDate = _storage.getLastActiveDate();

    if (lastActiveDate.isEmpty) {
      // 若歷史庫已有其他日期的記錄，但今日尚無記錄，代表目前暫存之計數實為舊日殘留，應予以重設歸零
      final hasOtherDays =
          _practiceRecords.records.keys.any((k) => k != todayKey);
      if (hasOtherDays && !_practiceRecords.hasRecord(todayKey)) {
        _count = 0;
        _autoCount = 0;
        _storage.setCounter(0);
        _storage.setAutoCounter(0);
      }
      _storage.setLastActiveDate(todayKey);
      return;
    }

    if (lastActiveDate == todayKey) {
      return;
    }

    // 換日了 (跨越半夜 12 點，或跨日重新開啟 App)
    final hasExistingToday = _practiceRecords.hasRecord(todayKey);
    final lastRecord = _practiceRecords.getRecordByKey(lastActiveDate);
    final todayRecord = _practiceRecords.getRecord(now);

    // 自我修復：如果今日記錄恰好與最後活躍日（昨日）完全相同且計數大於零，
    // 說明受到舊版初始化 bug 播種污染，應予以修復歸零
    if (hasExistingToday &&
        todayRecord.manualCount == lastRecord.manualCount &&
        todayRecord.autoCount == lastRecord.autoCount &&
        lastRecord.totalCount > 0) {
      _practiceRecords.clearDate(now);
      _count = 0;
      _autoCount = 0;
    } else if (hasExistingToday) {
      // 今日已有正常記錄（如今日其他時段所念）
      _count = todayRecord.manualCount;
      _autoCount = todayRecord.autoCount;
    } else {
      // 今日為全新的一天，數字歸零重新開始
      _count = 0;
      _autoCount = 0;
    }

    _storage.setCounter(_count);
    _storage.setAutoCounter(_autoCount);
    _storage.setLastActiveDate(todayKey);
    _practiceRecords.syncWidget();
    notifyListeners();
  }

  bool get isChantPlaying => _audio.isPlaying;

  // --- 手動計數 ---
  void increment() {
    checkDateRollover();
    _count++;
    _storage.setCounter(_count);
    _practiceRecords.addCount(DateTime.now(), manual: 1);
    _storage.setLastActiveDate(
        PracticeRecordService.formatDateKey(DateTime.now()));
    _audio.playClickSfx(_soundEffect);
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    notifyListeners();
  }

  void decrement() {
    checkDateRollover();
    if (_count > 0) {
      _count--;
      _storage.setCounter(_count);
      _practiceRecords.adjustCount(DateTime.now(), -1);
      _storage.setLastActiveDate(
          PracticeRecordService.formatDateKey(DateTime.now()));
      if (_vibrationEnabled) {
        HapticFeedback.selectionClick();
      }
      notifyListeners();
    }
  }

  void resetCount() {
    _count = 0;
    _storage.setCounter(_count);
    _practiceRecords.syncWidget();
    notifyListeners();
  }

  /// 立即手動重新整理並推播最新數據至桌面小工具 (iOS & Android)
  Future<void> refreshWidgetData() async {
    await _practiceRecords.syncWidget();
    notifyListeners();
  }

  /// 立即強制推播任何待發送之精進數據至桌面小工具 (取消防抖)
  Future<void> flushPracticeRecords() async {
    await _practiceRecords.flushWidgetSync();
  }

  // --- 功課月曆與記錄操作 ---
  Future<void> setPracticeCount(DateTime date, int newCount) async {
    final future = _practiceRecords.setCount(date, newCount);
    final now = DateTime.now();
    if (PracticeRecordService.formatDateKey(date) ==
        PracticeRecordService.formatDateKey(now)) {
      _count = newCount;
      _storage.setCounter(_count);
      _storage.setLastActiveDate(PracticeRecordService.formatDateKey(now));
    }
    notifyListeners();
    await future;
  }

  Future<void> adjustPracticeCount(DateTime date, int delta) async {
    final future = _practiceRecords.adjustCount(date, delta);
    final now = DateTime.now();
    if (PracticeRecordService.formatDateKey(date) ==
        PracticeRecordService.formatDateKey(now)) {
      _count = _practiceRecords.getCount(date);
      _storage.setCounter(_count);
      _storage.setLastActiveDate(PracticeRecordService.formatDateKey(now));
    }
    notifyListeners();
    await future;
  }

  Future<void> clearPracticeDate(DateTime date) async {
    final future = _practiceRecords.clearDate(date);
    final now = DateTime.now();
    if (PracticeRecordService.formatDateKey(date) ==
        PracticeRecordService.formatDateKey(now)) {
      _count = 0;
      _storage.setCounter(0);
    }
    notifyListeners();
    await future;
  }

  Future<void> updateReminderSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await _notifications.scheduleDailyReminder(
      hour: hour,
      minute: minute,
      enabled: enabled,
    );
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

  void _ensureAutoTimersRunning() {
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
    _autoBeatPollingTimer =
        Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (!_isAutoCounting || _isScrubbing) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastPositionUpdateTimestamp >= 300) {
        final pos = await _audio.getCurrentPosition();
        if (pos != null && _isAutoCounting && !_isScrubbing) {
          final currentSong = ChantConstants.getSongById(_currentSongId);
          _processAudioPosition(pos, currentSong.effectiveBeatIntervalMs);
        }
      }
    });
  }

  /// 恢復或啟動自動計數與佛曲播放
  void resumeOrStartAutoCount({bool fromBeginning = false}) {
    if (_isAutoCounting) return;
    _isAutoCounting = true;

    final song = ChantConstants.getSongById(_currentSongId);
    final bb = song.effectiveBeatIntervalMs;

    if (fromBeginning || _audioPosition == Duration.zero) {
      _setAudioPosition(Duration.zero);
      _targetNextBeatMs = bb;
      _nextMarkerIndex = 0;
      _lastPositionMs = 0;
      _isWaitingForAudioRestart = true;

      // 直接載入並播放當前佛曲（playChant 內部即從 0ms 開始，避免對未準備完成之播放器預先呼叫 seek）
      _audio.playChant(_currentSongId);
    } else {
      // 從目前暫停點平順恢復
      final posMs = _audioPosition.inMilliseconds;
      if (song.hasMarkers) {
        final nextIdx = song.phraseMarkersMs.indexWhere((m) => m > posMs);
        _nextMarkerIndex =
            (nextIdx != -1) ? nextIdx : song.phraseMarkersMs.length;
      } else {
        _targetNextBeatMs = ((posMs ~/ bb) + 1) * bb;
      }
      _lastPositionMs = posMs;
      _isWaitingForAudioRestart = false;
      if (!_audio.isPlaying) {
        _audio.resumeChant();
      }
    }

    _ensureAutoTimersRunning();
    notifyListeners();
  }

  /// 於自動計數模式下直接無縫切換佛曲並從頭對齊標記（不經過 stopAutoCount，避免 false->true 非同步狀態震盪）
  void _restartAutoCountWithSong(int songId) {
    _currentSongId = songId;
    _storage.setLastSongId(songId);
    _isAutoCounting = true;

    final song = ChantConstants.getSongById(songId);
    _setAudioPosition(Duration.zero);
    _setAudioDuration(Duration.zero);
    _targetNextBeatMs = song.effectiveBeatIntervalMs;
    _nextMarkerIndex = 0;
    _lastPositionMs = 0;
    _isWaitingForAudioRestart = true;

    _ensureAutoTimersRunning();
    _audio.playChant(songId);
    notifyListeners();
  }

  /// 音訊節拍同步計數處理演算法 (支援精確標記點與固定週期雙模式，具備防拖曳跳躍保護)
  void _processAudioPosition(Duration pos, int bb) {
    if (_isScrubbing) return; // 拖動進度條期間忽略進度推播，防誤算

    final posMs = pos.inMilliseconds;
    _setAudioPosition(pos);
    _lastPositionUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;

    // 若正在等待音訊重新回到開頭，忽略重啟前的舊進度推播，避免從半途位置累加
    if (_isWaitingForAudioRestart) {
      if (posMs > 350) {
        return; // 忽略尚未歸零的舊音訊推播
      }
      _isWaitingForAudioRestart = false;
      _targetNextBeatMs = bb;
      _nextMarkerIndex = 0;
      _lastPositionMs = posMs;
      return;
    }

    final song = ChantConstants.getSongById(_currentSongId);

    // 當音樂循環回到開頭時 (進度倒退 800ms 以上或小於 250ms 且之前位置較大)，重設指針為開頭
    final isLoopedBack = (posMs < _lastPositionMs - 800) || (posMs < 250 && _lastPositionMs > 1000);
    if (isLoopedBack) {
      _targetNextBeatMs = bb;
      _nextMarkerIndex = 0;
    }

    var beatChanged = false;

    if (song.hasMarkers) {
      // --- 模式 A：精準標記點 (Phrase Markers / Cue Points) 模式 ---
      while (_nextMarkerIndex < song.phraseMarkersMs.length &&
          posMs >= song.phraseMarkersMs[_nextMarkerIndex]) {
        final markerMs = song.phraseMarkersMs[_nextMarkerIndex];
        // 防跳躍安全機制：只有進度正常流過（與標記差距小於 3 秒）時才累加，避免因跳轉未攔截而暴增
        if (posMs - markerMs <= 3000) {
          checkDateRollover();
          _autoCount++;
          _storage.setAutoCounter(_autoCount);
          _practiceRecords.addCount(DateTime.now(), auto: 1);
          _storage.setLastActiveDate(
              PracticeRecordService.formatDateKey(DateTime.now()));
          beatChanged = true;
        }
        _nextMarkerIndex++;
      }
    } else {
      // --- 模式 B：向下相容之固定週期 (bb) 模式 ---
      if (posMs >= _targetNextBeatMs) {
        final jump = (posMs - _targetNextBeatMs) ~/ bb;
        if (jump <= 1) {
          while (posMs >= _targetNextBeatMs) {
            checkDateRollover();
            _autoCount++;
            _storage.setAutoCounter(_autoCount);
            _practiceRecords.addCount(DateTime.now(), auto: 1);
            _storage.setLastActiveDate(
                PracticeRecordService.formatDateKey(DateTime.now()));
            _targetNextBeatMs += bb;
            beatChanged = true;
          }
        } else {
          // 跳轉過大（例如 seek 遺留），對齊至下一拍但不累加跳過的時間
          _targetNextBeatMs = ((posMs ~/ bb) + 1) * bb;
        }
      }
    }

    _lastPositionMs = posMs;

    // 關鍵效能提升：進度條已由獨立 audioPositionListenable 局部驅動，此處僅在計數遞增（或經典模式開啟秒數顯示）時才通知主樹
    if (beatChanged) {
      notifyListeners();
    } else if (_showAudioPosition) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastProgressNotifyMs >= 250) {
        _lastProgressNotifyMs = now;
        notifyListeners();
      }
    }
  }

  /// 暫停自動計數與佛曲播放 (保留計時與計數，供三元件同步暫停)
  void pauseAutoCount() {
    if (!_isAutoCounting) return;
    _isAutoCounting = false;
    _isWaitingForAudioRestart = false;
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
    _setAudioPosition(Duration.zero);
    _storage.setAutoCounter(0);
    _storage.setAutoElapsedSeconds(0);
    notifyListeners();
  }

  // --- 佛曲選擇與播放 ---
  void selectSong(int songId) {
    if (_isAutoCounting) {
      // 若正在計數播放中，直接無縫切換至新曲目的速度重新開始（不呼叫 stopAutoCount 造成狀態震盪）
      _restartAutoCountWithSong(songId);
    } else {
      _currentSongId = songId;
      _storage.setLastSongId(songId);
      _setAudioPosition(Duration.zero);
      _setAudioDuration(Duration.zero);
      notifyListeners();
    }
  }

  void selectAndPlaySong(int songId) {
    if (isInAutoCountMode) {
      _restartAutoCountWithSong(songId);
    } else {
      _currentSongId = songId;
      _storage.setLastSongId(songId);
      _setAudioPosition(Duration.zero);
      _setAudioDuration(Duration.zero);
      _audio.playChant(songId);
      notifyListeners();
    }
  }

  /// 佛曲播放/暫停切換（核心連動：自動計數模式下連動自動計數與碼表，非自動計數模式則作為背景音效）
  void toggleChant(int songId) {
    if (_currentSongId != songId) {
      // 點擊清單中另一首不同佛曲時，直接切換並播放該首新佛曲
      selectAndPlaySong(songId);
      return;
    }

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
    selectAndPlaySong(nextId);
  }

  void playPreviousSong() {
    final total = ChantConstants.allSongs.length;
    final prevId = (_currentSongId - 1 + total) % total;
    selectAndPlaySong(prevId);
  }

  /// 開始手動拖動進度條（暫停進度推播與節拍比對，防高頻抖動）
  void beginScrubbing() {
    _isScrubbing = true;
  }

  /// 結束手動拖動進度條並跳至指定時間點
  void endScrubbing(Duration position) {
    _isScrubbing = false;
    seekAudio(position);
  }

  /// 跳至指定播放位置（精準重定位下一個計數標記點，絕不誤加跳過之次數）
  void seekAudio(Duration position) {
    _audio.seek(position);
    _setAudioPosition(position);
    final posMs = position.inMilliseconds;
    _lastPositionMs = posMs;
    _isWaitingForAudioRestart = false;

    if (_isAutoCounting) {
      final song = ChantConstants.getSongById(_currentSongId);
      if (song.hasMarkers) {
        // 精準將指針重新定位到 seek 目標時間之後的第一個標記點
        final nextIdx = song.phraseMarkersMs.indexWhere((m) => m > posMs);
        _nextMarkerIndex = (nextIdx != -1) ? nextIdx : song.phraseMarkersMs.length;
      } else {
        final bb = song.effectiveBeatIntervalMs;
        _targetNextBeatMs = ((posMs ~/ bb) + 1) * bb;
      }
    }
    if (_showAudioPosition) {
      notifyListeners();
    }
  }

  void seekAudioRelative(int seconds) {
    final cur = _audioPosition;
    final dur = _audioDuration;
    var target = cur + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (dur > Duration.zero && target > dur) target = dur;
    seekAudio(target);
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
    _practiceRecords.syncWidget();
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

  Future<void> setHuiXiangIndex(int index) async {
    final maxIdx = ChantConstants.huiXiangItems.length - 1;
    final clamped = index.clamp(0, maxIdx);
    if (_huiXiangIndex == clamped) return;
    _huiXiangIndex = clamped;
    await _storage.setHuiXiangIndex(clamped);
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
    _practiceRecords.dispose();
    _stopwatchTimer?.cancel();
    _autoElapsedTimer?.cancel();
    _autoBeatPollingTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _playStateSubscription?.cancel();
    _completeSubscription?.cancel();
    _currentSongSubscription?.cancel();
    _audioPositionNotifier.dispose();
    _audioDurationNotifier.dispose();
    _audio.dispose();
    super.dispose();
  }
}
