import 'package:flutter/foundation.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/practice_record_service.dart';
import '../../core/services/storage_service.dart';
import '../settings/tap_feedback.dart';

/// 今日功課：手動 / 自動計數、手動與每日目標、功課月曆紀錄、每日提醒、桌面小工具同步。
///
/// [count] / [autoCount] (計數器上的數字) 與 [records] (功課月曆的每日紀錄) 是分開的：
/// - 計數 +1 (或自動計數念了幾聲) 時，同時加到「當下那一天」的紀錄，跨過午夜就自然記到新的一天。
/// - 計數器的數字不會因為跨日而歸零，只有使用者按歸零才會歸零。
/// - −1 與歸零只改計數器，不動月曆紀錄；在月曆修改紀錄也不會改到計數器。
class PracticeController extends ChangeNotifier {
  PracticeController({
    required StorageService storage,
    required PracticeRecordService records,
    required NotificationService notifications,
    required TapFeedback feedback,
    DateTime Function()? clock,
  })  : _storage = storage,
        _records = records,
        _notifications = notifications,
        _feedback = feedback,
        _now = clock ?? DateTime.now,
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

  /// 目前時間 (測試可注入假的時鐘來模擬跨過午夜)
  final DateTime Function() _now;

  /// 功課月曆紀錄 (唯讀查詢用；修改請走本類別的方法，畫面才會更新)
  PracticeRecordService get records => _records;

  int _count;

  /// 手動計數器上的數字 (跨日不歸零)
  int get count => _count;

  int _autoCount;

  /// 自動計數器上的數字 (跨日不歸零)
  int get autoCount => _autoCount;

  int _targetCount;

  /// 手動計數目標 (0 = 不限)，只和 [count] 比較
  int get targetCount => _targetCount;
  double get targetProgress =>
      _targetCount > 0 ? (_count / _targetCount).clamp(0.0, 1.0) : 0.0;

  int _dailyTargetCount;

  /// 每日功課目標 (0 = 不限)，和當日月曆紀錄的手動 + 自動總聲數比較
  int get dailyTargetCount => _dailyTargetCount;

  // --- 計數 ---

  void increment() {
    checkDateRollover();
    _setCount(_count + 1);
    _records.addCount(_now(), manual: 1);
    _markActiveToday();
    _feedback.count();
    notifyListeners();
  }

  /// 計數器 −1 (點錯時修正用)；不動月曆紀錄
  void decrement() {
    if (_count <= 0) return;
    _setCount(_count - 1);
    _feedback.tick();
    notifyListeners();
  }

  /// 計數器歸零；不動月曆紀錄
  void resetCount() {
    _setCount(0);
    notifyListeners();
  }

  /// 自動計數念了 [beats] 聲 (由自動計數呼叫)
  void addAutoBeats(int beats) {
    if (beats <= 0) return;
    checkDateRollover();
    _setAutoCount(_autoCount + beats);
    _records.addCount(_now(), auto: beats);
    _markActiveToday();
    notifyListeners();
  }

  /// 自動計數器 −1；不動月曆紀錄
  void decrementAuto() {
    if (_autoCount <= 0) return;
    _setAutoCount(_autoCount - 1);
    _feedback.tick();
    notifyListeners();
  }

  /// 自動計數器歸零；不動月曆紀錄
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

  /// 檢查是否已跨過午夜 (App 開著時每 30 秒、回到前景時、每次計數前呼叫)。
  ///
  /// 計數器的數字不會歸零；這裡只讓月曆與桌面小工具的「今天」換成新的日期，
  /// 並修復舊版把昨天的數字誤複製到今天的資料。
  void checkDateRollover() {
    final now = _now();
    final todayKey = PracticeRecordService.formatDateKey(now);
    final lastActiveDate = _storage.getLastActiveDate();
    if (lastActiveDate == todayKey) return;

    if (lastActiveDate.isNotEmpty && _records.hasRecord(todayKey)) {
      final last = _records.getRecordByKey(lastActiveDate);
      final today = _records.getRecord(now);
      final copiedFromYesterday = today.manualCount == last.manualCount &&
          today.autoCount == last.autoCount &&
          last.totalCount > 0;
      if (copiedFromYesterday) _records.clearDate(now);
    }

    _storage.setLastActiveDate(todayKey);
    _records.syncWidget();
    notifyListeners();
  }

  // --- 功課月曆 ---

  int get streakDays => _records.calculateStreak(_now());
  int get todayPracticeCount => _records.getCount(_now());
  int get weeklyPracticeCount => _records.getWeeklyTotal(_now());
  int get monthlyPracticeCount {
    final now = _now();
    return _records.getMonthlyTotal(now.year, now.month);
  }

  /// 直接改寫某天的總聲數 (只改月曆紀錄，不影響計數器)
  Future<void> setPracticeCount(DateTime date, int newCount) async {
    final saving = _records.setCount(date, newCount);
    _afterRecordEdit(date);
    await saving;
  }

  /// 增減某天的總聲數 (只改月曆紀錄，不影響計數器)
  Future<void> adjustPracticeCount(DateTime date, int delta) async {
    final saving = _records.adjustCount(date, delta);
    _afterRecordEdit(date);
    await saving;
  }

  /// 清空某天的紀錄 (只改月曆紀錄，不影響計數器)
  Future<void> clearPracticeDate(DateTime date) async {
    final saving = _records.clearDate(date);
    _afterRecordEdit(date);
    await saving;
  }

  void _afterRecordEdit(DateTime date) {
    // 今天的紀錄被改過，就不能再被當成「舊版誤複製的資料」清掉
    if (_isToday(date)) _markActiveToday();
    notifyListeners();
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

  void _markActiveToday() =>
      _storage.setLastActiveDate(PracticeRecordService.formatDateKey(_now()));

  bool _isToday(DateTime date) =>
      PracticeRecordService.formatDateKey(date) ==
      PracticeRecordService.formatDateKey(_now());

  @override
  void dispose() {
    _records.dispose();
    super.dispose();
  }
}
