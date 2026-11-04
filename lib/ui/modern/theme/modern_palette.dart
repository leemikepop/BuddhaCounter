import 'package:flutter/material.dart';

/// 現代模式各元件共用的淺色 / 深色配色 (取代散落各處的 `isDark ? A : B`)
class ModernPalette {
  const ModernPalette._(this._scheme, this.isDark);

  factory ModernPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    return ModernPalette._(
        theme.colorScheme, theme.brightness == Brightness.dark);
  }

  final ColorScheme _scheme;
  final bool isDark;

  Color _pick(int light, int dark) => Color(isDark ? dark : light);

  Color get primary => _scheme.primary;
  Color get onSurface => _scheme.onSurface;
  Color get surface => _scheme.surface;

  /// 次要說明文字 (演出者、單位、時間)
  Color get mutedText => _pick(0xFF756F68, 0xFFA3A199);

  // --- 計數頁卡片 (碼表、設定卡) ---
  Color get card => isDark ? const Color(0xFF1E2027) : Colors.white;
  Color get cardBorder => _pick(0xFFEFE8DC, 0xFF2E323E);
  Color get cardShadow => isDark
      ? Colors.black.withValues(alpha: 0.2)
      : primary.withValues(alpha: 0.05);

  // --- 小膠囊按鈕 (目標、停止條件) ---
  Color get chip => isDark ? const Color(0xFF21232B) : Colors.white;
  Color get chipBorder => _pick(0xFFEBE3D5, 0xFF323642);
  Color get outlinedButtonBorder => _pick(0xFFDED6C7, 0xFF3B3F4E);

  // --- 功課月曆卡片 ---
  Color get panel => _pick(0xFFFCFAF7, 0xFF1E212A);
  Color get panelBorder => _pick(0xFFE8E0D4, 0xFF2C2F3A);

  /// 已達成每日目標 (月曆格、進度條)
  static const Color achieved = Color(0xFFF59E0B);

  // --- 浮動播放條 ---
  Color get raisedCard => isDark ? const Color(0xFF20232B) : Colors.white;
  Color get raisedCardBorder => _pick(0xFFEBE3D5, 0xFF323644);
  Color get floatingShadow => isDark
      ? Colors.black.withValues(alpha: 0.4)
      : const Color(0xFF8C5E32).withValues(alpha: 0.1);
  Color get progressTrack => _pick(0xFFEDE4D5, 0xFF2E313D);
  Color get badgeFill => _pick(0xFFF1EAE0, 0xFF2A2E3B);
  Color get badgeBorder => _pick(0xFFE2D8C8, 0xFF383C4D);

  // --- 播放器面板 ---
  Color get sheetBackground => isDark ? const Color(0xFF1B1D24) : Colors.white;
  Color get grabber => _pick(0xFFDDD5C7, 0xFF3A3E4D);
  Color get searchFill => _pick(0xFFF7F3EB, 0xFF242732);
  Color get searchHint => _pick(0xFF9E9991, 0xFF7E828E);
}
