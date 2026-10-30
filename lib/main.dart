import 'package:audio_service/audio_service.dart' as bg_audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/chant_songs.dart';
import 'core/services/audio_service.dart';
import 'core/services/chant_audio_handler.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/widget_service.dart';
import 'features/counter/counter_view_model.dart';
import 'ui/legacy/screens/legacy_counter_screen.dart';
import 'ui/modern/screens/modern_counter_screen.dart';
import 'ui/modern/theme/modern_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 設定邊界至邊界 (Edge-to-Edge) 沉浸式系統 UI 模式與透明導航列/狀態列
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // 優先載入 31 首佛曲音檔內嵌之 Metadata（title / 參與演出者 artist / 專輯 album）
  await ChantConstants.loadMetadataFromAssets();

  // 初始化系統級音訊媒體會話服務 (Android MediaSession & iOS NowPlayingCenter)
  ChantAudioHandler? audioHandler;
  try {
    audioHandler = await bg_audio.AudioService.init(
      builder: () => ChantAudioHandler(),
      config: const bg_audio.AudioServiceConfig(
        androidNotificationChannelId:
            'com.yichung.lee.buddha_counter.channel.audio',
        androidNotificationChannelName: '念佛計數器佛曲播放',
        androidNotificationChannelDescription: '保持螢幕休眠或退至背景時佛曲持續播放',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'drawable/ic_stat_music',
      ),
    );
  } catch (e) {
    debugPrint('AudioService.init error: $e');
  }

  // 初始化儲存與音訊服務
  final storageService = await StorageService.init();
  final audioService = AudioService(handler: audioHandler);

  // 初始化桌面小工具與定時提醒通知服務
  await WidgetService.init();
  final notificationService = NotificationService(storageService);
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CounterViewModel(
            storage: storageService,
            audio: audioService,
            notifications: notificationService,
          ),
        ),
      ],
      child: const BuddhaCounterApp(),
    ),
  );
}

class BuddhaCounterApp extends StatelessWidget {
  static final ThemeData _legacyTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0000FF)),
    useMaterial3: true,
  );

  const BuddhaCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 僅訂閱 UI 模式與深淺色主題變化，避免計數或音訊播放時重複重建整棵 MaterialApp
    final (uiMode, themeMode) = context.select<CounterViewModel, (AppUiMode, ThemeMode)>(
      (vm) => (vm.uiMode, vm.themeMode),
    );

    return MaterialApp(
      title: '念佛計數器',
      debugShowCheckedModeBanner: false,
      themeMode: (uiMode == AppUiMode.legacy) ? ThemeMode.light : themeMode,
      theme: (uiMode == AppUiMode.legacy)
          ? _legacyTheme
          : ModernTheme.lightTheme,
      darkTheme: (uiMode == AppUiMode.legacy)
          ? _legacyTheme
          : ModernTheme.darkTheme,
      // 根據使用者設定自動切換【經典復古模式 (Legacy)】或【現代禪意模式 (Modern)】
      home: uiMode == AppUiMode.legacy
          ? const LegacyCounterScreen()
          : const ModernCounterScreen(),
    );
  }
}
