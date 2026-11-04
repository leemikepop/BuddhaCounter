import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/playback/playback_controller.dart';
import '../../../features/practice/practice_controller.dart';
import '../../../features/practice/session_stopwatch.dart';
import '../../../features/settings/settings_controller.dart';
import '../../../features/settings/tap_feedback.dart';
import '../../../l10n/l10n.dart';
import '../../common/app_toast.dart';
import '../../common/screen_toggle_buttons.dart';
import '../../modern/views/modern_calendar_view.dart';
import '../../modern/widgets/modern_guide_dialog.dart';
import '../widgets/legacy_widgets.dart';
import 'legacy_about_screen.dart';
import 'legacy_auto_count_screen.dart';
import 'legacy_chant_screen.dart';
import 'legacy_music_list_screen.dart';
import 'legacy_settings_screen.dart';

/// 經典模式首頁：手動計數 (沿用最早 Android 版 MainActivity 的版面)
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
      if (!mounted) return;
      final settings = context.read<SettingsController>();
      settings.applyWakelock();
      if (!settings.hasSeenModernGuide) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showNewVersionIntro();
        });
      }
    });
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _switchToModern() {
    context.read<SettingsController>().setUiMode(AppUiMode.modern);
    AppToast.show(context, context.l10n.switchedToModernToast);
  }

  /// 第一次開啟時介紹現代模式
  void _showNewVersionIntro() {
    final settings = context.read<SettingsController>();
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: LegacyColors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: LegacyColors.blue, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.legacyUpgradeTitle,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.legacyUpgradeBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        settings.markModernGuideSeen();
                      },
                      child: Text(l10n.legacyKeepClassic),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: LegacyColors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        settings.setUiMode(AppUiMode.modern);
                        ModernGuideDialog.show(context);
                      },
                      child: Text(
                        l10n.legacyTryModern,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: legacyAppBar(
        l10n.tabManual,
        boldTitle: true,
        actions: [
          const OrientationLockButton(),
          const KeepScreenOnButton(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.style_outlined),
            tooltip: l10n.legacySwitchToModern,
            onPressed: _switchToModern,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.settings),
            tooltip: l10n.legacySettingsTitle,
            onPressed: () => _push(const LegacySettingsScreen()),
          ),
        ],
      ),
      drawer: _LegacyDrawer(push: _push, onSwitchToModern: _switchToModern),
      body: SafeArea(
        child: Column(
          children: [
            const LegacyBanner(),
            _TopActions(
                onOpenDedication: () => _push(const LegacyChantScreen())),
            const Expanded(child: _TapToCountButton()),
            _BottomPanel(push: _push),
          ],
        ),
      ),
    );
  }
}

/// 歸零、減一、念佛 (播放 / 暫停)、迴向頁
class _TopActions extends StatelessWidget {
  const _TopActions({required this.onOpenDedication});

  final VoidCallback onOpenDedication;

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        context.select<PlaybackController, bool>((p) => p.isPlaying);
    final practice = context.read<PracticeController>();
    final l10n = context.l10n;
    return Container(
      color: LegacyColors.cream,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          LegacyButton(
              text: l10n.legacyResetZero, onPressed: practice.resetCount),
          LegacyButton(
              text: l10n.legacyMinusOne, onPressed: practice.decrement),
          LegacyButton(
            text: l10n.legacyChant,
            textColor: isPlaying ? LegacyColors.blue : null,
            onPressed: () {
              context.read<TapFeedback>().sound();
              context.read<PlaybackController>().togglePlayPause();
            },
          ),
          LegacyButton(
              text: l10n.legacyDedicationPage, onPressed: onOpenDedication),
        ],
      ),
    );
  }
}

/// 中央的大按鈕：點一下算一聲，直接顯示計數 (橫向時也不會消失)
class _TapToCountButton extends StatelessWidget {
  const _TapToCountButton();

  @override
  Widget build(BuildContext context) {
    final count = context.select<PracticeController, int>((p) => p.count);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: LegacyColors.lightBlue,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            elevation: 3,
          ),
          onPressed: context.read<PracticeController>().increment,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部：自動計數頁、碼表控制、佛曲清單，以及碼表時間
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.push});

  final void Function(Widget screen) push;

  @override
  Widget build(BuildContext context) {
    final stopwatch = context.watch<SessionStopwatch>();
    final l10n = context.l10n;
    const timerStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    const gap = SizedBox(width: 4);

    return Container(
      color: LegacyColors.mint,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                LegacyButton(
                  text: l10n.legacyCounterPage,
                  onPressed: () => push(const LegacyAutoCountScreen()),
                ),
                gap,
                LegacyButton(
                    text: l10n.commonStart, onPressed: stopwatch.start),
                gap,
                LegacyButton(text: l10n.legacyStop, onPressed: stopwatch.stop),
                gap,
                LegacyButton(
                    text: l10n.counterResetShort, onPressed: stopwatch.reset),
                gap,
                LegacyButton(
                  text: l10n.legacySongs,
                  onPressed: () => push(const LegacyMusicListScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.legacyTimerLabel, style: timerStyle),
              Text(stopwatch.formatted, style: timerStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegacyDrawer extends StatelessWidget {
  const _LegacyDrawer({required this.push, required this.onSwitchToModern});

  final void Function(Widget screen) push;
  final VoidCallback onSwitchToModern;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // 導覽結束時選單已關閉，先取得 controller
    final settings = context.read<SettingsController>();

    Widget item(IconData icon, String title, VoidCallback onTap,
            {String? subtitle, Color? iconColor}) =>
        ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
        );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: LegacyColors.blue),
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
                  l10n.practiceBuddhaName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          item(Icons.timer_outlined, l10n.tabAuto,
              () => push(const LegacyAutoCountScreen())),
          item(Icons.auto_stories, l10n.tabDedication,
              () => push(const LegacyChantScreen())),
          item(
            Icons.calendar_month_rounded,
            l10n.legacyCalendarMenu,
            () => push(Scaffold(
              appBar: AppBar(title: Text(l10n.legacyCalendarMenu)),
              body: const SafeArea(child: ModernCalendarView()),
            )),
          ),
          const Divider(),
          item(Icons.library_music, l10n.legacySongListTitle,
              () => push(const LegacyMusicListScreen())),
          const Divider(),
          item(Icons.settings, l10n.legacyPreferences,
              () => push(const LegacySettingsScreen())),
          item(Icons.info_outline, l10n.drawerAbout,
              () => push(const LegacyAboutScreen())),
          const Divider(),
          item(
            Icons.school_outlined,
            l10n.drawerGuide,
            iconColor: LegacyColors.blue,
            subtitle: l10n.legacyGuideSubtitle,
            () => ModernGuideDialog.show(
              context,
              onComplete: () => settings.setUiMode(AppUiMode.modern),
            ),
          ),
          item(Icons.style_outlined, l10n.legacySwitchToModern,
              onSwitchToModern),
        ],
      ),
    );
  }
}
