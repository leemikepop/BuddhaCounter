import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/auto_count/auto_count_controller.dart';
import '../../../features/settings/settings_controller.dart';
import '../../../l10n/l10n.dart';
import '../../common/app_toast.dart';
import '../../common/screen_toggle_buttons.dart';
import '../views/modern_calendar_view.dart';
import '../views/modern_counter_view.dart';
import '../views/modern_practice_view.dart';
import '../views/modern_timer_view.dart';
import '../widgets/modern_drawer.dart';
import '../widgets/modern_floating_player.dart';
import '../widgets/modern_guide_dialog.dart';

/// 現代模式主畫面：四個可左右滑動的分頁 + 底部常駐浮動播放器
class ModernCounterScreen extends StatefulWidget {
  const ModernCounterScreen({super.key});

  /// 分頁順序
  static const int manualTab = 0;
  static const int autoTab = 1;
  static const int dedicationTab = 2;
  static const int calendarTab = 3;

  /// 平板上內容的最大寬度：超過就置中，兩側留白 (手機寬度不受影響)
  static const double maxContentWidth = 600;

  @override
  State<ModernCounterScreen> createState() => _ModernCounterScreenState();
}

class _ModernCounterScreenState extends State<ModernCounterScreen> {
  int _tab = ModernCounterScreen.manualTab;
  late final PageController _pageController;
  late final AutoCountController _autoCount;
  late final SettingsController _settings;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tab);
    _autoCount = context.read<AutoCountController>();
    _settings = context.read<SettingsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyTabEffects(_tab);
      if (!_settings.hasSeenModernGuide) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) ModernGuideDialog.show(context);
        });
      }
    });
  }

  @override
  void dispose() {
    // 切到經典模式時離開自動計數分頁
    _autoCount.setScreenVisible(false);
    _pageController.dispose();
    super.dispose();
  }

  /// 自動計數分頁上播放鍵就是開始計數；功課月曆分頁不需要螢幕常亮
  void _applyTabEffects(int tab) {
    _autoCount.setScreenVisible(tab == ModernCounterScreen.autoTab);
    _settings.applyWakelock(allowed: tab != ModernCounterScreen.calendarTab);
  }

  void _onPageChanged(int tab) {
    setState(() => _tab = tab);
    _applyTabEffects(tab);
  }

  void _goToTab(int tab) {
    _onPageChanged(tab);
    _pageController.animateToPage(
      tab,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      (Icons.touch_app_outlined, Icons.touch_app_rounded, l10n.tabManual),
      (Icons.timer_outlined, Icons.timer_rounded, l10n.tabAuto),
      (Icons.spa_outlined, Icons.spa_rounded, l10n.tabDedication),
      (
        Icons.calendar_month_outlined,
        Icons.calendar_month_rounded,
        l10n.tabCalendar
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tabs[_tab].$3,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          const OrientationLockButton(),
          const KeepScreenOnButton(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.style_outlined),
            tooltip: l10n.switchToClassicMode,
            onPressed: () {
              _settings.setUiMode(AppUiMode.legacy);
              AppToast.show(context, l10n.switchedToClassicToast);
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip:
                isDark ? l10n.themeToLightTooltip : l10n.themeToDarkTooltip,
            onPressed: () {
              _settings.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
              AppToast.show(
                context,
                isDark
                    ? l10n.themeSwitchedLightToast
                    : l10n.themeSwitchedDarkToast,
              );
            },
          ),
        ],
      ),
      drawer: ModernDrawer(currentTab: _tab, onSelectTab: _goToTab),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: ModernCounterScreen.maxContentWidth),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: const [
                      RepaintBoundary(child: ModernCounterView()),
                      RepaintBoundary(child: ModernTimerView()),
                      RepaintBoundary(child: ModernPracticeView()),
                      RepaintBoundary(child: ModernCalendarView()),
                    ],
                  ),
                ),
                const ModernFloatingPlayer(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goToTab,
        destinations: [
          for (final (icon, selectedIcon, label) in tabs)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selectedIcon),
              label: label,
            ),
        ],
      ),
    );
  }
}
