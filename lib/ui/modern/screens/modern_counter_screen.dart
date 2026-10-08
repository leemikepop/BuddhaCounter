import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../legacy/screens/legacy_chant_screen.dart';
import '../../legacy/screens/legacy_music_list_screen.dart';
import '../../legacy/screens/legacy_settings_screen.dart';
import '../../legacy/screens/legacy_about_screen.dart';

/// 現代禪意風格計數畫面 (未來擴充之全新現代化介面，與經典模式無縫共用同一個狀態模型)
class ModernCounterScreen extends StatefulWidget {
  const ModernCounterScreen({super.key});

  @override
  State<ModernCounterScreen> createState() => _ModernCounterScreenState();
}

class _ModernCounterScreenState extends State<ModernCounterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CounterViewModel>();
      vm.applyScreenWakelockForCurrentPage(vm.keepScreenHome);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapCount(CounterViewModel vm) {
    _animController.reverse().then((_) => _animController.forward());
    vm.increment();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2), // 禪意米白
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          '念佛計數器 · 禪意模式',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: '切換回經典模式 (Legacy)',
            onPressed: () {
              vm.setUiMode(AppUiMode.legacy);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已切換為經典復古模式')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegacySettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF4A6572)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    '南無阿彌陀佛',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '心平氣和 · 淨念相繼',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text('念佛頁面 (回向文)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegacyChantScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_music),
              title: const Text('佛曲清單'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegacyMusicListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('偏好設定'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegacySettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('阿忠小站 · 緣起傳承'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegacyAboutScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('切換至經典模式 (Legacy)'),
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
            const SizedBox(height: 20),

            // 偈頌提示
            const Text(
              '「都攝六根，淨念相繼」',
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 3,
                color: Color(0xFF757575),
                fontStyle: FontStyle.italic,
              ),
            ),

            const Spacer(),

            // 圓形禪意計數按鈕
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () => _onTapCount(vm),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A6572).withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFD6C7A1),
                        width: 4,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${vm.count}',
                          style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '點擊念佛',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8D6E63),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // 快捷控制按鈕群
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.refresh),
                    tooltip: '歸零',
                    onPressed: () => vm.resetCount(),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    tooltip: '減 1',
                    onPressed: () => vm.decrement(),
                  ),
                  IconButton.filledTonal(
                    icon: Icon(vm.isTimerRunning ? Icons.pause : Icons.play_arrow),
                    tooltip: vm.isTimerRunning ? '暫停計時' : '開始計時',
                    onPressed: () {
                      if (vm.isTimerRunning) {
                        vm.stopTimer();
                      } else {
                        vm.startTimer();
                      }
                    },
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.queue_music),
                    tooltip: '佛曲',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LegacyMusicListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 底部計時條
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '計時修持：${vm.formattedTimer}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
