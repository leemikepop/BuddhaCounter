import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';

/// 經典設定頁面 (忠實復刻原 MainActivity3 & activity_main_activity3.xml + 現代/經典模式切換)
class LegacySettingsScreen extends StatelessWidget {
  const LegacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFF0000FF),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 螢幕休眠設定標題
            const Text(
              '螢幕常亮（防止休眠）設定',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0000FF),
              ),
            ),
            const SizedBox(height: 8),

            CheckboxListTile(
              title: const Text('首頁不休眠', style: TextStyle(fontSize: 16)),
              value: vm.keepScreenHome,
              onChanged: (val) => vm.setKeepScreenHome(val ?? false),
            ),
            CheckboxListTile(
              title: const Text('念佛頁不休眠', style: TextStyle(fontSize: 16)),
              value: vm.keepScreenChant,
              onChanged: (val) => vm.setKeepScreenChant(val ?? false),
            ),
            CheckboxListTile(
              title: const Text('佛曲頁不休眠', style: TextStyle(fontSize: 16)),
              value: vm.keepScreenSongs,
              onChanged: (val) => vm.setKeepScreenSongs(val ?? false),
            ),
            CheckboxListTile(
              title: const Text('記數頁不休眠', style: TextStyle(fontSize: 16)),
              value: vm.keepScreenAuto,
              onChanged: (val) => vm.setKeepScreenAuto(val ?? false),
            ),

            const Divider(height: 32),

            // 敲擊音效設定
            const Text(
              '點擊計數音效',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0000FF),
              ),
            ),
            const SizedBox(height: 8),

            RadioGroup<SoundEffectType>(
              groupValue: vm.soundEffect,
              onChanged: (val) {
                if (val != null) {
                  vm.setSoundEffect(val);
                  vm.audioService.playClickSfx(val);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<SoundEffectType>(
                    title: Text('木魚聲 (預設)'),
                    subtitle: Text('沉穩定心，傳統佛門法器'),
                    value: SoundEffectType.woodfish,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text('引磬聲'),
                    subtitle: Text('清脆悠揚，警策精進'),
                    value: SoundEffectType.bell,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text('靜音'),
                    subtitle: Text('無聲點擊計數'),
                    value: SoundEffectType.none,
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            // 介面風格切換（經典 Legacy / 現代 Modern）
            const Text(
              '介面模式切換',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0000FF),
              ),
            ),
            const SizedBox(height: 8),

            RadioGroup<AppUiMode>(
              groupValue: vm.uiMode,
              onChanged: (val) {
                if (val != null) {
                  vm.setUiMode(val);
                  if (val == AppUiMode.modern) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已切換為現代禪意模式')),
                    );
                  }
                }
              },
              child: const Column(
                children: [
                  RadioListTile<AppUiMode>(
                    title: Text('經典復古模式 (Legacy)'),
                    subtitle: Text('父親原創高對比大字體版面，老用戶與長輩無縫延續使用習慣'),
                    value: AppUiMode.legacy,
                  ),
                  RadioListTile<AppUiMode>(
                    title: Text('現代禪意模式 (Modern)'),
                    subtitle: Text('新版極簡設計風格，支援圓環計數、現代手勢與深色沉浸修持'),
                    value: AppUiMode.modern,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0E0E0),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('完成並返回', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
