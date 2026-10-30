import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';

/// 本地通知與定時提醒服務 (Local Notifications & Daily Reminders)
class NotificationService {
  static const int reminderNotificationId = 100;
  static const String reminderChannelId = 'buddha_daily_reminder';
  static const String reminderChannelName = '精進日課提醒';
  static const String reminderChannelDesc = '簡單的事情每天做，就會變成不簡單。';

  final StorageService _storage;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  static bool _timeZonesInitialized = false;

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

      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
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
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
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

      const androidDetails = AndroidNotificationDetails(
        reminderChannelId,
        reminderChannelName,
        channelDescription: reminderChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTime = _nextInstanceOfTime(hour, minute);

      await _plugin.zonedSchedule(
        id: reminderNotificationId,
        title: '今日精進功課',
        body: '開啟念佛計數器填寫今日功課數吧！',
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleDailyReminder error: $e');
    }
  }

  /// 發送即時測試通知或里程碑慶賀
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'buddha_milestone',
        '目標達成通知',
        channelDescription: '發送目標達成與精進里程碑通知',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
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
