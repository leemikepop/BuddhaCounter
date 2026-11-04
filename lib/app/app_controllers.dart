import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../core/services/audio_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/practice_record_service.dart';
import '../core/services/storage_service.dart';
import '../features/auto_count/auto_count_controller.dart';
import '../features/playback/playback_controller.dart';
import '../features/practice/practice_controller.dart';
import '../features/practice/session_stopwatch.dart';
import '../features/settings/locale_controller.dart';
import '../features/settings/settings_controller.dart';
import '../features/settings/tap_feedback.dart';

/// 組裝 App 所有的 controller (正式 App 與測試共用同一套接線)。
///
/// 畫面以 `context.watch<XxxController>()` 只監聽自己需要的那一個，
/// 例如計時器每秒跳動只會重繪自動計數頁，不會重繪播放器或月曆。
class AppControllers {
  AppControllers._({
    required this.settings,
    required this.feedback,
    required this.locale,
    required this.practice,
    required this.stopwatch,
    required this.playback,
    required this.autoCount,
  });

  factory AppControllers.create({
    required StorageService storage,
    required AudioService audio,
    NotificationService? notifications,
    PracticeRecordService? records,
    List<Locale>? deviceLocales,
  }) {
    notifications ??= NotificationService(storage);
    records ??= PracticeRecordService(storage);

    final settings = SettingsController(storage);
    final feedback = TapFeedback(audio, settings);
    // 語言要最先套用：曲目名稱、小工具與通知文字都依賴它
    final locale = LocaleController(
      storage: storage,
      records: records,
      notifications: notifications,
      audio: audio,
      deviceLocales: deviceLocales,
    );
    final practice = PracticeController(
      storage: storage,
      records: records,
      notifications: notifications,
      feedback: feedback,
    );
    final playback = PlaybackController(audio: audio, storage: storage);
    final autoCount = AutoCountController(
      playback: playback,
      practice: practice,
      storage: storage,
    );

    return AppControllers._(
      settings: settings,
      feedback: feedback,
      locale: locale,
      practice: practice,
      stopwatch: SessionStopwatch(),
      playback: playback,
      autoCount: autoCount,
    );
  }

  final SettingsController settings;
  final TapFeedback feedback;
  final LocaleController locale;
  final PracticeController practice;
  final SessionStopwatch stopwatch;
  final PlaybackController playback;
  final AutoCountController autoCount;

  /// 把所有 controller 提供給 [child] 底下的畫面
  Widget provide({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider.value(value: feedback),
        ChangeNotifierProvider.value(value: locale),
        ChangeNotifierProvider.value(value: practice),
        ChangeNotifierProvider.value(value: stopwatch),
        ChangeNotifierProvider.value(value: playback),
        ChangeNotifierProvider.value(value: autoCount),
      ],
      child: child,
    );
  }

  void dispose() {
    autoCount.dispose();
    playback.dispose();
    stopwatch.dispose();
    practice.dispose();
    locale.dispose();
    settings.dispose();
  }
}
