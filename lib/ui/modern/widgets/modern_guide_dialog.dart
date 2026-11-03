import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../../l10n/l10n.dart';

/// 現代模式新版介面功能重點導覽 (精簡一頁式)
class ModernGuideDialog extends StatelessWidget {
  final VoidCallback? onComplete;

  const ModernGuideDialog({
    super.key,
    this.onComplete,
  });

  /// 呼叫顯示引導教學對話框
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onComplete,
  }) {
    final vm = context.read<CounterViewModel>();
    vm.markModernGuideSeen();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ModernGuideDialog(onComplete: onComplete),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final l10n = context.l10n;
    final items = [
      _FeaturePoint(
        icon: Icons.touch_app_rounded,
        title: l10n.guideFeatureCountTitle,
        desc: l10n.guideFeatureCountDesc(ChantConstants.allSongs.length),
      ),
      _FeaturePoint(
        icon: Icons.calendar_month_rounded,
        title: l10n.guideFeatureCalendarTitle,
        desc: l10n.guideFeatureCalendarDesc,
      ),
      _FeaturePoint(
        icon: Icons.widgets_rounded,
        title: l10n.guideFeatureWidgetTitle,
        desc: l10n.guideFeatureWidgetDesc,
      ),
      _FeaturePoint(
        icon: Icons.style_outlined,
        title: l10n.guideFeatureModeTitle,
        desc: l10n.guideFeatureModeDesc,
      ),
    ];

    return Dialog(
      backgroundColor:
          isDark ? const Color(0xFF1E212A) : const Color(0xFFFCFAF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 頂部小標籤與關閉按鈕
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.guideBadge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onComplete?.call();
                    },
                    tooltip: l10n.guideCloseTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 標題與簡介
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.spa_rounded, size: 26, color: primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.guideTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.guideSubtitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 重點特色清單 (一頁看完)
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2B2E3B)
                              : const Color(0xFFF3ECE0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          size: 18,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.desc,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),

              // 底部「開始精進」按鈕
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onComplete?.call();
                },
                child: Text(
                  l10n.guideStart,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePoint {
  final IconData icon;
  final String title;
  final String desc;

  const _FeaturePoint({
    required this.icon,
    required this.title,
    required this.desc,
  });
}
