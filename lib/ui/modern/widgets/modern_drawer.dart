import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/settings/locale_controller.dart';
import '../../../features/settings/settings_controller.dart';
import '../../../l10n/l10n.dart';
import '../../common/language_picker.dart';
import '../../legacy/screens/legacy_about_screen.dart';
import 'modern_floating_player.dart';
import 'modern_guide_dialog.dart';

/// 現代模式側邊選單：分頁捷徑、佛曲清單、使用導覽、關於、語言、切換經典模式
class ModernDrawer extends StatelessWidget {
  const ModernDrawer({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
  });

  final int currentTab;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appLanguage =
        context.select<LocaleController, AppLanguage>((l) => l.appLanguage);

    /// 先關閉選單再執行動作
    VoidCallback closeThen(VoidCallback action) => () {
          Navigator.pop(context);
          action();
        };

    Widget tabItem(int tab, IconData icon, String title) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          selected: currentTab == tab,
          onTap: closeThen(() => onSelectTab(tab)),
        );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF22242B) : theme.colorScheme.primary,
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
          tabItem(0, Icons.touch_app_rounded, l10n.tabManual),
          tabItem(1, Icons.timer_outlined, l10n.tabAuto),
          tabItem(2, Icons.spa_rounded, l10n.tabDedication),
          tabItem(3, Icons.calendar_month_rounded, l10n.tabCalendar),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: Text(l10n.drawerSongList),
            onTap:
                closeThen(() => ModernFloatingPlayer.openSongPicker(context)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(l10n.drawerGuide),
            onTap: closeThen(() => ModernGuideDialog.show(context)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.drawerAbout),
            onTap: closeThen(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegacyAboutScreen()),
                )),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: Text(l10n.languageMenuTitle),
            subtitle: Text(appLanguageLabel(l10n, appLanguage)),
            onTap: () => showLanguagePicker(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history_edu_rounded),
            title: Text(l10n.switchToClassicMode),
            onTap: closeThen(() =>
                context.read<SettingsController>().setUiMode(AppUiMode.legacy)),
          ),
        ],
      ),
    );
  }
}
