import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/practice/practice_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/l10n_dates.dart';
import '../../theme/modern_palette.dart';
import 'calendar_panel.dart';

/// 月曆頂部：連續精進天數橫幅 + 今日 / 本週 / 本月三欄統計
class PracticeStatsHeader extends StatelessWidget {
  const PracticeStatsHeader({super.key});

  static const Color _flame = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final practice = context.watch<PracticeController>();
    final streak = practice.streakDays;
    final today = practice.todayPracticeCount;
    final target = practice.dailyTargetCount;
    final palette = ModernPalette.of(context);
    final l10n = context.l10n;
    final month = DateTime.now().month;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: palette.isDark
                  ? const [Color(0xFF352B1E), Color(0xFF231E18)]
                  : const [Color(0xFFFFF4E5), Color(0xFFFDECD4)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _flame.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration:
                    const BoxDecoration(color: _flame, shape: BoxShape.circle),
                // 不用 emoji：截圖工具與部分平台沒有 emoji 字型，會畫成方框
                child: const Icon(Icons.local_fire_department_rounded,
                    size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.streakBanner(streak),
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
                              color: _flame,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.streakBadge,
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
                          ? l10n.streakEncourageActive
                          : l10n.streakEncourageStart,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: l10n.metricToday,
                value: '$today',
                subtitle: target > 0
                    ? l10n.metricTodayGoal(
                        target, (today / target * 100).toInt())
                    : l10n.metricNoGoal,
                icon: Icons.check_circle_outline_rounded,
                iconColor: palette.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                title: l10n.metricWeek,
                value: formatPracticeTotal(l10n, practice.weeklyPracticeCount),
                subtitle: l10n.metricWeekSubtitle,
                icon: Icons.date_range_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                title: l10n.metricMonth,
                value: formatPracticeTotal(l10n, practice.monthlyPracticeCount),
                subtitle:
                    l10n.metricMonthSubtitle(month, englishMonthShort(month)),
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = ModernPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.panelBorder),
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
                      fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                context.l10n.metricUnit,
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
}
