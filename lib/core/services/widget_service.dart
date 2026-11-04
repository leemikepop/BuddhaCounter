import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n_dates.dart';

/// 推送給原生桌面小工具的已翻譯文字
class WidgetTexts {
  final String dateDisplay;
  final String targetText;
  final String streakText;
  final String widgetTitle;
  final String weeklyText;
  final String monthlyText;
  final String refreshLabel;

  const WidgetTexts({
    required this.dateDisplay,
    required this.targetText,
    required this.streakText,
    required this.widgetTitle,
    required this.weeklyText,
    required this.monthlyText,
    required this.refreshLabel,
  });
}

/// 依語言組出小工具顯示文字 (純函式，便於測試)
WidgetTexts buildWidgetTexts(
  AppLocalizations l10n, {
  required int todayCount,
  required int targetCount,
  required int weeklyCount,
  required int monthlyCount,
  required int streakDays,
  required DateTime now,
}) {
  return WidgetTexts(
    dateDisplay:
        l10n.widgetDate(now.month, now.day, englishMonthShort(now.month)),
    targetText: targetCount > 0
        ? l10n.widgetTargetText(
            ((todayCount / targetCount) * 100).toInt(),
            todayCount,
            targetCount,
          )
        : l10n.widgetTodayNoGoal(todayCount),
    streakText:
        streakDays > 0 ? l10n.widgetStreak(streakDays) : l10n.widgetStreakNone,
    widgetTitle: l10n.appTitle,
    weeklyText: l10n.widgetWeekly(weeklyCount),
    monthlyText: l10n.widgetMonthly(monthlyCount),
    refreshLabel: l10n.widgetRefresh,
  );
}

/// 桌面小工具更新服務 (iOS WidgetKit & Android AppWidget)
class WidgetService {
  static const String appGroupId = 'group.com.yichung.lee.count4';
  static const String fallbackAppGroupId = 'group.app.CountApp';
  static const String androidWidgetName = 'BuddhaCounterWidgetProvider';
  static const String qualifiedAndroidWidgetName =
      'com.yichung.lee.buddha_counter.BuddhaCounterWidgetProvider';
  static const String iosWidgetName = 'BuddhaCounterWidget';

  static bool _isInitialized = false;

  /// 動態推導當前環境（原生安裝、TestFlight 或 Sideloadly / AltStore 側載更動 BundleID 時）所有可能的 App Group 清單
  static Future<List<String>> resolveTargetAppGroups() async {
    final groups = <String>{
      appGroupId, // 'group.com.yichung.lee.count4'
      fallbackAppGroupId, // 'group.app.CountApp'
    };

    try {
      final info = await PackageInfo.fromPlatform();
      final pkg = info.packageName.trim();
      if (pkg.isNotEmpty) {
        // 側載工具（如 Sideloadly / AltStore）會將 App Group 重新簽署為 group.<實際PackageName>
        groups.add('group.$pkg');
        groups.add('group.$pkg.BuddhaCounterWidgetExtension');

        final parts = pkg.split('.');
        if (parts.length >= 2) {
          groups.add('group.${parts.take(2).join('.')}');
        }
      }
    } catch (e) {
      debugPrint('WidgetService.resolveTargetAppGroups error: $e');
    }

    return groups.toList();
  }

  /// 初始化 Widget 設定（向所有候選 App Group 進行註冊）
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final groups = await resolveTargetAppGroups();
      for (final gid in groups) {
        try {
          await HomeWidget.setAppGroupId(gid);
        } catch (_) {}
      }
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
    required AppLocalizations l10n,
  }) async {
    try {
      final now = DateTime.now();
      final texts = buildWidgetTexts(
        l10n,
        todayCount: todayCount,
        targetCount: targetCount,
        weeklyCount: weeklyCount,
        monthlyCount: monthlyCount,
        streakDays: streakDays,
        now: now,
      );
      final timestamp = now.millisecondsSinceEpoch.toDouble();

      final groups = await resolveTargetAppGroups();

      // 向所有可能的 App Group 同步寫入（保證無論任何憑證或側載簽名，小工具皆能精準取得最新數據）
      for (final gid in groups) {
        try {
          await HomeWidget.setAppGroupId(gid);
          await HomeWidget.saveWidgetData<int>('today_count', todayCount,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<int>('target_count', targetCount,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<int>('weekly_count', weeklyCount,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<int>('monthly_count', monthlyCount,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<int>('streak_days', streakDays,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<String>(
              'date_display', texts.dateDisplay,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<String>(
              'widget_title', texts.widgetTitle,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<String>(
              'weekly_text', texts.weeklyText,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<String>(
              'monthly_text', texts.monthlyText,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<String>(
              'refresh_label', texts.refreshLabel,
              appGroupId: gid);
          await HomeWidget.saveWidgetData<String>(
            'streak_text',
            texts.streakText,
            appGroupId: gid,
          );
          await HomeWidget.saveWidgetData<String>(
            'target_text',
            texts.targetText,
            appGroupId: gid,
          );
          await HomeWidget.saveWidgetData<double>(
            'widget_update_timestamp',
            timestamp,
            appGroupId: gid,
          );
        } catch (e) {
          debugPrint('WidgetService sync error for $gid: $e');
        }
      }

      // 通知原生系統刷新小工具
      await HomeWidget.updateWidget(
        name: defaultTargetPlatform == TargetPlatform.iOS
            ? iosWidgetName
            : androidWidgetName,
        androidName: androidWidgetName,
        qualifiedAndroidName: qualifiedAndroidWidgetName,
        iOSName: iosWidgetName,
      );
    } catch (e) {
      // 桌面小工具更新失敗不影響主 App 運行
      debugPrint('WidgetService.updateWidgetData error: $e');
    }
  }
}
