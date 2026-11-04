import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';

/// 現代禪意圓形計數盤組件
/// 包含：呼吸微光進度環、手感回饋縮放動畫、大號襯線數字、目標達成狀態
class ZenCircleCounter extends StatefulWidget {
  final int count;
  final int targetCount;
  final VoidCallback onTap;
  final double size;

  const ZenCircleCounter({
    super.key,
    required this.count,
    required this.targetCount,
    required this.onTap,
    this.size = 280,
  });

  @override
  State<ZenCircleCounter> createState() => _ZenCircleCounterState();
}

class _ZenCircleCounterState extends State<ZenCircleCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _animController.reverse();
  }

  void _handleTapUp(TapUpDetails _) {
    _animController.forward();
    widget.onTap();
  }

  void _handleTapCancel() {
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (widget.targetCount > 0)
        ? (widget.count / widget.targetCount).clamp(0.0, 1.0)
        : 0.0;
    final isTargetReached =
        widget.targetCount > 0 && widget.count >= widget.targetCount;

    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;

    return Center(
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : primary.withValues(alpha: 0.12),
                    blurRadius: 32,
                    spreadRadius: 4,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 外圈目標進度環
                  if (widget.targetCount > 0)
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: isDark
                            ? const Color(0xFF2B2E37)
                            : const Color(0xFFEBE3D5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isTargetReached ? const Color(0xFF4CAF50) : primary,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),

                  // 主體內盤（禪心漸層木石質感）
                  Container(
                    width: widget.size - 24,
                    height: widget.size - 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF282B34),
                                const Color(0xFF1B1D23),
                              ]
                            : [
                                surface,
                                const Color(0xFFF7F2E9),
                              ],
                      ),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF383C48)
                            : const Color(0xFFEDE5D8),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.spa_rounded,
                          size: 26,
                          color: isTargetReached
                              ? const Color(0xFF4CAF50)
                              : primary.withValues(alpha: 0.75),
                        ),
                        const SizedBox(height: 8),
                        // 數字顯示（自動調整大字）
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              widget.count.toString(),
                              style: TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.0,
                                color: theme.colorScheme.onSurface,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.zenCircleUnitLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFA3A199)
                                : const Color(0xFF756F68),
                            letterSpacing: 2.0,
                          ),
                        ),
                        if (widget.targetCount > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isTargetReached
                                  ? const Color(0xFF4CAF50)
                                      .withValues(alpha: 0.15)
                                  : primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isTargetReached
                                  ? context.l10n
                                      .goalReachedLabel(widget.targetCount)
                                  : context.l10n.goalProgressLabel(
                                      widget.targetCount,
                                      (progress * 100).toInt(),
                                    ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isTargetReached
                                    ? const Color(0xFF4CAF50)
                                    : primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
