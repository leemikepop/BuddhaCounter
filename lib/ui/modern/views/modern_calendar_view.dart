import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/practice_record_service.dart';
import '../../../features/practice/practice_controller.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/l10n_dates.dart';
import '../../common/app_toast.dart';
import '../widgets/goal_picker.dart';

/// 現代禪意功課月曆與精進表記視圖 (Practice Calendar & Daily History)
/// 特色：
/// 1. 月曆瀏覽每日精進聲數與達成狀態
/// 2. 多鄰國風格頂部統計卡片 (連續天數、今日功課、本週本月累計)
/// 3. 自由手動增減修訂每日功課 (+10, +100, +108, +1000, 直接數值修改, 清空)
/// 4. 每日定時提醒通知設定與桌面小工具狀態
class ModernCalendarView extends StatefulWidget {
  const ModernCalendarView({super.key});

  @override
  State<ModernCalendarView> createState() => _ModernCalendarViewState();
}

class _ModernCalendarViewState extends State<ModernCalendarView> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  /// 彈出精美年月選擇對話框 (快速切換年份與 1~12 月九宮格)
  Future<void> _showMonthYearPicker() async {
    int pickerYear = _displayedMonth.year;
    final now = DateTime.now();

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final theme = Theme.of(ctx);
            final primary = theme.colorScheme.primary;
            final isDark = theme.brightness == Brightness.dark;

            // 支援前後 10 年之快速年份切換
            final availableYears = List.generate(21, (i) => now.year - 10 + i);

            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      setDialogState(() {
                        pickerYear--;
                      });
                    },
                    tooltip: ctx.l10n.calendarPrevYear,
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: availableYears.contains(pickerYear)
                          ? pickerYear
                          : null,
                      hint: Text(
                        ctx.l10n.calendarYearLabel(pickerYear),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      items: availableYears.map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text(
                            ctx.l10n.calendarYearLabel(y),
                            style: TextStyle(
                              fontWeight: y == pickerYear
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: y == pickerYear ? primary : null,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            pickerYear = val;
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      setDialogState(() {
                        pickerYear++;
                      });
                    },
                    tooltip: ctx.l10n.calendarNextYear,
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.1,
                      ),
                      itemCount: 12,
                      itemBuilder: (ctx, index) {
                        final month = index + 1;
                        final isCurrentSelected =
                            _displayedMonth.year == pickerYear &&
                                _displayedMonth.month == month;
                        final isThisMonth =
                            now.year == pickerYear && now.month == month;

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(ctx, DateTime(pickerYear, month, 1));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCurrentSelected
                                  ? primary
                                  : (isThisMonth
                                      ? primary.withAlpha(35)
                                      : (isDark
                                          ? Colors.white10
                                          : Colors.black.withAlpha(10))),
                              borderRadius: BorderRadius.circular(12),
                              border: isThisMonth && !isCurrentSelected
                                  ? Border.all(color: primary, width: 1.5)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              ctx.l10n.calendarMonthChip(
                                  month, englishMonthShort(month)),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrentSelected || isThisMonth
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrentSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx, DateTime(now.year, now.month, 1));
                  },
                  child: Text(ctx.l10n.calendarBackToThisMonth),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(ctx.l10n.commonCancel),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _displayedMonth = picked;
      });
    }
  }

  Future<void> _showEditCountDialog(
      PracticeController vm, int currentCount) async {
    final controller = TextEditingController(text: currentCount.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ctx.l10n.calendarEditTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.l10n.calendarEditDateLabel(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  englishMonthName(_selectedDate.month),
                ),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: ctx.l10n.calendarEditFieldLabel,
                  hintText: ctx.l10n.calendarEditFieldHint,
                  border: const OutlineInputBorder(),
                  suffixText: ctx.l10n.unitRecitationsSuffix,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final val = int.tryParse(controller.text.trim()) ?? 0;
                Navigator.pop(ctx, val);
              },
              child: Text(ctx.l10n.calendarEditSave),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      await vm.setPracticeCount(_selectedDate, result);
      if (mounted) {
        setState(() {});
        AppToast.show(context, context.l10n.calendarEditSavedToast(result));
      }
    }
  }

  Future<void> _pickReminderTime(PracticeController vm) async {
    final initialTime = TimeOfDay(
      hour: vm.reminderHour,
      minute: vm.reminderMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: context.l10n.reminderPickerHelp,
      cancelText: context.l10n.commonCancel,
      confirmText: context.l10n.commonSet,
    );

    if (picked != null && mounted) {
      await vm.updateReminderSettings(
        enabled: true,
        hour: picked.hour,
        minute: picked.minute,
      );
      if (mounted) {
        final hStr = picked.hour.toString().padLeft(2, '0');
        final mStr = picked.minute.toString().padLeft(2, '0');
        AppToast.show(context, context.l10n.reminderSetToast('$hStr:$mStr'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PracticeController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final streak = vm.streakDays;
    final todayCount = vm.todayPracticeCount;
    final weeklyCount = vm.weeklyPracticeCount;
    final monthlyCount = vm.monthlyPracticeCount;

    final selectedRecord = vm.records.getRecord(_selectedDate);
    final isSelectedDateToday =
        PracticeRecordService.formatDateKey(_selectedDate) ==
            PracticeRecordService.formatDateKey(DateTime.now());

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 多鄰國風格精進統計儀表板
          _buildDuolingoStatsHeader(
            streak: streak,
            todayCount: todayCount,
            weeklyCount: weeklyCount,
            monthlyCount: monthlyCount,
            targetCount: vm.dailyTargetCount,
            primary: primary,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 2. 月曆主體卡片 (支援左右手勢滑動翻月)
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -200) {
                  // 向左滑動 -> 下個月
                  _nextMonth();
                } else if (details.primaryVelocity! > 200) {
                  // 向右滑動 -> 上個月
                  _prevMonth();
                }
              }
            },
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2C2F3A)
                      : const Color(0xFFE8E0D4),
                ),
              ),
              color: isDark ? const Color(0xFF1E212A) : const Color(0xFFFCFAF7),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 月曆月份切換標頭
                    _buildMonthHeader(primary),
                    const SizedBox(height: 12),
                    // 星期欄列
                    _buildWeekdayRow(isDark),
                    const SizedBox(height: 8),
                    // 日期方格陣列
                    _buildCalendarGrid(vm, primary, isDark),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. 所選日期功課詳情與自由調整控制台
          _buildSelectedDayDetailCard(
            vm: vm,
            record: selectedRecord,
            isToday: isSelectedDateToday,
            primary: primary,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 4. 定時提醒與桌面小工具設定卡片
          _buildNotificationAndWidgetCard(
            vm: vm,
            primary: primary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// 多鄰國風格統計卡片
  Widget _buildDuolingoStatsHeader({
    required int streak,
    required int todayCount,
    required int weeklyCount,
    required int monthlyCount,
    required int targetCount,
    required Color primary,
    required bool isDark,
  }) {
    return Column(
      children: [
        // 連續精進天數橫幅 (Duolingo Flame Banner)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF352B1E), const Color(0xFF231E18)]
                  : [const Color(0xFFFFF4E5), const Color(0xFFFDECD4)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.l10n.streakBanner(streak),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (streak >= 7)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              context.l10n.streakBadge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      streak > 0
                          ? context.l10n.streakEncourageActive
                          : context.l10n.streakEncourageStart,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 三欄統計數值卡片 (今日 / 本週 / 本月)
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: context.l10n.metricToday,
                value: todayCount.toString(),
                unit: context.l10n.metricUnit,
                subtitle: targetCount > 0
                    ? context.l10n.metricTodayGoal(
                        targetCount,
                        ((todayCount / targetCount) * 100).toInt(),
                      )
                    : context.l10n.metricNoGoal,
                icon: Icons.check_circle_outline_rounded,
                iconColor: primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: context.l10n.metricWeek,
                value: _formatNumber(weeklyCount),
                unit: context.l10n.metricUnit,
                subtitle: context.l10n.metricWeekSubtitle,
                icon: Icons.date_range_rounded,
                iconColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: context.l10n.metricMonth,
                value: _formatNumber(monthlyCount),
                unit: context.l10n.metricUnit,
                subtitle: context.l10n.metricMonthSubtitle(
                  DateTime.now().month,
                  englishMonthShort(DateTime.now().month),
                ),
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E212A) : const Color(0xFFFCFAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2F3A) : const Color(0xFFE8E0D4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 10000) {
      return context.l10n.compactNumber(
        (n / 10000).toStringAsFixed(1),
        (n / 1000).toStringAsFixed(1),
      );
    }
    return n.toString();
  }

  /// 月份切換標頭
  Widget _buildMonthHeader(Color primary) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _prevMonth,
          tooltip: context.l10n.calendarPrevMonth,
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _showMonthYearPicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      context.l10n.calendarMonthTitle(
                        _displayedMonth.year,
                        _displayedMonth.month,
                        englishMonthName(_displayedMonth.month),
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 22,
                    color: primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _nextMonth,
          tooltip: context.l10n.calendarNextMonth,
        ),
        TextButton.icon(
          onPressed: _goToToday,
          icon: const Icon(Icons.today_rounded, size: 16),
          label: Text(context.l10n.calendarToday),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }

  /// 星期標題行
  Widget _buildWeekdayRow(bool isDark) {
    final l10n = context.l10n;
    // 月曆格線自週日起排列 (僅顯示用；本週累計仍以週一為起點)
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
      children: weekdays.map((w) {
        final isWeekend = w == weekdays.first || w == weekdays.last;
        return Expanded(
          child: Center(
            child: Text(
              w,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isWeekend
                    ? const Color(0xFFE11D48)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 月曆日期格子
  Widget _buildCalendarGrid(PracticeController vm, Color primary, bool isDark) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final firstDayWeekday =
        DateTime(year, month, 1).weekday % 7; // 0 for Sunday
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final now = DateTime.now();
    final todayKey = PracticeRecordService.formatDateKey(now);
    final selectedKey = PracticeRecordService.formatDateKey(_selectedDate);

    final totalSlots = ((firstDayWeekday + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalSlots,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        if (index < firstDayWeekday || index >= firstDayWeekday + daysInMonth) {
          return const SizedBox.shrink();
        }

        final day = index - firstDayWeekday + 1;
        final cellDate = DateTime(year, month, day);
        final cellKey = PracticeRecordService.formatDateKey(cellDate);
        final count = vm.records.getCount(cellDate);

        final isToday = cellKey == todayKey;
        final isSelected = cellKey == selectedKey;
        final isTargetAchieved =
            vm.dailyTargetCount > 0 && count >= vm.dailyTargetCount;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
          },
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
            // 日期格內容 (純數字) 只在格子過小 (例如 320dp 窄螢幕) 時等比縮小，一般螢幕維持原尺寸
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? primary : (isToday ? primary : null),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: isTargetAchieved
                            ? const Color(0xFFF59E0B)
                            : primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatCompact(count),
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: isTargetAchieved ? Colors.white : primary,
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

  String _formatCompact(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toString();
  }

  /// 選中日期功課卡片與手動修改控制台
  Widget _buildSelectedDayDetailCard({
    required PracticeController vm,
    required DailyPracticeRecord record,
    required bool isToday,
    required Color primary,
    required bool isDark,
  }) {
    final dateStr = context.l10n.calendarSelectedDate(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      englishMonthName(_selectedDate.month),
    );
    final count = record.totalCount;
    final target = vm.dailyTargetCount;
    final progress = target > 0 ? (count / target).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2F3A) : const Color(0xFFE8E0D4),
        ),
      ),
      color: isDark ? const Color(0xFF1E212A) : const Color(0xFFFCFAF7),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 日期標題與今日徽章
            Row(
              children: [
                Icon(Icons.event_note_rounded, size: 20, color: primary),
                const SizedBox(width: 8),
                // 日期與「今日」徽章：窄螢幕或較長的英文日期時自動換行，不擠壓修改按鈕
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                            context.l10n.calendarTodayBadge,
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
                // 直接輸入修改按鈕
                TextButton.icon(
                  onPressed: () => _showEditCountDialog(vm, count),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(context.l10n.calendarEditButton),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 總聲數顯示與細分
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.calendarCountUnit,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.calendarBreakdown(
                      record.manualCount,
                      record.autoCount,
                    ),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 目標進度條
            if (target > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? const Color(0xFFF59E0B) : primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      progress >= 1.0
                          ? context.l10n.calendarGoalReached
                          : context.l10n.calendarGoalInProgress,
                      style: TextStyle(
                        fontSize: 11,
                        color: progress >= 1.0
                            ? const Color(0xFFF59E0B)
                            : Colors.grey,
                        fontWeight: progress >= 1.0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).toInt()}% ($count/$target)',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  /// 每日提醒通知與桌面小工具卡片
  Widget _buildNotificationAndWidgetCard({
    required PracticeController vm,
    required Color primary,
    required bool isDark,
  }) {
    final reminderHourStr = vm.reminderHour.toString().padLeft(2, '0');
    final reminderMinStr = vm.reminderMinute.toString().padLeft(2, '0');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2F3A) : const Color(0xFFE8E0D4),
        ),
      ),
      color: isDark ? const Color(0xFF1E212A) : const Color(0xFFFCFAF7),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 每日功課目標設定（與手動 / 自動計數目標各自獨立，比較當日總聲數）
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => showCountGoalPicker(
                context,
                title: context.l10n.dailyGoalSheetTitle,
                current: vm.dailyTargetCount,
                onSelected: vm.setDailyTargetCount,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.dailyGoalRowTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.dailyGoalRowSubtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      vm.dailyTargetCount > 0
                          ? context.l10n.dailyGoalValue(vm.dailyTargetCount)
                          : context.l10n.goalUnlimited,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),

            // 提醒開關與時間設定
            Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 20, color: primary),
                const SizedBox(width: 8),
                Text(
                  context.l10n.reminderTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: vm.isReminderEnabled,
                  onChanged: (val) async {
                    if (val) {
                      await vm.requestNotificationPermissions();
                    }
                    await vm.updateReminderSettings(
                      enabled: val,
                      hour: vm.reminderHour,
                      minute: vm.reminderMinute,
                    );
                    if (mounted) {
                      AppToast.show(
                        context,
                        val
                            ? context.l10n.reminderEnabledToast
                            : context.l10n.reminderDisabledToast,
                      );
                    }
                  },
                ),
              ],
            ),
            if (vm.isReminderEnabled) ...[
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _pickReminderTime(vm),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.reminderDailyAt(
                            '$reminderHourStr:$reminderMinStr'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        context.l10n.reminderChangeTime,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(height: 24),

            // 桌面小工具說明
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.widgets_outlined, size: 20, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.widgetCardTitle,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.widgetCardBody,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          side: BorderSide(
                            color: primary.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await vm.refreshWidgetData();
                          if (mounted) {
                            AppToast.show(
                                context, context.l10n.widgetSyncedToast);
                          }
                        },
                        icon:
                            Icon(Icons.sync_rounded, size: 16, color: primary),
                        label: Text(
                          context.l10n.widgetSyncNow,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
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
