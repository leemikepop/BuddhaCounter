import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/practice/practice_controller.dart';
import '../../../features/practice/session_stopwatch.dart';
import '../../../features/settings/settings_controller.dart';
import '../../../features/settings/tap_feedback.dart';
import '../../../l10n/l10n.dart';
import '../../common/app_toast.dart';
import '../theme/modern_palette.dart';
import '../widgets/counter_controls.dart';
import '../widgets/goal_picker.dart';
import '../widgets/zen_circle_counter.dart';

/// 現代模式「手動計數」分頁：碼表、大圓計數盤、目標 / 減一 / 歸零、音效與震動設定
class ModernCounterView extends StatelessWidget {
  const ModernCounterView({super.key});

  @override
  Widget build(BuildContext context) {
    final fullscreenTap =
        context.select<SettingsController, bool>((s) => s.fullscreenTap);
    final practice = context.read<PracticeController>();

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: const [
          _Stopwatch(),
          SizedBox(height: 18),
          _CounterDisc(),
          SizedBox(height: 18),
          _CounterActions(),
          SizedBox(height: 14),
          _FeedbackSettingsCard(),
          SizedBox(height: 16),
        ],
      ),
    );

    if (!fullscreenTap) return content;
    // 全螢幕盲按：點畫面任何位置都算一聲
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: practice.increment,
      child: content,
    );
  }
}

class _Stopwatch extends StatelessWidget {
  const _Stopwatch();

  @override
  Widget build(BuildContext context) {
    final stopwatch = context.watch<SessionStopwatch>();
    return TimerPill(
      time: stopwatch.formatted,
      isRunning: stopwatch.isRunning,
      onToggle: stopwatch.toggle,
      onReset: stopwatch.reset,
    );
  }
}

class _CounterDisc extends StatelessWidget {
  const _CounterDisc();

  @override
  Widget build(BuildContext context) {
    final (count, target) = context.select<PracticeController, (int, int)>(
        (p) => (p.count, p.targetCount));
    return ZenCircleCounter(
      count: count,
      targetCount: target,
      size: 260,
      onTap: context.read<PracticeController>().increment,
    );
  }
}

class _CounterActions extends StatelessWidget {
  const _CounterActions();

  @override
  Widget build(BuildContext context) {
    final (count, target) = context.select<PracticeController, (int, int)>(
        (p) => (p.count, p.targetCount));
    final practice = context.read<PracticeController>();
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: GoalChip(
            icon: Icons.flag_outlined,
            label: target > 0
                ? l10n.goalChipLabel(target)
                : l10n.goalChipUnlimited,
            onTap: () => showCountGoalPicker(
              context,
              title: l10n.manualGoalSheetTitle,
              current: target,
              onSelected: practice.setTargetCount,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SmallOutlinedAction(
          icon: Icons.remove_circle_outline_rounded,
          label: l10n.counterMinusOne,
          onPressed: count > 0 ? practice.decrement : null,
        ),
        const SizedBox(width: 8),
        SmallOutlinedAction(
          icon: Icons.refresh_rounded,
          label: l10n.counterResetShort,
          destructive: true,
          onPressed: () => confirmReset(
            context,
            title: l10n.counterResetConfirmTitle,
            body: l10n.counterResetConfirmBody(count),
            confirmLabel: l10n.counterResetConfirmAction,
            onConfirm: () {
              practice.resetCount();
              AppToast.show(context, l10n.counterResetDoneToast);
            },
          ),
        ),
      ],
    );
  }
}

/// 音效選擇、震動回饋與全螢幕盲按開關
class _FeedbackSettingsCard extends StatelessWidget {
  const _FeedbackSettingsCard();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final palette = ModernPalette.of(context);
    final l10n = context.l10n;

    ButtonSegment<SoundEffectType> segment(
            SoundEffectType type, String label) =>
        ButtonSegment(
          value: type,
          label: Text(label, style: const TextStyle(fontSize: 12)),
        );

    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.volume_up_outlined,
                    size: 18, color: palette.primary),
                const SizedBox(width: 6),
                Text(
                  l10n.soundEffectTitle,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SegmentedButton<SoundEffectType>(
                    showSelectedIcon: false,
                    segments: [
                      segment(
                          SoundEffectType.woodfish1, l10n.soundChipWoodfish1),
                      segment(
                          SoundEffectType.woodfish2, l10n.soundChipWoodfish2),
                      segment(SoundEffectType.bell, l10n.soundChipBell),
                      segment(SoundEffectType.none, l10n.soundChipMute),
                    ],
                    selected: {settings.soundEffect},
                    onSelectionChanged: (selection) {
                      settings.setSoundEffect(selection.first);
                      context.read<TapFeedback>().preview(selection.first);
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _LabeledSwitch(
                    label: l10n.vibrationFeedback,
                    value: settings.vibrationEnabled,
                    onChanged: settings.setVibrationEnabled,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LabeledSwitch(
                    label: l10n.fullscreenTap,
                    value: settings.fullscreenTap,
                    onChanged: settings.setFullscreenTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 整列可點的開關 (不用 ListTile，避免卡片內的 DecoratedBox 警告)
class _LabeledSwitch extends StatelessWidget {
  const _LabeledSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
