import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../common/app_toast.dart';
import '../widgets/zen_circle_counter.dart';

/// 現代禪意【念佛計數】專屬視圖
/// 包含：頂部簡約禪修碼表、大圓計數盤、功課目標設定、倒退/歸零、無溢位音效選擇、震動與全螢幕盲按
class ModernCounterView extends StatelessWidget {
  const ModernCounterView({super.key});

  void _confirmReset(BuildContext context, CounterViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認重設記數？'),
        content: Text('目前記數為 ${vm.count} 聲，確定要歸零嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(ctx);
              vm.resetCount();
              AppToast.show(context, '已歸零');
            },
            child: const Text('確認歸零'),
          ),
        ],
      ),
    );
  }

  void _showTargetPicker(BuildContext context, CounterViewModel vm) {
    final targets = [108, 300, 1080, 5000, 10000, 0];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '設定今日念佛目標',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: targets.map((t) {
                    final label = (t == 0) ? '不限目標' : '$t 聲';
                    final isSel = vm.targetCount == t;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) {
                          vm.setTargetCount(t);
                          Navigator.pop(ctx);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    // 全螢幕點擊手勢容器
    Widget content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // 頂部簡約禪修計時碼表（無多餘文字說明，乾淨清爽）
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
                  vm.formattedTimer,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 14),
                // 開始 / 暫停按鈕
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    vm.isTimerRunning
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: primary,
                    size: 26,
                  ),
                  tooltip: vm.isTimerRunning ? '暫停' : '開始',
                  onPressed: () {
                    if (vm.isTimerRunning) {
                      vm.stopTimer();
                    } else {
                      vm.startTimer();
                    }
                  },
                ),
                const SizedBox(width: 10),
                // 歸零按鈕
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
                  onPressed: () => vm.resetTimer(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 核心禪意大圓計數盤
          ZenCircleCounter(
            count: vm.count,
            targetCount: vm.targetCount,
            size: 260,
            onTap: () {
              vm.increment();
            },
          ),
          const SizedBox(height: 18),

          // 功課目標與快速動作（減一、歸零）小按鈕列
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 功課目標小按鈕
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showTargetPicker(context, vm),
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
                      Icon(Icons.flag_outlined, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        vm.targetCount > 0 ? '目標 ${vm.targetCount}' : '目標 不限',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, size: 16, color: primary),
                    ],
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
                onPressed: vm.count > 0 ? () => vm.decrement() : null,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 14),
                label: const Text('減一', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),

              // 歸零 小按鈕
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
                onPressed: () => _confirmReset(context, vm),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('歸零', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 快捷控制功能卡片
          Material(
            color: isDark ? const Color(0xFF1E2027) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color:
                    isDark ? const Color(0xFF2E323E) : const Color(0xFFEFE8DC),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  // 音效模式選擇（防 Overflow 修正版）
                  Row(
                    children: [
                      Icon(Icons.volume_up_outlined, size: 18, color: primary),
                      const SizedBox(width: 6),
                      const Text(
                        '音效',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SegmentedButton<SoundEffectType>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: SoundEffectType.woodfish,
                              label: Text('木魚', style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment(
                              value: SoundEffectType.bell,
                              label: Text('引磬', style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment(
                              value: SoundEffectType.none,
                              label: Text('靜音', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          selected: {vm.soundEffect},
                          onSelectionChanged: (val) {
                            vm.setSoundEffect(val.first);
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 震動開關與全螢幕點擊開關 (使用原生 Switch 與 InkWell，防止 ListTile DecoratedBox 警告)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              vm.setVibrationEnabled(!vm.vibrationEnabled),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '震動回饋',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: vm.vibrationEnabled,
                                  onChanged: (val) =>
                                      vm.setVibrationEnabled(val),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              vm.setFullscreenTap(!vm.fullscreenTap),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '全螢幕點擊',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: vm.fullscreenTap,
                                  onChanged: (val) =>
                                      vm.setFullscreenTap(val),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (vm.fullscreenTap) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => vm.increment(),
        child: content,
      );
    }

    return content;
  }
}
