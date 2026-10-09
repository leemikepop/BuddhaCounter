import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../legacy/screens/legacy_about_screen.dart';
import '../../common/app_toast.dart';
import '../views/modern_counter_view.dart';
import '../views/modern_timer_view.dart';
import '../views/modern_practice_view.dart';
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

  final List<String> _tabTitles = const [
    '手動計數',
    '自動計數',
    '迴向',
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
      AppToast.show(context, '已切換為淺色模式');
    } else {
      vm.setThemeMode(ThemeMode.dark);
      AppToast.show(context, '已切換為深色模式');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabTitles[_currentTabIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // 1. 螢幕方向鎖定
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              vm.isOrientationLocked
                  ? Icons.screen_lock_rotation_rounded
                  : Icons.screen_rotation_rounded,
            ),
            tooltip: vm.isOrientationLocked ? '解除方向鎖定' : '鎖定螢幕方向',
            onPressed: () {
              final orientation = MediaQuery.of(context).orientation;
              vm.toggleOrientationLock(orientation);
              AppToast.show(
                context,
                vm.isOrientationLocked ? '已鎖定螢幕方向' : '已解除方向鎖定',
              );
            },
          ),
          // 2. 螢幕常亮（防止休眠）
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              vm.isCurrentScreenAwake
                  ? Icons.remove_red_eye_rounded
                  : Icons.visibility_off_outlined,
            ),
            tooltip: vm.isCurrentScreenAwake ? '關閉螢幕常亮' : '螢幕常亮',
            onPressed: () {
              vm.toggleCurrentScreenAwake();
              AppToast.show(
                context,
                vm.isCurrentScreenAwake ? '螢幕常亮' : '已關閉螢幕常亮',
              );
            },
          ),
          // 3. 切換至經典模式
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.style_outlined),
            tooltip: '切換回經典模式',
            onPressed: () {
              vm.setUiMode(AppUiMode.legacy);
              AppToast.show(context, '已切換為經典模式');
            },
          ),
          // 4. 快速切換深色 / 淺色模式
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? '切換為淺色模式' : '切換為深色模式',
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '念佛、拜佛記數器',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '南無阿彌陀佛',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.touch_app_rounded),
              title: const Text('手動計數'),
              selected: _currentTabIndex == 0,
              onTap: () {
                Navigator.pop(context);
                _onTabSelect(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('自動計數'),
              selected: _currentTabIndex == 1,
              onTap: () {
                Navigator.pop(context);
                _onTabSelect(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.spa_rounded),
              title: const Text('迴向'),
              selected: _currentTabIndex == 2,
              onTap: () {
                Navigator.pop(context);
                _onTabSelect(2);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('選擇佛曲清單'),
              onTap: () {
                Navigator.pop(context);
                ModernFloatingPlayer.openSongPicker(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('新版功能導覽教學'),
              onTap: () {
                Navigator.pop(context);
                ModernGuideDialog.show(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('阿忠小站 · 緣起傳承'),
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
              leading: const Icon(Icons.history_edu_rounded),
              title: const Text('切換回經典模式'),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.touch_app_outlined),
            selectedIcon: Icon(Icons.touch_app_rounded),
            label: '手動計數',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded),
            label: '自動計數',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa_rounded),
            label: '迴向',
          ),
        ],
      ),
    );
  }
}
