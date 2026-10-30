import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// 桌面小工具更新服務 (iOS WidgetKit & Android AppWidget)
class WidgetService {
  static const String appGroupId = 'group.com.yichung.lee.count4';
  static const String androidWidgetName = 'BuddhaCounterWidgetProvider';
  static const String iosWidgetName = 'BuddhaCounterWidget';

  static bool _isInitialized = false;

  /// 初始化 Widget 設定（註冊 App Group）
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      _isInitialized = true;
    } catch (e) {
      debugPrint('WidgetService.init error: $e');
    }
  }

  /// 同步更新桌面小工具數據
  /// [todayCount]: 今日功課聲數
  /// [targetCount]: 今日目標聲數
  /// [weeklyCount]: 本週累計聲數
  /// [monthlyCount]: 本月累計聲數
  /// [streakDays]: 連續精進天數 (Duolingo 風格)
  static Future<void> updateWidgetData({
    required int todayCount,
    required int targetCount,
    required int weeklyCount,
    required int monthlyCount,
    required int streakDays,
  }) async {
    try {
      final now = DateTime.now();
      final dateDisplay = '${now.month}月${now.day}日';
      final percent = targetCount > 0
          ? ((todayCount / targetCount) * 100).toInt()
          : 0;

      await HomeWidget.saveWidgetData<int>('today_count', todayCount);
      await HomeWidget.saveWidgetData<int>('target_count', targetCount);
      await HomeWidget.saveWidgetData<int>('weekly_count', weeklyCount);
      await HomeWidget.saveWidgetData<int>('monthly_count', monthlyCount);
      await HomeWidget.saveWidgetData<int>('streak_days', streakDays);
      await HomeWidget.saveWidgetData<String>('date_display', dateDisplay);
      await HomeWidget.saveWidgetData<String>(
        'streak_text',
        streakDays > 0 ? '🔥 連續 $streakDays 天' : '今日精進念佛',
      );
      await HomeWidget.saveWidgetData<String>(
        'target_text',
        '目標 $percent% ($todayCount/$targetCount)',
      );

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iosWidgetName,
      );
    } catch (e) {
      // 桌面小工具更新失敗不影響主 App 運行
      debugPrint('WidgetService.updateWidgetData error: $e');
    }
  }
}

