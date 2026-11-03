import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../common/app_toast.dart';
import '../widgets/goal_picker.dart';

/// 現代禪意【自動計數】專屬視圖
/// 版面風格統一模仿手動計數：頂部碼表、圓形計數盤 (含自動停止進度環)、
/// 自動停止設定 / 減一 / 重置小按鈕列、下方開始暫停大按鈕
class ModernTimerView extends StatelessWidget {
  const ModernTimerView({super.key});

  static const double _ringSize = 256;
  static const Color _reachedColor = Color(0xFF4CAF50);

  /// 自動停止設定面板：「念滿聲數」與「定時停止」二擇一，設定其中一項會清空另一項
  void _showStopConditionPicker(BuildContext context, CounterViewModel vm) {
    showGoalSheet(
      context,
      title: '設定自動停止',
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
        void done(String message) {
          Navigator.pop(ctx);
          AppToast.show(context, message);
        }

        Widget sectionTitle(IconData icon, String text) => Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 14),
              child: Text(
                '聲數與時間只能擇一，設定其中一項會清空另一項。',
                style: TextStyle(fontSize: 12.5, color: muted),
              ),
            ),
            sectionTitle(Icons.flag_outlined, '念滿聲數停止'),
            PresetValuePicker(
              presets: const [108, 500, 1000, 5000, 10000],
              current: vm.autoTargetCount,
              chipLabel: (v) => '$v 聲',
              customChipLabel: (v) => '$v 聲 (自訂)',
              customPrompt: '或自訂目標聲數：',
              hintText: '輸入目標 (如 500)',
              suffixText: '聲',
              invalidMessage: '請輸入大於 0 的有效目標數字',
              onSelected: (v) {
                vm.setAutoTargetCount(v);
                done('已設定念滿 $v 聲自動停止');
              },
              onDeselected: () {
                vm.setAutoTargetCount(0);
                done('已取消聲數目標，持續播放');
              },
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            sectionTitle(Icons.hourglass_bottom_rounded, '定時停止'),
            PresetValuePicker(
              presets: const [15, 30, 45, 60, 90],
              current: vm.autoStopMinutes,
              chipLabel: (m) => '$m 分鐘',
              customChipLabel: (m) => '$m 分鐘 (自訂)',
              customPrompt: '或自訂分鐘數：',
              hintText: '輸入分鐘數 (如 20)',
              suffixText: '分鐘',
              invalidMessage: '請輸入大於 0 的有效分鐘數',
              onSelected: (m) {
                vm.setAutoStopMinutes(m);
                done('已設定定時停止：$m 分鐘');
              },
              onDeselected: () {
                vm.setAutoStopMinutes(0);
                done('已取消定時停止，持續播放');
              },
            ),
            if (vm.autoTargetCount > 0 || vm.autoStopMinutes > 0) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    vm.clearAutoStopCondition();
                    done('已清除設定，持續播放');
                  },
                  icon: const Icon(Icons.all_inclusive_rounded, size: 18),
                  label: const Text('清除設定，持續播放'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _confirmResetAutoCount(BuildContext context, CounterViewModel vm) {
    if (vm.autoCount == 0) {
      AppToast.show(context, '目前計數已為 0');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重設自動計數？'),
        content: Text('目前自動計數為 ${vm.autoCount} 聲，確定要歸零重置嗎？\n（計時時間將會保留）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(ctx);
              vm.resetAutoCount();
              AppToast.show(context, '自動計數已重置為 0');
            },
            child: const Text('確認重置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final song = ChantConstants.getSongById(vm.currentSongId);

    // 自動停止條件 (念滿聲數 / 定時停止二擇一)
    final countGoal = vm.autoTargetCount;
    final timeGoal = vm.autoStopMinutes;
    final hasStopGoal = countGoal > 0 || timeGoal > 0;
    final double ringProgress =
        countGoal > 0 ? vm.autoTargetProgress : vm.autoStopElapsedProgress;
    final bool isGoalReached = countGoal > 0
        ? vm.isAutoTargetReached
        : (timeGoal > 0 && vm.autoStopRemainingSeconds == 0);
    final String? goalLabel;
    if (countGoal > 0) {
      goalLabel = isGoalReached
          ? '達成 $countGoal 聲'
          : '目標 $countGoal · ${(ringProgress * 100).toInt()}%';
    } else if (timeGoal > 0) {
      goalLabel = isGoalReached
          ? '定時 $timeGoal 分 · 已到'
          : '定時 $timeGoal 分 · 剩 ${_formatRemaining(vm.autoStopRemainingSeconds)}';
    } else {
      goalLabel = null;
    }
    final String stopLabel = countGoal > 0
        ? '目標 $countGoal'
        : (timeGoal > 0 ? '定時 $timeGoal 分' : '持續播放');
    final IconData stopIcon = countGoal > 0
        ? Icons.flag_outlined
        : (timeGoal > 0
            ? Icons.hourglass_bottom_rounded
            : Icons.all_inclusive_rounded);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // 頂部碼表（模仿手動計數：時鐘圖示、計時數字、開始/暫停鈕、歸零鈕，無文字）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2027) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF2E323E) : const Color(0xFFEFE8DC),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: primary,
                ),
                const SizedBox(width: 8),
                Text(
                  vm.formattedAutoTimer,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 14),
                // 開始 / 暫停按鈕 (與下方大按鈕同步)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    vm.isAutoCounting
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: primary,
                    size: 26,
                  ),
                  tooltip: vm.isAutoCounting ? '暫停' : '開始',
                  onPressed: () => vm.toggleAutoCount(),
                ),
                const SizedBox(width: 10),
                // 計時重置按鈕（維持計時重置，不影響計數）
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.replay_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  tooltip: '重設計時',
                  onPressed: () {
                    vm.resetAutoTimer();
                    AppToast.show(context, '計時已重置');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 核心圓形計數盤 + 自動停止進度環
          // 依聲數：顯示聲數進度；依時間：顯示時間進度；持續播放：不顯示進度環
          // (靜態進度環僅於數值變動時重繪，非轉圈動畫，不會造成卡頓)
          RepaintBoundary(
            child: GestureDetector(
              onTap: () => vm.toggleAutoCount(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: _ringSize,
                height: _ringSize,
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
                    if (hasStopGoal)
                      SizedBox(
                        width: _ringSize,
                        height: _ringSize,
                        child: CircularProgressIndicator(
                          value: ringProgress,
                          strokeWidth: 6,
                          backgroundColor: isDark
                              ? const Color(0xFF2B2E37)
                              : const Color(0xFFEBE3D5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isGoalReached ? _reachedColor : primary,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    Container(
                      width: _ringSize - 24,
                      height: _ringSize - 24,
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
                            vm.isAutoCounting
                                ? Icons.auto_mode_rounded
                                : Icons.spa_rounded,
                            size: 26,
                            color: isGoalReached
                                ? _reachedColor
                                : primary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 8),
                          // 數字顯示（自動調整大字）
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                vm.autoCount.toString(),
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
                            '聲 · 遍',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFA3A199)
                                  : const Color(0xFF756F68),
                              letterSpacing: 2.0,
                            ),
                          ),
                          if (goalLabel != null) ...[
                            const SizedBox(height: 10),
                            _buildPill(
                              goalLabel,
                              isGoalReached ? _reachedColor : primary,
                            ),
                          ],
                          const SizedBox(height: 6),
                          // 當前曲目節拍小標籤
                          Text(
                            '每拍 ${(song.effectiveBeatIntervalMs / 1000).toStringAsFixed(2)}s 自動累加',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 自動停止設定與快速動作（減一、重置）小按鈕列，排版與手動計數一致
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 自動停止設定小按鈕（念滿聲數 / 定時停止二擇一）
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showStopConditionPicker(context, vm),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF21232B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF323642)
                            : const Color(0xFFEBE3D5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stopIcon, size: 14, color: primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            stopLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 16, color: primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 減一 小按鈕
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF3B3F4E)
                        : const Color(0xFFDED6C7),
                  ),
                ),
                onPressed: vm.autoCount > 0 ? () => vm.decrementAuto() : null,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 14),
                label: const Text('減一', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),

              // 重置 小按鈕（僅重置自動計數，計時保留）
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: Colors.redAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                  ),
                ),
                onPressed: () => _confirmResetAutoCount(context, vm),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('重置', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 主控制按鈕：開始 / 暫停（重置已移至上方小按鈕列）
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: vm.isAutoCounting ? 0 : 3,
                shadowColor: primary.withValues(alpha: 0.3),
              ),
              onPressed: () => vm.toggleAutoCount(),
              icon: Icon(
                vm.isAutoCounting
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 24,
              ),
              label: Text(
                vm.isAutoCounting ? '暫停' : '開始',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == _reachedColor ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static String _formatRemaining(int seconds) {
    if (seconds >= 60) return '${(seconds / 60).ceil()} 分';
    return '$seconds 秒';
  }
}
