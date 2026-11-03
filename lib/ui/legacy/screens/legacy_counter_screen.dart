import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';
import 'legacy_chant_screen.dart';
import 'legacy_auto_count_screen.dart';
import 'legacy_music_list_screen.dart';
import 'legacy_settings_screen.dart';
import 'legacy_about_screen.dart';
import '../../common/app_toast.dart';
import '../../modern/widgets/modern_guide_dialog.dart';
import '../../modern/views/modern_calendar_view.dart';

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
      if (!vm.hasSeenModernGuide) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _showNewVersionIntro(context, vm);
          }
        });
      }
    });
  }

  void _showNewVersionIntro(BuildContext context, CounterViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0000FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF0000FF),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.legacyUpgradeTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.legacyUpgradeBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          vm.markModernGuideSeen();
                        },
                        child: Text(context.l10n.legacyKeepClassic),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0000FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          vm.setUiMode(AppUiMode.modern);
                          ModernGuideDialog.show(context);
                        },
                        child: Text(
                          context.l10n.legacyTryModern,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0000FF),
        foregroundColor: Colors.white,
        title: Text(
          context.l10n.tabManual,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // 1. 螢幕方向鎖定
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              vm.isOrientationLocked
                  ? Icons.screen_lock_rotation_rounded
                  : Icons.screen_rotation_rounded,
            ),
            tooltip: vm.isOrientationLocked ? context.l10n.orientationUnlockTooltip : context.l10n.orientationLockTooltip,
            onPressed: () {
              final orientation = MediaQuery.of(context).orientation;
              vm.toggleOrientationLock(orientation);
              AppToast.show(
                context,
                vm.isOrientationLocked ? context.l10n.orientationLockedToast : context.l10n.legacyUnlockedToast,
              );
            },
          ),
          // 2. 螢幕常亮
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              vm.isCurrentScreenAwake
                  ? Icons.remove_red_eye_rounded
                  : Icons.visibility_off_outlined,
            ),
            tooltip: vm.isCurrentScreenAwake ? context.l10n.screenAwakeOffTooltip : context.l10n.screenAwakeOn,
            onPressed: () {
              vm.toggleCurrentScreenAwake();
              AppToast.show(
                context,
                vm.isCurrentScreenAwake ? context.l10n.screenAwakeOn : context.l10n.screenAwakeOffToast,
              );
            },
          ),
          // 3. 切換至現代模式
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.style_outlined),
            tooltip: context.l10n.legacySwitchToModern,
            onPressed: () {
              vm.setUiMode(AppUiMode.modern);
              AppToast.show(context, context.l10n.switchedToModernToast);
            },
          ),
          // 4. 設定
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.settings),
            tooltip: context.l10n.legacySettingsTitle,
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
              decoration: const BoxDecoration(color: Color(0xFF0000FF)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    context.l10n.drawerHeaderTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.practiceBuddhaName,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(context.l10n.tabAuto),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LegacyAutoCountScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: Text(context.l10n.tabDedication),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegacyChantScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: Text(context.l10n.legacyCalendarMenu),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: Text(context.l10n.legacyCalendarMenu),
                      ),
                      body: const SafeArea(child: ModernCalendarView()),
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.library_music),
              title: Text(context.l10n.legacySongListTitle),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LegacyMusicListScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(context.l10n.legacyPreferences),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LegacySettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.l10n.drawerAbout),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegacyAboutScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.school_outlined, color: Color(0xFF0000FF)),
              title: Text(context.l10n.drawerGuide),
              subtitle: Text(context.l10n.legacyGuideSubtitle),
              onTap: () {
                Navigator.pop(context);
                ModernGuideDialog.show(
                  context,
                  onComplete: () {
                    vm.setUiMode(AppUiMode.modern);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.style_outlined),
              title: Text(context.l10n.legacySwitchToModern),
              onTap: () {
                Navigator.pop(context);
                vm.setUiMode(AppUiMode.modern);
                AppToast.show(context, context.l10n.switchedToModernToast);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部藍底白字聖號橫幅
            Container(
              width: double.infinity,
              color: const Color(0xFF0000FF),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                context.l10n.practiceBuddhaName,
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
                    text: context.l10n.legacyResetZero,
                    onPressed: () => vm.resetCount(),
                  ),
                  _buildClassicButton(
                    text: context.l10n.legacyMinusOne,
                    onPressed: () => vm.decrement(),
                  ),
                  _buildClassicButton(
                    text: context.l10n.legacyChant,
                    textColor: vm.isChantPlaying
                        ? const Color(0xFF0000FF)
                        : Colors.black,
                    onPressed: () => vm.toggleHomeChant(),
                  ),
                  _buildClassicButton(
                    text: context.l10n.legacyDedicationPage,
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

            // 中央巨大點擊按鈕（淺藍色 #A1C9FF），直接顯示計數數字（避免橫向時按鈕消失）
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${vm.count}',
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
                          text: context.l10n.legacyCounterPage,
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
                          text: context.l10n.commonStart,
                          onPressed: () => vm.startTimer(),
                        ),
                        const SizedBox(width: 4),
                        _buildClassicButton(
                          text: context.l10n.legacyStop,
                          onPressed: () => vm.stopTimer(),
                        ),
                        const SizedBox(width: 4),
                        _buildClassicButton(
                          text: context.l10n.counterResetShort,
                          onPressed: () => vm.resetTimer(),
                        ),
                        const SizedBox(width: 4),
                        _buildClassicButton(
                          text: context.l10n.legacySongs,
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
                      Text(
                        context.l10n.legacyTimerLabel,
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
    Color? textColor,
  }) {
    final color = textColor ?? Colors.black;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0E0E0),
        foregroundColor: color,
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
        style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
