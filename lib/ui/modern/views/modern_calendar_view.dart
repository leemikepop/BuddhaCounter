import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/practice_record_service.dart';
import '../../../core/services/widget_service.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../common/app_toast.dart';

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
            final availableYears =
                List.generate(21, (i) => now.year - 10 + i);

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
                    tooltip: '上一年',
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: availableYears.contains(pickerYear)
                          ? pickerYear
                          : null,
                      hint: Text(
                        '$pickerYear 年',
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
                            '$y 年',
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
                    tooltip: '下一年',
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
                              '$month 月',
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
                  child: const Text('回到本月'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
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
      CounterViewModel vm, int currentCount) async {
    final controller = TextEditingController(text: currentCount.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('手動修改功課聲數'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '日期：${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '今日功課聲數',
                  hintText: '請輸入念佛聲數',
                  border: OutlineInputBorder(),
                  suffixText: '聲',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final val = int.tryParse(controller.text.trim()) ?? 0;
                Navigator.pop(ctx, val);
              },
              child: const Text('確認儲存'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      await vm.setPracticeCount(_selectedDate, result);
      if (mounted) {
        setState(() {});
        AppToast.show(context, '已更新功課紀錄為 $result 聲');
      }
    }
  }

  Future<void> _pickReminderTime(CounterViewModel vm) async {
    final initialTime = TimeOfDay(
      hour: vm.reminderHour,
      minute: vm.reminderMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: '選擇每日念佛提醒時間',
      cancelText: '取消',
      confirmText: '設定',
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
        AppToast.show(context, '已設定每日 $hStr:$mStr 定時提醒');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final streak = vm.streakDays;
    final todayCount = vm.todayPracticeCount;
    final weeklyCount = vm.weeklyPracticeCount;
    final monthlyCount = vm.monthlyPracticeCount;

    final selectedRecord = vm.practiceRecords.getRecord(_selectedDate);
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
            targetCount: vm.targetCount,
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
                          '連續精進 $streak 天',
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
                            child: const Text(
                              '精進不懈',
                              style: TextStyle(
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
                          ? '念念相續，功德無量！繼續保持今日精進。'
                          : '今日開啟第一聲佛號，建立每日精進習慣！',
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
                title: '今日功課',
                value: todayCount.toString(),
                unit: '聲',
                subtitle: targetCount > 0
                    ? '目標 $targetCount (${((todayCount / targetCount) * 100).toInt()}%)'
                    : '無目標',
                icon: Icons.check_circle_outline_rounded,
                iconColor: primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: '本週累計',
                value: _formatNumber(weeklyCount),
                unit: '聲',
                subtitle: '週一至週日',
                icon: Icons.date_range_rounded,
                iconColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: '本月累計',
                value: _formatNumber(monthlyCount),
                unit: '聲',
                subtitle: '${DateTime.now().month}月總和',
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
      return '${(n / 10000).toStringAsFixed(1)}萬';
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
          tooltip: '上一月',
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
                      '${_displayedMonth.year} 年 ${_displayedMonth.month} 月',
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
          tooltip: '下一月',
        ),
        TextButton.icon(
          onPressed: _goToToday,
          icon: const Icon(Icons.today_rounded, size: 16),
          label: const Text('今天'),
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
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Row(
      children: weekdays.map((w) {
        final isWeekend = w == '日' || w == '六';
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
  Widget _buildCalendarGrid(
      CounterViewModel vm, Color primary, bool isDark) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final firstDayWeekday = DateTime(year, month, 1).weekday % 7; // 0 for Sunday
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
        if (index < firstDayWeekday ||
            index >= firstDayWeekday + daysInMonth) {
          return const SizedBox.shrink();
        }

        final day = index - firstDayWeekday + 1;
        final cellDate = DateTime(year, month, day);
        final cellKey = PracticeRecordService.formatDateKey(cellDate);
        final count = vm.practiceRecords.getCount(cellDate);

        final isToday = cellKey == todayKey;
        final isSelected = cellKey == selectedKey;
        final isTargetAchieved =
            vm.targetCount > 0 && count >= vm.targetCount;

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? primary
                        : (isToday ? primary : null),
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
    required CounterViewModel vm,
    required DailyPracticeRecord record,
    required bool isToday,
    required Color primary,
    required bool isDark,
  }) {
    final dateStr =
        '${_selectedDate.year} 年 ${_selectedDate.month} 月 ${_selectedDate.day} 日';
    final count = record.totalCount;
    final target = vm.targetCount;
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
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '今日',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // 直接輸入修改按鈕
                TextButton.icon(
                  onPressed: () => _showEditCountDialog(vm, count),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('修改數值'),
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
                const Text(
                  '聲佛號',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  '手動: ${record.manualCount} · 自動: ${record.autoCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  Text(
                    progress >= 1.0 ? '福慧圓滿，共成佛道！' : '持續精進...',
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
    required CounterViewModel vm,
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
            // 提醒開關與時間設定
            Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 20, color: primary),
                const SizedBox(width: 8),
                const Text(
                  '每日定時念佛提醒',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: vm.isReminderEnabled,
                  onChanged: (val) async {
                    if (val) {
                      await vm.notifications.requestPermissions();
                    }
                    await vm.updateReminderSettings(
                      enabled: val,
                      hour: vm.reminderHour,
                      minute: vm.reminderMinute,
                    );
                    if (mounted) {
                      AppToast.show(
                        context,
                        val ? '已開啟每日定時提醒' : '已關閉定時提醒',
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
                        '每天 $reminderHourStr:$reminderMinStr 推播提醒',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Text(
                        '更換時間',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      const Text(
                        'iOS / Android 桌面小工具',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '支援桌面 Widget，隨時在手機主畫面檢視今日精進、連續天數與每週累計。精進數據已自動即時同步。',
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
                            AppToast.show(context, '已同步最新數據至桌面小工具');
                          }
                        },
                        onLongPress: () async {
                          final diag = await WidgetService.getDiagnostics();
                          if (!mounted) return;
                          _showWidgetDiagnosticsDialog(context, diag, primary, isDark);
                        },
                        icon: Icon(Icons.sync_rounded, size: 16, color: primary),
                        label: Text(
                          '立即同步桌面小工具',
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

  /// 顯示小工具跨進程與 App Group 診斷對話框
  void _showWidgetDiagnosticsDialog(
    BuildContext context,
    Map<String, dynamic> diag,
    Color primary,
    bool isDark,
  ) {
    final pkg = diag['packageName'] ?? '未知';
    final ver = '${diag['version']}+${diag['buildNumber']}';
    final candidateGroups = (diag['candidateGroups'] as List?)?.join('\n') ?? '無';
    final groupData = diag['groupData'] as Map<String, dynamic>? ?? {};
    final installedWidgets = (diag['installedWidgets'] as List?) ?? [];

    final buffer = StringBuffer();
    buffer.writeln('=== 桌面小工具診斷報告 ===');
    buffer.writeln('應用套件識別碼 (Package ID): $pkg');
    buffer.writeln('應用版本 (Version): $ver');
    buffer.writeln('\n[候選 App Group 清單]');
    buffer.writeln(candidateGroups);
    buffer.writeln('\n[各群組數據讀取測試]');
    groupData.forEach((k, v) {
      buffer.writeln('- $k: $v');
    });
    buffer.writeln('\n[系統已安裝小工具]');
    if (installedWidgets.isEmpty) {
      buffer.writeln('無 (尚未偵測到主畫面已加入小工具)');
    } else {
      for (final w in installedWidgets) {
        buffer.writeln('- $w');
      }
    }

    final diagString = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.developer_mode_rounded, color: primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              '小工具診斷資訊',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    diagString,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '💡 診斷提示：iOS 桌面小工具必須依賴 Apple 官方簽署之 App Group 跨進程共享數據。若透過免費個人 Apple ID 經由 Sideloadly 側載，Apple 會限制該權限導致小工具顯示未連線；若使用付費開發者帳號或 TestFlight 簽署，則可完整即時同步。',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.amber[200] : Colors.amber[900],
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: diagString));
              AppToast.show(context, '已複製診斷報告至剪貼簿');
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('複製報告'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primary),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}
