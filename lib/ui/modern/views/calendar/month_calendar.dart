import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/practice_record_service.dart';
import '../../../../features/practice/practice_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/l10n_dates.dart';
import '../../theme/modern_palette.dart';
import 'calendar_panel.dart';

/// 月曆卡片：月份切換、星期列與日期格 (每格顯示當日聲數；達成每日目標為金色)。
/// 左右滑動可切換月份。
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  /// 顯示的月份 (該月 1 日)
  final DateTime month;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  void _shiftMonth(int delta) =>
      onMonthChanged(DateTime(month.year, month.month + delta, 1));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -200) _shiftMonth(1);
        if (v > 200) _shiftMonth(-1);
      },
      child: CalendarPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _MonthHeader(
              month: month,
              onShift: _shiftMonth,
              onPick: () async {
                final picked = await showMonthYearPicker(context, month);
                if (picked != null) onMonthChanged(picked);
              },
              onToday: () {
                final now = DateTime.now();
                onMonthChanged(DateTime(now.year, now.month, 1));
                onDateSelected(DateTime(now.year, now.month, now.day));
              },
            ),
            const SizedBox(height: 12),
            const _WeekdayRow(),
            const SizedBox(height: 8),
            _DayGrid(
              month: month,
              selectedDate: selectedDate,
              onDateSelected: onDateSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onShift,
    required this.onPick,
    required this.onToday,
  });

  final DateTime month;
  final ValueChanged<int> onShift;
  final VoidCallback onPick;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => onShift(-1),
          tooltip: l10n.calendarPrevMonth,
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPick,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      l10n.calendarMonthTitle(month.year, month.month,
                          englishMonthName(month.month)),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded,
                      size: 22, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => onShift(1),
          tooltip: l10n.calendarNextMonth,
        ),
        TextButton.icon(
          onPressed: onToday,
          icon: const Icon(Icons.today_rounded, size: 16),
          label: Text(l10n.calendarToday),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 月曆格線從週日排起 (只影響顯示；「本週累計」仍以週一為起點)
    final weekdays = [
      l10n.weekdaySun,
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
    ];
    return Row(
      children: [
        for (var i = 0; i < weekdays.length; i++)
          Expanded(
            child: Center(
              child: Text(
                weekdays[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: i == 0 || i == 6
                      ? const Color(0xFFE11D48)
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final practice = context.watch<PracticeController>();
    final target = practice.dailyTargetCount;
    final primary = Theme.of(context).colorScheme.primary;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final todayKey = PracticeRecordService.formatDateKey(DateTime.now());
    final selectedKey = PracticeRecordService.formatDateKey(selectedDate);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ((leadingBlanks + daysInMonth) / 7).ceil() * 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final day = index - leadingBlanks + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();

        final date = DateTime(month.year, month.month, day);
        final key = PracticeRecordService.formatDateKey(date);
        final count = practice.records.getCount(date);
        final isToday = key == todayKey;
        final isSelected = key == selectedKey;
        final achieved = target > 0 && count >= target;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.18)
                  : (isToday
                      ? primary.withValues(alpha: 0.08)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? primary
                    : (isToday
                        ? primary.withValues(alpha: 0.5)
                        : Colors.transparent),
                width: isSelected ? 1.6 : 1.0,
              ),
            ),
            // 只有格子太小 (例如 320dp 窄螢幕) 時才等比縮小，一般螢幕維持原尺寸
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected || isToday ? primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: achieved
                            ? ModernPalette.achieved
                            : primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formatCellCount(count),
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: achieved ? Colors.white : primary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 年月選擇對話框：切換年份 (前後 10 年) + 1~12 月方格
Future<DateTime?> showMonthYearPicker(BuildContext context, DateTime current) {
  final now = DateTime.now();
  final years = List.generate(21, (i) => now.year - 10 + i);
  var year = current.year;

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final theme = Theme.of(ctx);
        final primary = theme.colorScheme.primary;
        final isDark = theme.brightness == Brightness.dark;
        final l10n = ctx.l10n;

        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setDialogState(() => year--),
                tooltip: l10n.calendarPrevYear,
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: years.contains(year) ? year : null,
                  hint: Text(
                    l10n.calendarYearLabel(year),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  items: [
                    for (final y in years)
                      DropdownMenuItem<int>(
                        value: y,
                        child: Text(
                          l10n.calendarYearLabel(y),
                          style: TextStyle(
                            fontWeight:
                                y == year ? FontWeight.bold : FontWeight.normal,
                            color: y == year ? primary : null,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => year = v);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setDialogState(() => year++),
                tooltip: l10n.calendarNextYear,
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.1,
              ),
              itemCount: 12,
              itemBuilder: (ctx, index) {
                final m = index + 1;
                final isShown = current.year == year && current.month == m;
                final isThisMonth = now.year == year && now.month == m;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(ctx, DateTime(year, m, 1)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isShown
                          ? primary
                          : (isThisMonth
                              ? primary.withAlpha(35)
                              : (isDark
                                  ? Colors.white10
                                  : Colors.black.withAlpha(10))),
                      borderRadius: BorderRadius.circular(12),
                      border: isThisMonth && !isShown
                          ? Border.all(color: primary, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l10n.calendarMonthChip(m, englishMonthShort(m)),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isShown || isThisMonth
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isShown
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, DateTime(now.year, now.month, 1)),
              child: Text(l10n.calendarBackToThisMonth),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
          ],
        );
      },
    ),
  );
}
