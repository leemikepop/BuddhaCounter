import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/storage_service.dart';
import '../features/practice/practice_controller.dart';
import '../features/settings/locale_controller.dart';
import '../features/settings/settings_controller.dart';
import '../l10n/l10n.dart';
import '../ui/common/tablet_scale.dart';
import '../ui/legacy/screens/legacy_counter_screen.dart';
import '../ui/modern/screens/modern_counter_screen.dart';
import '../ui/modern/theme/modern_theme.dart';
import '../ui/web/web_frame.dart';

/// App 根元件：依設定切換經典 / 現代介面、主題與語言，並處理前景 / 背景切換
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
    // App 開著跨過午夜時，今日計數也要歸零
    _midnightTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<PracticeController>().checkDateRollover();
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
    // 語言設為「跟隨系統」時，手機改語言立即生效
    context.read<LocaleController>().updateDeviceLocales(locales ?? const []);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final practice = context.read<PracticeController>();
    switch (state) {
      case AppLifecycleState.resumed:
        practice.checkDateRollover();
        practice.refreshWidgetData();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // 退到背景前把最新計數推送到桌面小工具
        practice.flushWidgetSync();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (uiMode, themeMode) =
        context.select<SettingsController, (AppUiMode, ThemeMode)>(
            (s) => (s.uiMode, s.themeMode));
    final locale = context.select<LocaleController, Locale>((l) => l.locale);
    final isLegacy = uiMode == AppUiMode.legacy;

    return MaterialApp(
      onGenerateTitle: (ctx) => ctx.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      debugShowCheckedModeBanner: false,
      // 經典模式固定淺色
      themeMode: isLegacy ? ThemeMode.light : themeMode,
      theme: isLegacy ? _legacyTheme : ModernTheme.lightTheme,
      darkTheme: isLegacy ? _legacyTheme : ModernTheme.darkTheme,
      // 網頁版：電腦上維持手機寬度置中、手機瀏覽器建議下載 App (原生 App 原樣通過)
      // 平板：整個 App 等比放大 (手機與網頁不變)
      builder: (context, child) => WebFrame(child: TabletScale(child: child!)),
      home:
          isLegacy ? const LegacyCounterScreen() : const ModernCounterScreen(),
    );
  }
}
