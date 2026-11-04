import 'package:flutter/foundation.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/practice_record_service.dart';
import '../../core/services/storage_service.dart';
import '../settings/tap_feedback.dart';

/// 今日功課：手動 / 自動計數、手動與每日目標、功課月曆紀錄、每日提醒、桌面小工具同步。
///
/// [count] 與 [autoCount] 永遠是「今天」的數字；跨過午夜時由 [checkDateRollover] 歸零，
/// 過去的數字保留在 [records] (功課月曆) 裡。
class PracticeController extends ChangeNotifier {
  PracticeController({
    required StorageService storage,
    required PracticeRecordService records,
    required NotificationService notifications,
    required TapFeedback feedback,
  })  : _storage = storage,
        _records = records,
        _notifications = notifications,
        _feedback = feedback,
        _count = storage.getCounter(),
        _autoCount = storage.getAutoCounter(),
        _targetCount = storage.getTargetCount(),
        _dailyTargetCount = storage.getDailyTargetCount() {
    _records.syncWidget();
    checkDateRollover();
  }

  final StorageService _storage;
  final PracticeRecordService _records;
  final NotificationService _notifications;
  final TapFeedback _feedback;

  /// 功課月曆紀錄 (唯讀查詢用；修改請走本類別的方法，才會同步今日計數)
  PracticeRecordService get records => _records;

  int _count;

  /// 今日手動計數
  int get count => _count;

  int _autoCount;

  /// 今日自動計數
  int get autoCount => _autoCount;

  int _targetCount;

  /// 手動計數目標 (0 = 不限)，只和 [count] 比較
  int get targetCount => _targetCount;
  double get targetProgress =>
      _targetCount > 0 ? (_count / _targetCount).clamp(0.0, 1.0) : 0.0;

  int _dailyTargetCount;

  /// 每日功課目標 (0 = 不限)，和當日手動 + 自動總聲數比較
  int get dailyTargetCount => _dailyTargetCount;

  // --- 計數 ---

  void increment() {
    checkDateRollover();
    _setCount(_count + 1);
    _records.addCount(DateTime.now(), manual: 1);
    _markActiveToday();
    _feedback.count();
    notifyListeners();
  }

  void decrement() {
    checkDateRollover();
    if (_count <= 0) return;
    _setCount(_count - 1);
    _records.addCount(DateTime.now(), manual: -1);
    _markActiveToday();
    _feedback.tick();
    notifyListeners();
  }

  void resetCount() {
    _setCount(0);
    _records.syncWidget();
    notifyListeners();
  }

  /// 自動計數念了 [beats] 聲 (由自動計數呼叫)
  void addAutoBeats(int beats) {
    if (beats <= 0) return;
    checkDateRollover();
    _setAutoCount(_autoCount + beats);
    _records.addCount(DateTime.now(), auto: beats);
    _markActiveToday();
    notifyListeners();
  }

  void decrementAuto() {
    checkDateRollover();
    if (_autoCount <= 0) return;
    _setAutoCount(_autoCount - 1);
    _records.addCount(DateTime.now(), auto: -1);
    _markActiveToday();
    _feedback.tick();
    notifyListeners();
  }

  void resetAutoCount() {
    _setAutoCount(0);
    notifyListeners();
  }

  // --- 目標 ---

  void setTargetCount(int value) {
    _targetCount = value;
    _storage.setTargetCount(value);
    notifyListeners();
  }

  void setDailyTargetCount(int value) {
    _dailyTargetCount = value;
    _storage.setDailyTargetCount(value);
    _records.syncWidget();
    notifyListeners();
  }

  // --- 跨日 ---

