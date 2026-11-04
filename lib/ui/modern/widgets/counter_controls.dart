import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../theme/modern_palette.dart';

/// 計數頁上方的碼表膠囊：時間、開始 / 暫停、歸零 (手動與自動計數頁共用)
class TimerPill extends StatelessWidget {
  const TimerPill({
    super.key,
    required this.time,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
  });

  final String time;
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = ModernPalette.of(context);
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 20, color: palette.primary),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: palette.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 14),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              isRunning
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: palette.primary,
              size: 26,
            ),
            tooltip: isRunning ? l10n.commonPause : l10n.commonStart,
            onPressed: onToggle,
          ),
          const SizedBox(width: 10),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.replay_rounded,
              color: palette.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
            tooltip: l10n.timerResetTooltip,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

/// 可點開設定面板的小膠囊 (手動計數目標、自動計數停止條件)
class GoalChip extends StatelessWidget {
  const GoalChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModernPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.chip,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.chipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: palette.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: palette.onSurface,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16, color: palette.primary),
          ],
        ),
      ),
    );
  }
}

/// 小型外框按鈕 (減一、歸零)；[destructive] 為紅色
class SmallOutlinedAction extends StatelessWidget {
  const SmallOutlinedAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final palette = ModernPalette.of(context);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: destructive ? Colors.redAccent : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: destructive
              ? Colors.redAccent.withValues(alpha: 0.35)
              : palette.outlinedButtonBorder,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

/// 確認後才執行的歸零對話框
Future<void> confirmReset(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton.tonal(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
