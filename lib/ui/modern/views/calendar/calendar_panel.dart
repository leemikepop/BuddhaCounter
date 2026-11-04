import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import '../../theme/modern_palette.dart';

/// 功課月曆各區塊共用的圓角卡片
class CalendarPanel extends StatelessWidget {
  const CalendarPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = ModernPalette.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.panelBorder),
      ),
      color: palette.panel,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// 一萬以上改用「1.2 萬」/「12.3k」等縮寫 (統計卡片)
String formatPracticeTotal(AppLocalizations l10n, int n) {
  if (n < 10000) return '$n';
  return l10n.compactNumber(
    (n / 10000).toStringAsFixed(1),
    (n / 1000).toStringAsFixed(1),
  );
}

/// 一千以上改用「1.2k」(月曆格子裡的小徽章)
String formatCellCount(int n) =>
    n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
