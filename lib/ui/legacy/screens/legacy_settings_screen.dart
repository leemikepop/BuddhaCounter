import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/storage_service.dart';
import '../../../features/settings/locale_controller.dart';
import '../../../features/settings/settings_controller.dart';
import '../../../features/settings/tap_feedback.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/sound_effect_labels.dart';
import '../../common/app_toast.dart';
import '../../common/language_picker.dart';
import '../widgets/legacy_widgets.dart';

/// 經典模式設定頁：螢幕常亮、敲擊音效、介面模式、語言 (沿用最早 Android 版 MainActivity3)
class LegacySettingsScreen extends StatelessWidget {
  const LegacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final appLanguage =
        context.select<LocaleController, AppLanguage>((l) => l.appLanguage);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: legacyAppBar(context.l10n.legacySettingsTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 螢幕常亮（防止休眠）設定
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                context.l10n.legacyKeepScreenOnTitle,
                style: const TextStyle(
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
              value: settings.keepScreenOn,
              onChanged: (val) {
                settings.setKeepScreenOn(val);
                AppToast.show(
                  context,
                  val
                      ? context.l10n.screenAwakeOn
                      : context.l10n.screenAwakeOffToast,
                );
              },
            ),

            const Divider(height: 32),

            // 敲擊音效設定
            Text(
              context.l10n.legacyClickSoundTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0000FF),
              ),
            ),
            const SizedBox(height: 8),

            RadioGroup<SoundEffectType>(
              groupValue: settings.soundEffect,
              onChanged: (val) {
                if (val != null) {
                  settings.setSoundEffect(val);
                  context.read<TapFeedback>().preview(val);
                }
              },
              child: Column(
                children: [
                  RadioListTile<SoundEffectType>(
                    title: Text(soundEffectLabel(
                        context.l10n, SoundEffectType.woodfish1)),
                    value: SoundEffectType.woodfish1,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text(soundEffectLabel(
                        context.l10n, SoundEffectType.woodfish2)),
                    value: SoundEffectType.woodfish2,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text(
                        soundEffectLabel(context.l10n, SoundEffectType.bell)),
                    value: SoundEffectType.bell,
                  ),
                  RadioListTile<SoundEffectType>(
                    title: Text(
                        soundEffectLabel(context.l10n, SoundEffectType.none)),
                    value: SoundEffectType.none,
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            // 介面風格切換（經典 Legacy / 現代 Modern）
            Text(
              context.l10n.legacyUiModeTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0000FF),
              ),
            ),
            const SizedBox(height: 8),

            RadioGroup<AppUiMode>(
              groupValue: settings.uiMode,
              onChanged: (val) {
                if (val != null) {
                  settings.setUiMode(val);
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
              subtitle: Text(appLanguageLabel(context.l10n, appLanguage)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLanguagePicker(context),
            ),

            const SizedBox(height: 24),

            LegacyPlainButton(
              text: context.l10n.legacySaveAndBack,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
