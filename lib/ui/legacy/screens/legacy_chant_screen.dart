import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';

/// 經典念佛頁面 (忠實復刻原 MainActivity2 & activity_main_activity2.xml)
class LegacyChantScreen extends StatefulWidget {
  const LegacyChantScreen({super.key});

  @override
  State<LegacyChantScreen> createState() => _LegacyChantScreenState();
}

class _LegacyChantScreenState extends State<LegacyChantScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CounterViewModel>();
      vm.applyScreenWakelockForCurrentPage(vm.keepScreenChant);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('念佛頁面'),
        backgroundColor: const Color(0xFF0000FF),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 阿彌陀佛聖像
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.asset(
                  'assets/images/amitabha735x659.jpg',
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/amitabha768x1024.png',
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 大回向西方文標題
              const Text(
                ChantConstants.huiXiangTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // 回向偈頌文句
              ...ChantConstants.huiXiangVerses.map(
                (verse) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    verse,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 南無阿彌陀佛
              const Text(
                '南無阿彌陀佛',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0000FF),
                ),
              ),

              const SizedBox(height: 20),

              // 返回按鈕
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('返回首頁', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
