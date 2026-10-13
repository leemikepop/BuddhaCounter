import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../common/app_toast.dart';

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
            // 螢幕常亮（防止休眠）設定
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '保持螢幕常亮（防止休眠）',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0000FF),
                ),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '開啟後計數、念佛與播放佛曲時不會自動關閉螢幕，亦可直接於各頁面頂部右上角快捷鍵切換',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              value: vm.isCurrentScreenAwake,
              onChanged: (val) {
                vm.setScreenAwake(val);
                AppToast.show(
                  context,
                  val ? '螢幕常亮' : '已關閉螢幕常亮',
                );
              },
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
                    title: Text('木魚一'),
                    value: SoundEffectType.woodfish1,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text('木魚二'),
                    value: SoundEffectType.woodfish2,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text('木魚三 (經典原音)'),
                    value: SoundEffectType.woodfish3,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text('引磬聲'),
                    value: SoundEffectType.bell,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text('靜音'),
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
                    AppToast.show(context, '已切換為現代模式');
                  }
                }
              },
              child: const Column(
                children: [
                  RadioListTile<AppUiMode>(
                    title: Text('經典模式'),
                    value: AppUiMode.legacy,
                  ),
                  RadioListTile<AppUiMode>(
                    title: Text('現代模式'),
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
              child: const Text('儲存並返回', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
