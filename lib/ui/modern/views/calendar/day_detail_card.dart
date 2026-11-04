import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/practice_record_service.dart';
import '../../../../features/practice/practice_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/l10n_dates.dart';
import '../../../common/app_toast.dart';
import '../../theme/modern_palette.dart';
import 'calendar_panel.dart';

/// 選取日期的功課：總聲數、手動 / 自動明細、每日目標進度，可直接修改總聲數
class DayDetailCard extends StatelessWidget {
  const DayDetailCard({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final practice = context.watch<PracticeController>();
    final record = practice.records.getRecord(date);
    final count = record.totalCount;
    final target = practice.dailyTargetCount;
    final progress = target > 0 ? (count / target).clamp(0.0, 1.0) : 0.0;
    final reached = progress >= 1.0;
    final isToday = PracticeRecordService.formatDateKey(date) ==
        PracticeRecordService.formatDateKey(DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    const grey = TextStyle(fontSize: 11, color: Colors.grey);

    return CalendarPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, size: 20, color: primary),
              const SizedBox(width: 8),
              // 窄螢幕或較長的英文日期時自動換行，不擠壓修改按鈕
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.calendarSelectedDate(date.year, date.month, date.day,
                          englishMonthName(date.month)),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.calendarTodayBadge,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _editCount(context, count),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.calendarEditButton),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.calendarCountUnit,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.calendarBreakdown(record.manualCount, record.autoCount),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (target > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                    reached ? ModernPalette.achieved : primary),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reached
                        ? l10n.calendarGoalReached
                        : l10n.calendarGoalInProgress,
                    style: reached
                        ? const TextStyle(
                            fontSize: 11,
                            color: ModernPalette.achieved,
                            fontWeight: FontWeight.bold,
                          )
                        : grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(progress * 100).toInt()}% ($count/$target)',
                    style: grey),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _editCount(BuildContext context, int current) async {
    final practice = context.read<PracticeController>();
    final controller = TextEditingController(text: '$current');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return AlertDialog(
          title: Text(l10n.calendarEditTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.calendarEditDateLabel(date.year, date.month, date.day,
                    englishMonthName(date.month)),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.calendarEditFieldLabel,
                  hintText: l10n.calendarEditFieldHint,
                  border: const OutlineInputBorder(),
                  suffixText: l10n.unitRecitationsSuffix,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, int.tryParse(controller.text.trim()) ?? 0),
              child: Text(l10n.calendarEditSave),
            ),
          ],
        );
      },
    );
    // 不在這裡 dispose controller：對話框關閉動畫期間 TextField 仍在使用它
    if (result == null) return;
    await practice.setPracticeCount(date, result);
    if (context.mounted) {
      AppToast.show(context, context.l10n.calendarEditSavedToast(result));
    }
  }
}
