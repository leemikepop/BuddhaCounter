import 'package:flutter/material.dart';
import 'calendar/day_detail_card.dart';
import 'calendar/goal_reminder_card.dart';
import 'calendar/month_calendar.dart';
import 'calendar/practice_stats_header.dart';

/// 功課月曆分頁 (現代模式第四頁，經典模式從選單進入)：
/// 統計、月曆、選取日期的功課 (可修改)、每日目標 / 提醒 / 桌面小工具
class ModernCalendarView extends StatefulWidget {
  const ModernCalendarView({super.key});

  @override
  State<ModernCalendarView> createState() => _ModernCalendarViewState();
}

class _ModernCalendarViewState extends State<ModernCalendarView> {
  late DateTime _month;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PracticeStatsHeader(),
          const SizedBox(height: 16),
          MonthCalendar(
            month: _month,
            selectedDate: _selectedDate,
            onMonthChanged: (m) => setState(() => _month = m),
            onDateSelected: (d) => setState(() => _selectedDate = d),
          ),
          const SizedBox(height: 16),
          DayDetailCard(date: _selectedDate),
          const SizedBox(height: 16),
          const GoalReminderCard(),
        ],
      ),
    );
  }
}
