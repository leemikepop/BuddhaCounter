import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../l10n/app_language.dart';
import '../../l10n/generated/app_localizations.dart';
import 'storage_service.dart';

/// 本地通知與定時提醒服務 (Local Notifications & Daily Reminders)
class NotificationService {
  static const int reminderNotificationId = 100;
  static const String reminderChannelId = 'buddha_daily_reminder';

  final StorageService _storage;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  static bool _timeZonesInitialized = false;

  /// 通知文字使用的語言 (由 LocaleController 依目前語言設定)
  Locale locale = kZhHant;

  NotificationService(this._storage);

  /// 確保時區資料庫已載入並設定預設地區
  static void ensureTimeZonesInitialized() {
    if (!_timeZonesInitialized) {
      try {
        tz.initializeTimeZones();
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Taipei'));
        } catch (_) {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
        _timeZonesInitialized = true;
      } catch (e) {
        debugPrint('Timezones init error: $e');
      }
    }
  }

  /// 初始化本地通知插件與時區設定
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      ensureTimeZonesInitialized();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      _isInitialized = true;

      // 若先前已開啟提醒，於啟動時重新確認排程
      if (_storage.getReminderEnabled()) {
        await scheduleDailyReminder(
          hour: _storage.getReminderHour(),
          minute: _storage.getReminderMinute(),
          enabled: true,
        );
      }
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  /// 請求推播通知權限 (Android 13+ 與 iOS)
  Future<bool?> requestPermissions() async {
    try {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        return await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// 計算下一個觸發時間點
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    ensureTimeZonesInitialized();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// 設定或更新每日定時念佛提醒
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    await _storage.setReminderEnabled(enabled);
    await _storage.setReminderHour(hour);
    await _storage.setReminderMinute(minute);

    try {
      await _plugin.cancel(id: reminderNotificationId);

      if (!enabled) return;

      final l10n = lookupAppLocalizations(locale);
      final androidDetails = AndroidNotificationDetails(
        reminderChannelId,
        l10n.reminderChannelName,
        channelDescription: l10n.reminderChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTime = _nextInstanceOfTime(hour, minute);

      await _plugin.zonedSchedule(
        id: reminderNotificationId,
        title: l10n.reminderNotifTitle,
        body: l10n.reminderNotifBody,
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleDailyReminder error: $e');
    }
  }

  /// 以目前語言重新排程已開啟的每日提醒 (切換語言後通知文字才會跟著換)
  Future<void> refreshDailyReminder() async {
    if (!_storage.getReminderEnabled()) return;
    await scheduleDailyReminder(
      hour: _storage.getReminderHour(),
      minute: _storage.getReminderMinute(),
    );
  }

  /// 發送即時測試通知或里程碑慶賀
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    try {
      final l10n = lookupAppLocalizations(locale);
      final androidDetails = AndroidNotificationDetails(
        'buddha_milestone',
        l10n.milestoneChannelName,
        channelDescription: l10n.milestoneChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: 999,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('showInstantNotification error: $e');
    }
  }

  /// 取消每日提醒
  Future<void> cancelDailyReminder() async {
    await _storage.setReminderEnabled(false);
    try {
      await _plugin.cancel(id: reminderNotificationId);
    } catch (e) {
      debugPrint('cancelDailyReminder error: $e');
    }
  }
}
