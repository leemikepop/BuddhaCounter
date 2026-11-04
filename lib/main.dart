import 'package:audio_service/audio_service.dart' as bg_audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_controllers.dart';
import 'app/buddha_counter_app.dart';
import 'core/constants/chant_songs.dart';
import 'core/services/audio_service.dart';
import 'core/services/chant_audio_handler.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/widget_service.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 內容延伸到狀態列與導航列底下 (透明系統列)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // 先讀各音檔內嵌的曲名 / 演出者 / 專輯
  await ChantConstants.loadMetadataFromAssets();

  // 背景播放的通知頻道名稱要在 runApp 前決定，所以先依語言偏好解析啟動語言
  final storage = await StorageService.init();
  final startupL10n = lookupAppLocalizations(resolveAppLocale(
    WidgetsBinding.instance.platformDispatcher.locales,
    storage.getAppLanguage(),
  ));

  // 系統媒體控制 (Android MediaSession / iOS 控制中心)
  ChantAudioHandler? audioHandler;
  try {
    audioHandler = await bg_audio.AudioService.init(
      builder: () => ChantAudioHandler(),
      config: bg_audio.AudioServiceConfig(
        androidNotificationChannelId:
            'com.yichung.lee.buddha_counter.channel.audio',
        androidNotificationChannelName: startupL10n.audioChannelName,
        androidNotificationChannelDescription: startupL10n.audioChannelDesc,
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'drawable/ic_stat_music',
      ),
    );
  } catch (e) {
    debugPrint('AudioService.init error: $e');
  }

  await WidgetService.init();
  final notifications = NotificationService(storage);
  await notifications.init();

  final controllers = AppControllers.create(
    storage: storage,
    audio: AudioService(handler: audioHandler),
    notifications: notifications,
  );

  runApp(controllers.provide(child: const BuddhaCounterApp()));
}
