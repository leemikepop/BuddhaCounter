import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/auto_count/auto_count_controller.dart';
import '../../../features/playback/playback_controller.dart';
import '../../../features/practice/practice_controller.dart';
import '../../../l10n/l10n.dart';
import '../../common/app_toast.dart';
import '../theme/modern_palette.dart';
import '../widgets/counter_controls.dart';
import '../widgets/goal_picker.dart';

/// 現代模式「自動計數」分頁，版面和手動計數一致：
/// 碼表、圓形計數盤 (含停止條件進度環)、停止條件 / 減一 / 重置、開始暫停大按鈕
class ModernTimerView extends StatelessWidget {
  const ModernTimerView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          _ElapsedTimer(),
          SizedBox(height: 18),
          _AutoCountDisc(),
          SizedBox(height: 18),
          _AutoCountActions(),
          SizedBox(height: 20),
          _StartPauseButton(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// 達成停止條件時的顏色
const Color _reachedColor = Color(0xFF4CAF50);

class _ElapsedTimer extends StatelessWidget {
  const _ElapsedTimer();

  @override
  Widget build(BuildContext context) {
    final autoCount = context.watch<AutoCountController>();
    return TimerPill(
      time: autoCount.formattedElapsed,
      isRunning: autoCount.isCounting,
      onToggle: autoCount.toggle,
      onReset: () {
        // 只重置計時，聲數保留
        autoCount.resetElapsed();
        AppToast.show(context, context.l10n.autoTimerResetToast);
      },
    );
  }
}

/// 停止條件的進度與標示 (念滿聲數 / 定時停止 / 不限)
class _StopGoal {
  _StopGoal(AutoCountController auto, AppLocalizations l10n) {
    final countGoal = auto.targetCount;
    final timeGoal = auto.stopMinutes;
    hasGoal = countGoal > 0 || timeGoal > 0;
    if (countGoal > 0) {
      progress = auto.targetProgress;
      reached = auto.isTargetReached;
      label = reached
          ? l10n.goalReachedLabel(countGoal)
          : l10n.goalProgressLabel(countGoal, (progress * 100).toInt());
      chipLabel = l10n.goalChipLabel(countGoal);
      icon = Icons.flag_outlined;
    } else if (timeGoal > 0) {
      progress = auto.stopElapsedProgress;
      reached = auto.stopRemainingSeconds == 0;
      label = reached
          ? l10n.autoTimeReachedLabel(timeGoal)
          : l10n.autoTimeProgressLabel(
              timeGoal, _formatRemaining(l10n, auto.stopRemainingSeconds));
      chipLabel = l10n.autoTimerChip(timeGoal);
      icon = Icons.hourglass_bottom_rounded;
    } else {
      chipLabel = l10n.autoContinuous;
      icon = Icons.all_inclusive_rounded;
    }
  }

  late final bool hasGoal;
  double progress = 0;
  bool reached = false;
  String? label;
  late final String chipLabel;
  late final IconData icon;

  static String _formatRemaining(AppLocalizations l10n, int seconds) {
    if (seconds >= 60) return l10n.autoRemainingMinutes((seconds / 60).ceil());
    return l10n.autoRemainingSeconds(seconds);
  }
}

class _AutoCountDisc extends StatelessWidget {
  const _AutoCountDisc();

  static const double _size = 256;

  @override
  Widget build(BuildContext context) {
    final auto = context.watch<AutoCountController>();
    final count = context.select<PracticeController, int>((p) => p.autoCount);
    final songId =
        context.select<PlaybackController, int>((p) => p.currentSongId);
    final song = ChantConstants.getSongById(songId);
    final palette = ModernPalette.of(context);
    final primary = palette.primary;
    final l10n = context.l10n;
    final goal = _StopGoal(auto, l10n);
    final accent = goal.reached ? _reachedColor : primary;

    // 停止條件進度環是靜態的 (數值變動才重繪)，不是轉圈動畫
    return RepaintBoundary(
      child: GestureDetector(
        onTap: auto.toggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : primary.withValues(alpha: 0.12),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (goal.hasGoal)
                SizedBox(
                  width: _size,
                  height: _size,
                  child: CircularProgressIndicator(
                    value: goal.progress,
                    strokeWidth: 6,
                    backgroundColor: palette.isDark
                        ? const Color(0xFF2B2E37)
                        : const Color(0xFFEBE3D5),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              Container(
                width: _size - 24,
                height: _size - 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: palette.isDark
                        ? const [Color(0xFF282B34), Color(0xFF1B1D23)]
                        : [palette.surface, const Color(0xFFF7F2E9)],
                  ),
                  border: Border.all(
                    color: palette.isDark
                        ? const Color(0xFF383C48)
                        : const Color(0xFFEDE5D8),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      auto.isCounting
                          ? Icons.auto_mode_rounded
                          : Icons.spa_rounded,
                      size: 26,
                      color: goal.reached
                          ? _reachedColor
                          : primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 58,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                            color: palette.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.autoCircleUnitLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: palette.mutedText,
                        letterSpacing: 2.0,
                      ),
                    ),
                    if (goal.label case final label?) ...[
                      const SizedBox(height: 10),
                      _Pill(text: label, color: accent, strong: goal.reached),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      l10n.autoBeatHint(song.beatSeconds),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: palette.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, required this.strong});

  final String text;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: strong ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _AutoCountActions extends StatelessWidget {
  const _AutoCountActions();

  @override
  Widget build(BuildContext context) {
    final auto = context.watch<AutoCountController>();
    final count = context.select<PracticeController, int>((p) => p.autoCount);
    final practice = context.read<PracticeController>();
    final l10n = context.l10n;
    final goal = _StopGoal(auto, l10n);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: GoalChip(
            icon: goal.icon,
            label: goal.chipLabel,
            onTap: () => _showStopConditionSheet(context),
          ),
        ),
        const SizedBox(width: 8),
        SmallOutlinedAction(
          icon: Icons.remove_circle_outline_rounded,
          label: l10n.counterMinusOne,
          onPressed: count > 0 ? practice.decrementAuto : null,
        ),
        const SizedBox(width: 8),
        // 只重置聲數，計時保留
        SmallOutlinedAction(
          icon: Icons.refresh_rounded,
          label: l10n.autoResetShort,
          destructive: true,
          onPressed: () {
            if (count == 0) {
              AppToast.show(context, l10n.autoAlreadyZeroToast);
              return;
            }
            confirmReset(
              context,
              title: l10n.autoResetConfirmTitle,
              body: l10n.autoResetConfirmBody(count),
              confirmLabel: l10n.autoResetConfirmAction,
              onConfirm: () {
                practice.resetAutoCount();
                AppToast.show(context, l10n.autoResetDoneToast);
              },
            );
          },
        ),
      ],
    );
  }
}

class _StartPauseButton extends StatelessWidget {
  const _StartPauseButton();

  @override
  Widget build(BuildContext context) {
    final isCounting =
        context.select<AutoCountController, bool>((a) => a.isCounting);
    final palette = ModernPalette.of(context);
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: isCounting ? 0 : 3,
          shadowColor: palette.primary.withValues(alpha: 0.3),
        ),
        onPressed: context.read<AutoCountController>().toggle,
        icon: Icon(
          isCounting ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 24,
        ),
        label: Text(
          isCounting ? l10n.commonPause : l10n.commonStart,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}

/// 停止條件面板：「念滿聲數」與「定時停止」二擇一，設定其中一項會清掉另一項
void _showStopConditionSheet(BuildContext context) {
  final auto = context.read<AutoCountController>();
  showGoalSheet(
    context,
    title: context.l10n.autoStopSheetTitle,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final l10n = ctx.l10n;
      void done(String message) {
        Navigator.pop(ctx);
        AppToast.show(context, message);
      }

      Widget sectionTitle(IconData icon, String text) => Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              l10n.autoStopExclusiveHint,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          sectionTitle(Icons.flag_outlined, l10n.autoStopByCountTitle),
          PresetValuePicker(
            presets: const [108, 500, 1000, 5000, 10000],
            current: auto.targetCount,
            chipLabel: l10n.autoCountChip,
            customChipLabel: l10n.autoCountCustomChip,
            customPrompt: l10n.goalCustomPrompt,
            hintText: l10n.goalCustomHint,
            suffixText: l10n.unitRecitationsSuffix,
            invalidMessage: l10n.goalInvalidNumber,
            onSelected: (v) {
              auto.setTargetCount(v);
              done(l10n.autoCountGoalSetToast(v));
            },
            onDeselected: () {
              auto.setTargetCount(0);
              done(l10n.autoCountGoalClearedToast);
            },
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          sectionTitle(
              Icons.hourglass_bottom_rounded, l10n.autoStopByTimeTitle),
          PresetValuePicker(
            presets: const [15, 30, 45, 60, 90],
            current: auto.stopMinutes,
            chipLabel: l10n.autoMinutesChip,
            customChipLabel: l10n.autoMinutesCustomChip,
            customPrompt: l10n.autoMinutesPrompt,
            hintText: l10n.autoMinutesHint,
            suffixText: l10n.unitMinutesSuffix,
            invalidMessage: l10n.autoMinutesInvalid,
            onSelected: (m) {
              auto.setStopMinutes(m);
              done(l10n.autoTimerSetToast(m));
            },
            onDeselected: () {
              auto.setStopMinutes(0);
              done(l10n.autoTimerClearedToast);
            },
          ),
          if (auto.targetCount > 0 || auto.stopMinutes > 0) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  auto.clearStopCondition();
                  done(l10n.autoStopClearedToast);
                },
                icon: const Icon(Icons.all_inclusive_rounded, size: 18),
                label: Text(l10n.autoStopClearAction),
              ),
            ),
          ],
        ],
      );
    },
  );
}
