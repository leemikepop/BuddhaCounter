import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/practice/practice_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/app_toast.dart';
import '../../widgets/goal_picker.dart';
import 'calendar_panel.dart';

/// 每日功課目標、每日提醒開關與時間、桌面小工具說明與立即同步
class GoalReminderCard extends StatelessWidget {
  const GoalReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final practice = context.watch<PracticeController>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final dailyTarget = practice.dailyTargetCount;
    final time = '${practice.reminderHour.toString().padLeft(2, '0')}:'
        '${practice.reminderMinute.toString().padLeft(2, '0')}';
    const titleStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
    const greyStyle = TextStyle(fontSize: 12, color: Colors.grey);
    const chevron =
        Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey);

    return CalendarPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 每日功課目標 (和手動 / 自動計數目標各自獨立，比較當日總聲數)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => showCountGoalPicker(
              context,
              title: l10n.dailyGoalSheetTitle,
              current: dailyTarget,
              onSelected: practice.setDailyTargetCount,
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
                        Text(l10n.dailyGoalRowTitle, style: titleStyle),
                        const SizedBox(height: 2),
                        Text(l10n.dailyGoalRowSubtitle, style: greyStyle),
                      ],
                    ),
                  ),
                  Text(
                    dailyTarget > 0
                        ? l10n.dailyGoalValue(dailyTarget)
                        : l10n.goalUnlimited,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: primary),
                  ),
                  chevron,
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  size: 20, color: primary),
              const SizedBox(width: 8),
              Text(l10n.reminderTitle, style: titleStyle),
              const Spacer(),
              Switch(
                value: practice.isReminderEnabled,
                onChanged: (on) => _setReminderEnabled(context, on),
              ),
            ],
          ),
          if (practice.isReminderEnabled) ...[
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _pickReminderTime(context),
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
                      l10n.reminderDailyAt(time),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(l10n.reminderChangeTime, style: greyStyle),
                    chevron,
                  ],
                ),
              ),
            ),
          ],
          const Divider(height: 24),
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
                      l10n.widgetCardTitle,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.widgetCardBody,
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
                        side: BorderSide(color: primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await practice.refreshWidgetData();
                        if (context.mounted) {
                          AppToast.show(context, l10n.widgetSyncedToast);
                        }
                      },
                      icon: Icon(Icons.sync_rounded, size: 16, color: primary),
                      label: Text(
                        l10n.widgetSyncNow,
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
    );
  }

  Future<void> _setReminderEnabled(BuildContext context, bool on) async {
    final practice = context.read<PracticeController>();
    final l10n = context.l10n;
    if (on) await practice.requestNotificationPermissions();
    await practice.updateReminderSettings(
      enabled: on,
      hour: practice.reminderHour,
      minute: practice.reminderMinute,
    );
    if (context.mounted) {
      AppToast.show(
          context, on ? l10n.reminderEnabledToast : l10n.reminderDisabledToast);
    }
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final practice = context.read<PracticeController>();
    final l10n = context.l10n;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: practice.reminderHour, minute: practice.reminderMinute),
      helpText: l10n.reminderPickerHelp,
      cancelText: l10n.commonCancel,
      confirmText: l10n.commonSet,
    );
    if (picked == null) return;
    await practice.updateReminderSettings(
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    if (context.mounted) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      AppToast.show(context, l10n.reminderSetToast('$h:$m'));
    }
  }
}
