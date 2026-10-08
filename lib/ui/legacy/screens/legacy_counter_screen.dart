import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/counter/counter_view_model.dart';
import 'legacy_chant_screen.dart';
import 'legacy_auto_count_screen.dart';
import 'legacy_music_list_screen.dart';
import 'legacy_settings_screen.dart';
import 'legacy_about_screen.dart';

/// 經典模式主計數畫面 (忠實復刻原 Android MainActivity.java & activity_main.xml)
class LegacyCounterScreen extends StatefulWidget {
  const LegacyCounterScreen({super.key});

  @override
  State<LegacyCounterScreen> createState() => _LegacyCounterScreenState();
}

class _LegacyCounterScreenState extends State<LegacyCounterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CounterViewModel>();
      vm.applyScreenWakelockForCurrentPage(vm.keepScreenHome);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0000FF),
        foregroundColor: Colors.white,
        title: const Text(
          '念佛、拜佛記數器',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '阿忠小站',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegacyAboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部藍底白字聖號橫幅
            Container(
              width: double.infinity,
              color: const Color(0xFF0000FF),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text(
                '南無阿彌陀佛',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            // 功能橫列 1（米黃色背景 #FBFFE5）
            Container(
              color: const Color(0xFFFBFFE5),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildClassicButton(
                    text: '歸0',
                    onPressed: () => vm.resetCount(),
                  ),
                  _buildClassicButton(
                    text: '減1',
                    onPressed: () => vm.decrement(),
                  ),
                  _buildClassicButton(
                    text: '念佛',
                    onPressed: () => vm.increment(),
                  ),
                  _buildClassicButton(
                    text: '念佛頁',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LegacyChantScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 大計數數字顯示（米黃色背景）
            Container(
              width: double.infinity,
              color: const Color(0xFFFBFFE5),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${vm.count}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            // 中央巨大「按我」主點擊按鈕（淺藍色 #A1C9FF）
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA1C9FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () => vm.increment(),
                    child: const Text(
                      '按我',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 底部控制區與計時器（淡綠色 #DAFFE8）
            Container(
              color: const Color(0xFFDAFFE8),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // 控制列
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildClassicButton(
                          text: '計數頁',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LegacyAutoCountScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        _buildClassicButton(
                          text: '開始',
                          onPressed: () => vm.startTimer(),
                        ),
                        const SizedBox(width: 4),
                        _buildClassicButton(
                          text: '停止',
                          onPressed: () => vm.stopTimer(),
                        ),
                        const SizedBox(width: 4),
                        _buildClassicButton(
                          text: '歸零',
                          onPressed: () => vm.resetTimer(),
                        ),
                        const SizedBox(width: 4),
                        _buildClassicButton(
                          text: '佛曲',
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
                  const SizedBox(height: 6),

                  // 計時器顯示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '計時：',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        vm.formattedTimer,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0E0E0),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(60, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xFF9E9E9E)),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
