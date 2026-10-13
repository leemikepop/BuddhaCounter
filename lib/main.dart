import 'package:audio_service/audio_service.dart' as bg_audio;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/audio_service.dart';
import 'core/services/chant_audio_handler.dart';
import 'core/services/storage_service.dart';
import 'features/counter/counter_view_model.dart';
import 'ui/legacy/screens/legacy_counter_screen.dart';
import 'ui/modern/screens/modern_counter_screen.dart';
import 'ui/modern/theme/modern_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
  } catch (e) {
    debugPrint('AudioService.init error: $e');
  }

  // 初始化儲存與音訊服務
  final storageService = await StorageService.init();
  final audioService = AudioService(handler: audioHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CounterViewModel(
            storage: storageService,
            audio: audioService,
          ),
        ),
      ],
      child: const BuddhaCounterApp(),
    ),
  );
}

class BuddhaCounterApp extends StatelessWidget {
  const BuddhaCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();

    return MaterialApp(
      title: '念佛計數器',
      debugShowCheckedModeBanner: false,
      themeMode:
          (vm.uiMode == AppUiMode.legacy) ? ThemeMode.light : vm.themeMode,
      theme: (vm.uiMode == AppUiMode.legacy)
          ? ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF0000FF)),
              useMaterial3: true,
            )
          : ModernTheme.lightTheme,
      darkTheme: (vm.uiMode == AppUiMode.legacy)
          ? ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF0000FF)),
              useMaterial3: true,
            )
          : ModernTheme.darkTheme,
      // 根據使用者設定自動切換【經典復古模式 (Legacy)】或【現代禪意模式 (Modern)】
      home: vm.uiMode == AppUiMode.legacy
          ? const LegacyCounterScreen()
          : const ModernCounterScreen(),
    );
  }
}
