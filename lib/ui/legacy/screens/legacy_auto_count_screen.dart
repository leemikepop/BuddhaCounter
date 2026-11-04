import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/auto_count/auto_count_controller.dart';
import '../../../features/playback/playback_controller.dart';
import '../../../features/practice/practice_controller.dart';
import '../../../features/settings/settings_controller.dart';
import '../../../l10n/l10n.dart';
import '../../common/screen_toggle_buttons.dart';
import '../widgets/legacy_widgets.dart';

/// 經典模式自動計數頁 (沿用最早 Android 版 Main6Activity 的版面)
class LegacyAutoCountScreen extends StatefulWidget {
  const LegacyAutoCountScreen({super.key});

  @override
  State<LegacyAutoCountScreen> createState() => _LegacyAutoCountScreenState();
}

class _LegacyAutoCountScreenState extends State<LegacyAutoCountScreen> {
  final TextEditingController _stopMinutes = TextEditingController(text: '0');
  late final AutoCountController _autoCount;

  @override
  void initState() {
    super.initState();
    _autoCount = context.read<AutoCountController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 在這頁按「念佛」就是開始自動計數
      _autoCount.setScreenVisible(true);
      context.read<SettingsController>().applyWakelock();
      if (_autoCount.stopMinutes > 0) {
        _stopMinutes.text = '${_autoCount.stopMinutes}';
      }
    });
  }

  @override
  void dispose() {
    _stopMinutes.dispose();
    _autoCount.setScreenVisible(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const bigBold = TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
    const bigTabular = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    const mediumBold = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: legacyAppBar(
        l10n.legacyAutoTitle,
        actions: const [OrientationLockButton(), KeepScreenOnButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const LegacyBanner(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const _SongDropdown(),
                    // 計時
                    _Band(
                      color: LegacyColors.mint,
                      child: Selector<AutoCountController, String>(
                        selector: (_, a) => a.formattedElapsed,
                        builder: (_, time, __) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.legacyTimerLabel, style: bigBold),
                            Text(time, style: bigTabular),
                          ],
                        ),
                      ),
                    ),
                    // 音訊「時長 : 位置」(按下方「音訊」切換顯示)
                    _Band(
                      color: const Color(0xFFDAFFAA),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.legacyAudioLabel, style: bigBold),
                          const _AudioPositionText(style: bigTabular),
                        ],
                      ),
                    ),
                    // 幾分鐘後自動停止
                    Container(
                      color: const Color(0xFF99FFBB),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.legacyAutoStopLabel, style: mediumBold),
                          SizedBox(
                            width: 60,
                            height: 40,
                            child: TextField(
                              controller: _stopMinutes,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: mediumBold,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (v) => _autoCount
                                  .setStopMinutes(int.tryParse(v) ?? 0),
                            ),
                          ),
                          Text(l10n.legacyMinutesLater, style: mediumBold),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      color: LegacyColors.cream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Selector<PracticeController, int>(
                        selector: (_, p) => p.autoCount,
                        builder: (_, count, __) => Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _BottomActions(),
          ],
        ),
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        color: color,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: child,
      );
}

/// 曲目下拉選單 (只選曲，不會自動開始播放)
class _SongDropdown extends StatelessWidget {
  const _SongDropdown();

  @override
  Widget build(BuildContext context) {
    final songId =
        context.select<PlaybackController, int>((p) => p.currentSongId);
    return Container(
      color: const Color(0xFFF2FFDA),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            context.l10n.legacyAutoSongButton,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<int>(
              isExpanded: true,
              value: songId,
              items: [
                for (final s in ChantConstants.allSongs)
                  DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(
                      s.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id != null) {
                  context.read<PlaybackController>().selectSong(id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 「時長 : 位置」(秒，小數一位)；未開啟顯示時為 `0.0 : 0.0`
class _AudioPositionText extends StatelessWidget {
  const _AudioPositionText({required this.style});

  final TextStyle style;

  static String _seconds(Duration d) =>
      (d.inMilliseconds / 1000).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final show =
        context.select<AutoCountController, bool>((a) => a.showAudioPosition);
    if (!show) return Text('0.0 : 0.0', style: style);
    final playback = context.read<PlaybackController>();
    return ListenableBuilder(
      listenable: Listenable.merge(
          [playback.positionListenable, playback.durationListenable]),
      builder: (_, __) => Text(
        '${_seconds(playback.duration)} : ${_seconds(playback.position)}',
        style: style,
      ),
    );
  }
}

/// 返回、歸零、念佛 (開始 / 暫停計數)、音訊顯示
class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    final (isCounting, showAudio) =
        context.select<AutoCountController, (bool, bool)>(
            (a) => (a.isCounting, a.showAudioPosition));
    final autoCount = context.read<AutoCountController>();
    final l10n = context.l10n;
    Color? activeIf(bool on) => on ? LegacyColors.blue : null;

    return Container(
      color: LegacyColors.cream,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          LegacyButton(
            text: l10n.commonBack,
            horizontalPadding: 16,
            minHeight: 40,
            onPressed: () {
              if (autoCount.isCounting) autoCount.stop();
              Navigator.pop(context);
            },
          ),
          LegacyButton(
            text: l10n.legacyResetZero,
            horizontalPadding: 16,
            minHeight: 40,
            onPressed: context.read<PracticeController>().resetAutoCount,
          ),
          LegacyButton(
            text: l10n.legacyChant,
            horizontalPadding: 16,
            minHeight: 40,
            textColor: activeIf(isCounting),
            onPressed: autoCount.toggle,
          ),
          LegacyButton(
            text: l10n.legacyAudio,
            horizontalPadding: 16,
            minHeight: 40,
            textColor: activeIf(showAudio),
            onPressed: autoCount.toggleShowAudioPosition,
          ),
        ],
      ),
    );
  }
}
