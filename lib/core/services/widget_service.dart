import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  }) async {
    try {
      final now = DateTime.now();
      final dateDisplay = '${now.month}月${now.day}日';
      final String targetText;
      if (targetCount > 0) {
        final percent = ((todayCount / targetCount) * 100).toInt();
        targetText = '目標 $percent% ($todayCount/$targetCount)';
      } else {
        targetText = '今日累積 $todayCount 聲 (不限目標)';
      }
      final timestamp = now.millisecondsSinceEpoch.toDouble();

      final groups = await resolveTargetAppGroups();

      // 向所有可能的 App Group 同步寫入（保證無論任何憑證或側載簽名，小工具皆能精準取得最新數據）
      for (final gid in groups) {
        try {
          await HomeWidget.setAppGroupId(gid);
          await HomeWidget.saveWidgetData<int>('today_count', todayCount, appGroupId: gid);
          await HomeWidget.saveWidgetData<int>('target_count', targetCount, appGroupId: gid);
          await HomeWidget.saveWidgetData<int>('weekly_count', weeklyCount, appGroupId: gid);
          await HomeWidget.saveWidgetData<int>('monthly_count', monthlyCount, appGroupId: gid);
          await HomeWidget.saveWidgetData<int>('streak_days', streakDays, appGroupId: gid);
          await HomeWidget.saveWidgetData<String>('date_display', dateDisplay, appGroupId: gid);
          await HomeWidget.saveWidgetData<String>(
            'streak_text',
            streakDays > 0 ? '🔥 連續 $streakDays 天' : '今日精進念佛',
            appGroupId: gid,
          );
          await HomeWidget.saveWidgetData<String>(
            'target_text',
            targetText,
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

  /// 獲取小工具診斷資訊 (用於調試跨進程與 App Group 狀態)
  static Future<Map<String, dynamic>> getDiagnostics() async {
    final Map<String, dynamic> diag = {};
    try {
      final info = await PackageInfo.fromPlatform();
      diag['packageName'] = info.packageName;
      diag['appName'] = info.appName;
      diag['version'] = info.version;
      diag['buildNumber'] = info.buildNumber;
    } catch (e) {
      diag['packageInfoError'] = e.toString();
    }

    try {
      final groups = await resolveTargetAppGroups();
      diag['candidateGroups'] = groups;

      final groupReads = <String, dynamic>{};
      for (final gid in groups) {
        try {
          final count =
              await HomeWidget.getWidgetData<int>('today_count', appGroupId: gid);
          final text =
              await HomeWidget.getWidgetData<String>('target_text', appGroupId: gid);
          final ts = await HomeWidget.getWidgetData<double>(
              'widget_update_timestamp',
              appGroupId: gid);
          groupReads[gid] = {
            'today_count': count,
            'target_text': text,
            'timestamp': ts,
          };
        } catch (e) {
          groupReads[gid] = {'error': e.toString()};
        }
      }
      diag['groupData'] = groupReads;
    } catch (e) {
      diag['groupsError'] = e.toString();
    }

    try {
      final installed = await HomeWidget.getInstalledWidgets();
      diag['installedWidgets'] = installed
          .map((w) => {
                'iOSFamily': w.iOSFamily,
                'iOSKind': w.iOSKind,
                'androidWidgetId': w.androidWidgetId,
                'androidClassName': w.androidClassName,
              })
          .toList();
    } catch (e) {
      diag['installedError'] = e.toString();
    }

    return diag;
  }
}
