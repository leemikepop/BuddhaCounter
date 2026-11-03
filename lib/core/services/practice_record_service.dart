import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import '../../l10n/app_language.dart';
import '../../l10n/generated/app_localizations.dart';
import 'storage_service.dart';
import 'widget_service.dart';

/// 單日精進記錄模型
class DailyPracticeRecord {
  final String dateKey; // 格式: yyyy-MM-dd
  int manualCount;
  int autoCount;
  int totalCount;

  DailyPracticeRecord({
    required this.dateKey,
    this.manualCount = 0,
    this.autoCount = 0,
    int? totalCount,
  }) : totalCount = totalCount ?? (manualCount + autoCount);

  Map<String, dynamic> toJson() => {
        'manual': manualCount,
        'auto': autoCount,
        'total': totalCount,
      };

  factory DailyPracticeRecord.fromJson(
      String key, Map<String, dynamic> json) {
    final manual = (json['manual'] as num?)?.toInt() ?? 0;
    final auto = (json['auto'] as num?)?.toInt() ?? 0;
    final total = (json['total'] as num?)?.toInt() ?? (manual + auto);
    return DailyPracticeRecord(
      dateKey: key,
      manualCount: manual,
      autoCount: auto,
      totalCount: total,
    );
  }
}

/// 每日精進記錄管理服務 (Local Practice History)
class PracticeRecordService {
  final StorageService _storage;
  final Map<String, DailyPracticeRecord> _records = {};

  /// 小工具文字使用的語言 (由 CounterViewModel 依目前語言設定)
  Locale locale = kZhHant;

  PracticeRecordService(this._storage) {
    _loadFromStorage();
  }

