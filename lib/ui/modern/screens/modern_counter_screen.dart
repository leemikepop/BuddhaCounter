import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../../l10n/l10n.dart';
import '../../common/language_picker.dart';
import '../../legacy/screens/legacy_about_screen.dart';
import '../../common/app_toast.dart';
import '../views/modern_counter_view.dart';
import '../views/modern_timer_view.dart';
import '../views/modern_practice_view.dart';
import '../views/modern_calendar_view.dart';
import '../widgets/modern_floating_player.dart';
import '../widgets/modern_guide_dialog.dart';

/// 現代禪意模式主導航視圖
/// 特色：
/// 1. 支援水平左右滑動切換頁面 (PageView)
/// 2. 下方常駐浮動佛曲播放器，旁附一鍵選曲清單
/// 3. 頂部簡約計時碼表（置於計數頁最上方）
/// 4. 完美深色/淺色禪意主題切換
class ModernCounterScreen extends StatefulWidget {
  const ModernCounterScreen({super.key});

  @override
  State<ModernCounterScreen> createState() => _ModernCounterScreenState();
}

class _ModernCounterScreenState extends State<ModernCounterScreen> {
  int _currentTabIndex = 0;
  late final PageController _pageController;

  List<String> _tabTitles(AppLocalizations l10n) => [
        l10n.tabManual,
        l10n.tabAuto,
        l10n.tabDedication,
        l10n.tabCalendar,
      ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CounterViewModel>();
      vm.setActiveTabIndex(_currentTabIndex);
      vm.applyScreenWakelockForCurrentPage(vm.isCurrentScreenAwake);
      if (!vm.hasSeenModernGuide) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ModernGuideDialog.show(context);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelect(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    context.read<CounterViewModel>().setActiveTabIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleThemeQuickly(CounterViewModel vm, bool isDark) {
    if (isDark) {
      vm.setThemeMode(ThemeMode.light);
      AppToast.show(context, context.l10n.themeSwitchedLightToast);
    } else {
      vm.setThemeMode(ThemeMode.dark);
      AppToast.show(context, context.l10n.themeSwitchedDarkToast);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 僅監聽 AppBar 圖示所需狀態，避免播放佛曲、計時或點擊計數時重建整頁 Scaffold 與 PageView
    final (isOrientationLocked, isCurrentScreenAwake) =
        context.select<CounterViewModel, (bool, bool)>(
      (vm) => (vm.isOrientationLocked, vm.isCurrentScreenAwake),
    );
    final vm = context.read<CounterViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabTitles(l10n)[_currentTabIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // 1. 螢幕方向鎖定
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isOrientationLocked
                  ? Icons.screen_lock_rotation_rounded
                  : Icons.screen_rotation_rounded,
            ),
            tooltip: isOrientationLocked
                ? l10n.orientationUnlockTooltip
                : l10n.orientationLockTooltip,
            onPressed: () {
              final orientation = MediaQuery.of(context).orientation;
              vm.toggleOrientationLock(orientation);
              AppToast.show(
                context,
                vm.isOrientationLocked
                    ? l10n.orientationLockedToast
                    : l10n.orientationUnlockedToast,
              );
            },
          ),
          // 2. 螢幕常亮（防止休眠）
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isCurrentScreenAwake
                  ? Icons.remove_red_eye_rounded
                  : Icons.visibility_off_outlined,
            ),
            tooltip: isCurrentScreenAwake
                ? l10n.screenAwakeOffTooltip
                : l10n.screenAwakeOn,
            onPressed: () {
              vm.toggleCurrentScreenAwake();
              AppToast.show(
                context,
                vm.isCurrentScreenAwake
                    ? l10n.screenAwakeOn
                    : l10n.screenAwakeOffToast,
              );
            },
          ),
          // 3. 切換至經典模式
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.style_outlined),
            tooltip: l10n.switchToClassicMode,
            onPressed: () {
              vm.setUiMode(AppUiMode.legacy);
              AppToast.show(context, l10n.switchedToClassicToast);
            },
          ),
          // 4. 快速切換深色 / 淺色模式
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? l10n.themeToLightTooltip : l10n.themeToDarkTooltip,
            onPressed: () => _toggleThemeQuickly(vm, isDark),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF22242B) : primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    l10n.drawerHeaderTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.drawerHeaderSubtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.touch_app_rounded),
              title: Text(l10n.tabManual),
              selected: _currentTabIndex == 0,
              onTap: () {
                Navigator.pop(context);
                _onTabSelect(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.tabAuto),
              selected: _currentTabIndex == 1,
              onTap: () {
                Navigator.pop(context);
                _onTabSelect(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.spa_rounded),
              title: Text(l10n.tabDedication),
              selected: _currentTabIndex == 2,
              onTap: () {
                Navigator.pop(context);
                _onTabSelect(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: Text(l10n.tabCalendar),
              selected: _currentTabIndex == 3,
              onTap: () {
                Navigator.pop(context);
                _onTabSelect(3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: Text(l10n.drawerSongList),
              onTap: () {
                Navigator.pop(context);
                ModernFloatingPlayer.openSongPicker(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(l10n.drawerGuide),
              onTap: () {
                Navigator.pop(context);
                ModernGuideDialog.show(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.drawerAbout),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegacyAboutScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(context.l10n.languageMenuTitle),
              subtitle: Text(appLanguageLabel(context.l10n, vm.appLanguage)),
              onTap: () => showLanguagePicker(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history_edu_rounded),
              title: Text(l10n.switchToClassicMode),
              onTap: () {
                Navigator.pop(context);
                vm.setUiMode(AppUiMode.legacy);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 可左右滑動的分頁視圖 (PageView)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                  context.read<CounterViewModel>().setActiveTabIndex(index);
                },
                children: const [
                  RepaintBoundary(child: ModernCounterView()),
                  RepaintBoundary(child: ModernTimerView()),
                  RepaintBoundary(child: ModernPracticeView()),
                  RepaintBoundary(child: ModernCalendarView()),
                ],
              ),
            ),

            // 下方常駐浮動佛曲播放器（附帶播放清單選單鈕）
            const ModernFloatingPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: _onTabSelect,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.touch_app_outlined),
            selectedIcon: Icon(Icons.touch_app_rounded),
            label: l10n.tabManual,
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded),
            label: l10n.tabAuto,
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa_rounded),
            label: l10n.tabDedication,
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: l10n.tabCalendar,
          ),
        ],
      ),
    );
  }
}