  /// 檢查是否已跨過午夜：
  /// 1. 新的一天：今日手動 / 自動計數歸零 (過去紀錄保留在功課月曆)。
  /// 2. 今天稍早已有紀錄：恢復今天的數字。
  /// 3. 修復舊版把昨天的數字誤複製到今天的資料。
  void checkDateRollover() {
    final now = DateTime.now();
    final todayKey = PracticeRecordService.formatDateKey(now);
    final lastActiveDate = _storage.getLastActiveDate();

    if (lastActiveDate.isEmpty) {
      // 已有其他日期的紀錄但今天沒有：目前暫存的數字是舊日殘留，歸零
      final hasOtherDays = _records.records.keys.any((k) => k != todayKey);
      if (hasOtherDays && !_records.hasRecord(todayKey)) {
        _setCount(0);
        _setAutoCount(0);
      }
      _storage.setLastActiveDate(todayKey);
      return;
    }
    if (lastActiveDate == todayKey) return;

    final hasToday = _records.hasRecord(todayKey);
    final last = _records.getRecordByKey(lastActiveDate);
    final today = _records.getRecord(now);
    final copiedFromYesterday = hasToday &&
        today.manualCount == last.manualCount &&
        today.autoCount == last.autoCount &&
        last.totalCount > 0;

    if (copiedFromYesterday) {
      _records.clearDate(now);
      _setCount(0);
      _setAutoCount(0);
    } else if (hasToday) {
      _setCount(today.manualCount);
      _setAutoCount(today.autoCount);
    } else {
      _setCount(0);
      _setAutoCount(0);
    }

    _storage.setLastActiveDate(todayKey);
    _records.syncWidget();
    notifyListeners();
  }

  // --- 功課月曆 ---

  int get streakDays => _records.calculateStreak();
  int get todayPracticeCount => _records.getCount(DateTime.now());
  int get weeklyPracticeCount => _records.getWeeklyTotal(DateTime.now());
  int get monthlyPracticeCount {
    final now = DateTime.now();
    return _records.getMonthlyTotal(now.year, now.month);
  }

  /// 直接改寫某天的總聲數；改的是今天時同步今日手動計數
  Future<void> setPracticeCount(DateTime date, int newCount) async {
    final saving = _records.setCount(date, newCount);
    if (_isToday(date)) {
      _setCount(newCount);
      _markActiveToday();
    }
    notifyListeners();
    await saving;
  }

  Future<void> adjustPracticeCount(DateTime date, int delta) async {
    final saving = _records.adjustCount(date, delta);
    if (_isToday(date)) {
      _setCount(_records.getCount(date));
      _markActiveToday();
    }
    notifyListeners();
    await saving;
  }

  Future<void> clearPracticeDate(DateTime date) async {
    final saving = _records.clearDate(date);
    if (_isToday(date)) _setCount(0);
    notifyListeners();
    await saving;
  }

  // --- 桌面小工具 ---

  /// 立即把最新數字推送到桌面小工具
  Future<void> refreshWidgetData() async {
    await _records.syncWidget();
    notifyListeners();
  }

  /// 取消防抖，立刻推送還沒送出的小工具更新 (App 退到背景時呼叫)
  Future<void> flushWidgetSync() => _records.flushWidgetSync();

  // --- 每日提醒 ---

  bool get isReminderEnabled => _storage.getReminderEnabled();
  int get reminderHour => _storage.getReminderHour();
  int get reminderMinute => _storage.getReminderMinute();

  Future<bool?> requestNotificationPermissions() =>
      _notifications.requestPermissions();

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

  // ---

  void _setCount(int value) {
    _count = value;
    _storage.setCounter(value);
  }

  void _setAutoCount(int value) {
    _autoCount = value;
    _storage.setAutoCounter(value);
  }

  void _markActiveToday() => _storage
      .setLastActiveDate(PracticeRecordService.formatDateKey(DateTime.now()));

  static bool _isToday(DateTime date) =>
      PracticeRecordService.formatDateKey(date) ==
      PracticeRecordService.formatDateKey(DateTime.now());

  @override
  void dispose() {
    _records.dispose();
    super.dispose();
  }
}