  /// 日期格式化工具 (yyyy-MM-dd)
  static String formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 從 StorageService 載入歷史記錄
  void _loadFromStorage() {
    final jsonStr = _storage.getDailyRecordsJson();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            _records[entry.key] = DailyPracticeRecord.fromJson(
              entry.key,
              entry.value as Map<String, dynamic>,
            );
          } else if (entry.value is num) {
            // 相容純數字格式
            final count = (entry.value as num).toInt();
            _records[entry.key] = DailyPracticeRecord(
              dateKey: entry.key,
              manualCount: count,
              autoCount: 0,
              totalCount: count,
            );
          }
        }
      } catch (e) {
        debugPrint('Error loading daily practice records: $e');
      }
    }

    // 僅在記錄庫為完全空白（初次從舊版升級）時，才將舊版既有計數作為歷史起點播種
    if (_records.isEmpty) {
      final lastDate = _storage.getLastActiveDate();
      final targetKey =
          lastDate.isNotEmpty ? lastDate : formatDateKey(DateTime.now());
      final existingCounter = _storage.getCounter();
      final existingAuto = _storage.getAutoCounter();
      if (existingCounter > 0 || existingAuto > 0) {
        _records[targetKey] = DailyPracticeRecord(
          dateKey: targetKey,
          manualCount: existingCounter,
          autoCount: existingAuto,
          totalCount: existingCounter + existingAuto,
        );
        _storage.setLastActiveDate(targetKey);
        _saveToStorage();
      }
    }
  }

  /// 檢查特定日期是否已存在紀錄
  bool hasRecord(String dateKey) => _records.containsKey(dateKey);

  /// 取得所有記錄之唯讀映射
  Map<String, DailyPracticeRecord> get records => Map.unmodifiable(_records);

  /// 取得指定日期的記錄 (依格式化字串鍵值 yyyy-MM-dd)
  DailyPracticeRecord getRecordByKey(String key) {
    return _records[key] ??
        DailyPracticeRecord(
          dateKey: key,
          manualCount: 0,
          autoCount: 0,
          totalCount: 0,
        );
  }

  Timer? _widgetDebounceTimer;

  /// 僅儲存資料記錄至 SharedPreferences 本地快取
  Future<void> _saveRecordsOnly() async {
    try {
      final map = <String, dynamic>{};
      for (final entry in _records.entries) {
        map[entry.key] = entry.value.toJson();
      }
      await _storage.setDailyRecordsJson(jsonEncode(map));
    } catch (e) {
      debugPrint('Error saving daily practice records: $e');
    }
  }

  /// 儲存至 StorageService 並立即同步桌面 Widget (用於手動修訂、清空等操作)
  Future<void> _saveToStorage() async {
    await _saveRecordsOnly();
    await syncWidget();
  }

  /// 桌面小工具防抖推播 (Debounce 800ms)：避免手動高頻點擊或佛曲快節拍時每秒重複觸發跨行程 IPC，暫停即快速同步
  void _debounceSyncWidget() {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    _widgetDebounceTimer?.cancel();
    _widgetDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      syncWidget();
    });
  }

  /// 立即強制推播桌面 Widget (取消待處理的防抖計時)
  Future<void> flushWidgetSync() async {
    _widgetDebounceTimer?.cancel();
    await syncWidget();
  }

  void dispose() {
    _widgetDebounceTimer?.cancel();
  }

  /// 同步更新桌面 Widget 數據 (今日功課、本週本月累計、連續天數)
  Future<void> syncWidget() async {
    final now = DateTime.now();
    final todayCount = getCount(now);
    final target = _storage.getDailyTargetCount();
    final weekly = getWeeklyTotal(now);
    final monthly = getMonthlyTotal(now.year, now.month);
    final streak = calculateStreak(now);

    await WidgetService.updateWidgetData(
      todayCount: todayCount,
      targetCount: target,
      weeklyCount: weekly,
      monthlyCount: monthly,
      streakDays: streak,
      l10n: lookupAppLocalizations(locale),
    );
  }

  /// 取得指定日期的記錄 (若無則回傳預設 0 之物件)
  DailyPracticeRecord getRecord(DateTime date) {
    final key = formatDateKey(date);
    return _records[key] ??
        DailyPracticeRecord(
          dateKey: key,
          manualCount: 0,
          autoCount: 0,
          totalCount: 0,
        );
  }

  /// 取得指定日期總聲數
  int getCount(DateTime date) => getRecord(date).totalCount;

  /// 新增指定日期的計數 (手動累加或自動累加；傳入負值即為減一，各分項最低為 0)
  Future<void> addCount(DateTime date, {int manual = 0, int auto = 0}) async {
    final key = formatDateKey(date);
    final rec = _records[key] ??
        DailyPracticeRecord(
          dateKey: key,
          manualCount: 0,
          autoCount: 0,
          totalCount: 0,
        );

    rec.manualCount = (rec.manualCount + manual).clamp(0, 999999999);
    rec.autoCount = (rec.autoCount + auto).clamp(0, 999999999);
    rec.totalCount = rec.manualCount + rec.autoCount;
    _records[key] = rec;
    await _saveRecordsOnly();
    _debounceSyncWidget();
  }

  /// 手動直接設定指定日期的總聲數 (提供自由修改能力)
  Future<void> setCount(DateTime date, int newCount) async {
    final key = formatDateKey(date);
    final clamped = newCount < 0 ? 0 : newCount;
    final rec = _records[key] ??
        DailyPracticeRecord(
          dateKey: key,
          manualCount: 0,
          autoCount: 0,
          totalCount: 0,
        );

    rec.totalCount = clamped;
    rec.manualCount = clamped;
    rec.autoCount = 0;
    _records[key] = rec;
    await _saveToStorage();
  }

  /// 手動增減指定日期的聲數 (例如 +10, -10, +108 等)
  Future<void> adjustCount(DateTime date, int delta) async {
    final key = formatDateKey(date);
    final rec = _records[key] ??
        DailyPracticeRecord(
          dateKey: key,
          manualCount: 0,
          autoCount: 0,
          totalCount: 0,
        );

    final updated = (rec.totalCount + delta).clamp(0, 999999999);
    rec.totalCount = updated;
    rec.manualCount = updated;
    rec.autoCount = 0;
    _records[key] = rec;
    await _saveToStorage();
  }

  /// 清空指定日期的聲數
  Future<void> clearDate(DateTime date) async {
    final key = formatDateKey(date);
    _records[key] = DailyPracticeRecord(
      dateKey: key,
      manualCount: 0,
      autoCount: 0,
      totalCount: 0,
    );
    await _saveToStorage();
  }

  /// 取得指定月份所有有記錄的日期與聲數對照
  Map<DateTime, int> getMonthRecords(int year, int month) {
    final result = <DateTime, int>{};
    final prefix =
        '$year-${month.toString().padLeft(2, '0')}-';
    for (final entry in _records.entries) {
      if (entry.key.startsWith(prefix)) {
        final parts = entry.key.split('-');
        if (parts.length == 3) {
          final day = int.tryParse(parts[2]);
          if (day != null) {
            result[DateTime(year, month, day)] = entry.value.totalCount;
          }
        }
      }
    }
    return result;
  }

  /// 取得本週累計聲數 (週一至週日)
  int getWeeklyTotal(DateTime date) {
    // 找出本週的週一
    final weekday = date.weekday; // 1 (Mon) - 7 (Sun)
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));

    int sum = 0;
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      sum += getCount(d);
    }
    return sum;
  }

  /// 取得指定月份累計聲數
  int getMonthlyTotal(int year, int month) {
    int sum = 0;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      sum += getCount(DateTime(year, month, day));
    }
    return sum;
  }

  /// 計算連續精進天數 (Streak)
  /// 邏輯仿多鄰國：
  /// - 若今日已有精進 (>0)，自今日往前連續回推
  /// - 若今日尚未精進 (==0)，檢查昨日是否有精進，若有則延續昨日連續紀錄
  /// - 若昨日亦無精進，則連續紀錄中斷為 0
  int calculateStreak([DateTime? relativeTo]) {
    final anchor = relativeTo ?? DateTime.now();
    final today = DateTime(anchor.year, anchor.month, anchor.day);

    final todayCount = getCount(today);
    DateTime currentCheck;
    int streak = 0;

    if (todayCount > 0) {
      streak = 1;
      currentCheck = today.subtract(const Duration(days: 1));
    } else {
      // 今日尚未念佛，檢查昨日
      final yesterday = today.subtract(const Duration(days: 1));
      if (getCount(yesterday) > 0) {
        currentCheck = yesterday;
      } else {
        return 0;
      }
    }

    while (true) {
      if (getCount(currentCheck) > 0) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}

