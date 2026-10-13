import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: const Text('確認要歸零嗎？'),
        content: Text('目前計數為${vm.count}'),
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
    final customController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          '設定今日念佛目標',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...targets.map((t) {
                        final label = (t == 0) ? '不限目標' : '$t';
                        final isSel = vm.targetCount == t;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) {
                              vm.setTargetCount(t);
                              Navigator.pop(ctx);
                              AppToast.show(
                                context,
                                t == 0 ? '已設定為不限目標' : '已設定目標：$t',
                              );
                            }
                          },
                        );
                      }),
                      if (!targets.contains(vm.targetCount) &&
                          vm.targetCount > 0)
                        ChoiceChip(
                          label: Text('${vm.targetCount} 聲 (自訂)'),
                          selected: true,
                          onSelected: (_) {},
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '或自訂目標聲數：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: TextField(
                            controller: customController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: '輸入目標 (如 500)',
                              suffixText: '聲',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF242732)
                                  : const Color(0xFFF7F3EB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) {
                              final val =
                                  int.tryParse(customController.text.trim());
                              if (val != null && val > 0) {
                                vm.setTargetCount(val);
                                Navigator.pop(ctx);
                                AppToast.show(context, '已設定目標：$val 聲');
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final val =
                              int.tryParse(customController.text.trim());
                          if (val != null && val > 0) {
                            vm.setTargetCount(val);
                            Navigator.pop(ctx);
                            AppToast.show(context, '已設定目標：$val 聲');
                          } else {
                            AppToast.show(context, '請輸入大於 0 的有效目標數字');
                          }
                        },
                        child: const Text('設定'),
                      ),
                    ],
                  ),
                ],
              ),
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
                              value: SoundEffectType.woodfish1,
                              label: Text('木魚1', style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment(
                              value: SoundEffectType.woodfish2,
                              label: Text('木魚2', style: TextStyle(fontSize: 12)),
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
                            vm.audioService.playClickSfx(val.first);
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 2),
                            ),
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
