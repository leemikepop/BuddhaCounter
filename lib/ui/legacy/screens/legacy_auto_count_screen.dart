import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';

/// 經典念佛自動計數頁面 (忠實復刻原 Main6Activity & activity_main6.xml)
class LegacyAutoCountScreen extends StatefulWidget {
  const LegacyAutoCountScreen({super.key});

  @override
  State<LegacyAutoCountScreen> createState() => _LegacyAutoCountScreenState();
}

class _LegacyAutoCountScreenState extends State<LegacyAutoCountScreen> {
  final TextEditingController _stopMinController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CounterViewModel>();
      vm.applyScreenWakelockForCurrentPage(vm.keepScreenAuto);
      if (vm.autoStopMinutes > 0) {
        _stopMinController.text = vm.autoStopMinutes.toString();
      }
    });
  }

  @override
  void dispose() {
    _stopMinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final songs = ChantConstants.getAllSongs();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('念佛自動計數'),
        backgroundColor: const Color(0xFF0000FF),
        foregroundColor: Colors.white,
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

            // 控制區塊
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 曲目下拉選單區（淡黃綠背景 #F2FFDA）
                    Container(
                      color: const Color(0xFFF2FFDA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Text(
                            '念佛\n曲目',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: vm.currentSongId,
                              items: songs.map((s) {
                                return DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(
                                    s.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (id) {
                                if (id != null) {
                                  vm.selectSong(id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 計時顯示區（淡薄荷綠 #DAFFE8）
                    Container(
                      color: const Color(0xFFDAFFE8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '計時：',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            vm.formattedAutoTimer,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 音訊顯示區（淺黃綠 #DAFFAA，點擊下方「音訊」按鈕切換顯示/隱藏）
                    Container(
                      color: const Color(0xFFDAFFAA),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '音訊：',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            vm.formattedAudioPosition,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 自動關閉設定區（淡薄荷翠綠 #99FFBB）
                    Container(
                      color: const Color(0xFF99FFBB),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '自動關閉：',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 60,
                            height: 40,
                            child: TextField(
                              controller: _stopMinController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (val) {
                                final mins = int.tryParse(val) ?? 0;
                                vm.setAutoStopMinutes(mins);
                              },
                            ),
                          ),
                          const Text(
                            ' 分鐘後',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 計數數字顯示
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFFBFFE5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '${vm.autoCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部操作橫列（米黃底）
            Container(
              color: const Color(0xFFFBFFE5),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(
                    '返回',
                    () {
                      if (vm.isAutoCounting) {
                        vm.stopAutoCount();
                      }
                      Navigator.pop(context);
                    },
                  ),
                  _buildButton('歸0', () => vm.resetAutoCount()),
                  _buildButton(
                    '念佛',
                    () => vm.toggleAutoCount(),
                    textColor: vm.isAutoCounting ? const Color(0xFF0000FF) : Colors.black,
                  ),
                  _buildButton(
                    '音訊',
                    () => vm.toggleShowAudioPosition(),
                    textColor: vm.showAudioPosition ? const Color(0xFF0000FF) : Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    Color? textColor,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0E0E0),
        foregroundColor: textColor ?? Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(60, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xFF9E9E9E)),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.black,
        ),
      ),
    );
  }
}
