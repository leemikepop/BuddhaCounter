import 'dart:async';
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
import 'l10n/l10n.dart';
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

  // 先初始化儲存服務，以便依使用者語言偏好決定啟動語言 (背景播放通知頻道名稱需在 runApp 前建立)
  final storageService = await StorageService.init();
  final startupL10n = lookupAppLocalizations(resolveAppLocale(
    WidgetsBinding.instance.platformDispatcher.locales,
    storageService.getAppLanguage(),
  ));

  // 初始化系統級音訊媒體會話服務 (Android MediaSession & iOS NowPlayingCenter)
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

  // 初始化音訊服務
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

class BuddhaCounterApp extends StatefulWidget {
  const BuddhaCounterApp({super.key});

  @override
  State<BuddhaCounterApp> createState() => _BuddhaCounterAppState();
}

class _BuddhaCounterAppState extends State<BuddhaCounterApp>
    with WidgetsBindingObserver {
  static final ThemeData _legacyTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0000FF)),
    useMaterial3: true,
  );

  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 每 30 秒定期檢查跨日換日（半夜 12 點）
    _midnightTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        context.read<CounterViewModel>().checkDateRollover();
      }
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // 手機系統語言變更：設定為「跟隨系統」時即時切換
    context.read<CounterViewModel>().updateDeviceLocales(locales ?? const []);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 當 App 切換回前台或喚醒時，檢查跨日重設並同步桌面小工具數據
      final vm = context.read<CounterViewModel>();
      vm.checkDateRollover();
      vm.refreshWidgetData();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // 當 App 退至背景、切換視窗或鎖定螢幕時，立即強制將最新計數同步至桌面小工具
      context.read<CounterViewModel>().flushPracticeRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 僅訂閱 UI 模式與深淺色主題變化，避免計數或音訊播放時重複重建整棵 MaterialApp
    final (uiMode, themeMode, locale) =
        context.select<CounterViewModel, (AppUiMode, ThemeMode, Locale)>(
      (vm) => (vm.uiMode, vm.themeMode, vm.locale),
    );

    return MaterialApp(
      onGenerateTitle: (ctx) => ctx.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
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
