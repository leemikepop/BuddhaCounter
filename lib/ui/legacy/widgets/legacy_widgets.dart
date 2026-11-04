import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';

/// 經典模式配色 (沿用最早 Android 版的版面顏色)
abstract final class LegacyColors {
  static const Color blue = Color(0xFF0000FF);
  static const Color buttonGray = Color(0xFFE0E0E0);
  static const Color buttonBorder = Color(0xFF9E9E9E);
  static const Color cream = Color(0xFFFBFFE5);
  static const Color mint = Color(0xFFDAFFE8);
  static const Color lightBlue = Color(0xFFA1C9FF);
}

/// 經典模式的 AppBar (藍底白字)
AppBar legacyAppBar(String title,
    {List<Widget>? actions, bool boldTitle = false}) {
  return AppBar(
    backgroundColor: LegacyColors.blue,
    foregroundColor: Colors.white,
    title: Text(
      title,
      style: boldTitle ? const TextStyle(fontWeight: FontWeight.bold) : null,
    ),
    actions: actions,
  );
}

/// 頁面頂端藍底白字的「南無阿彌陀佛」橫幅
class LegacyBanner extends StatelessWidget {
  const LegacyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: LegacyColors.blue,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        context.l10n.practiceBuddhaName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

/// 經典灰底按鈕；[textColor] 用來標示「進行中」(藍字)
class LegacyButton extends StatelessWidget {
  const LegacyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor,
    this.horizontalPadding = 12,
    this.minHeight = 36,
  });

  final String text;
  final VoidCallback onPressed;
  final Color? textColor;
  final double horizontalPadding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? Colors.black;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: LegacyColors.buttonGray,
        foregroundColor: color,
        padding:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        minimumSize: Size(60, minHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: LegacyColors.buttonBorder),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

/// 沒有外框的灰底按鈕 (返回、儲存並返回)
class LegacyPlainButton extends StatelessWidget {
  const LegacyPlainButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontSize = 16,
    this.bold = false,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  final String text;
  final VoidCallback onPressed;
  final double fontSize;
  final bool bold;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: LegacyColors.buttonGray,
        foregroundColor: Colors.black,
        padding: padding,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : null,
        ),
      ),
    );
  }
}
