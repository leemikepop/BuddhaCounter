import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/sound_effect_labels.dart';
import '../../common/language_picker.dart';
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
        title: Text(context.l10n.legacySettingsTitle),
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
              title: Text(
                context.l10n.legacyKeepScreenOnTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0000FF),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.l10n.legacyKeepScreenOnDesc,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              value: vm.isCurrentScreenAwake,
              onChanged: (val) {
                vm.setScreenAwake(val);
                AppToast.show(
                  context,
                  val ? context.l10n.screenAwakeOn : context.l10n.screenAwakeOffToast,
                );
              },
            ),

            const Divider(height: 32),

            // 敲擊音效設定
            Text(
              context.l10n.legacyClickSoundTitle,
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
              child: Column(
                children: [
                  RadioListTile<SoundEffectType>(
                    title: Text(soundEffectLabel(context.l10n, SoundEffectType.woodfish1)),
                    value: SoundEffectType.woodfish1,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text(soundEffectLabel(context.l10n, SoundEffectType.woodfish2)),
                    value: SoundEffectType.woodfish2,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text(soundEffectLabel(context.l10n, SoundEffectType.bell)),
                    value: SoundEffectType.bell,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text(soundEffectLabel(context.l10n, SoundEffectType.none)),
                    value: SoundEffectType.none,
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            // 介面風格切換（經典 Legacy / 現代 Modern）
            Text(
              context.l10n.legacyUiModeTitle,
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
                    AppToast.show(context, context.l10n.switchedToModernToast);
                  }
                }
              },
              child: Column(
                children: [
                  RadioListTile<AppUiMode>(
                    title: Text(context.l10n.legacyClassicMode),
                    value: AppUiMode.legacy,
                  ),
                  RadioListTile<AppUiMode>(
                    title: Text(context.l10n.legacyModernMode),
                    value: AppUiMode.modern,
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            // 語言設定
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                context.l10n.languageMenuTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0000FF),
                ),
              ),
              subtitle: Text(appLanguageLabel(context.l10n, vm.appLanguage)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLanguagePicker(context),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0E0E0),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.legacySaveAndBack, style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
